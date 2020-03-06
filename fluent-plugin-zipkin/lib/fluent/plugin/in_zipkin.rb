#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

# This plugin base on fluentd in_http
# TODO (sumo-drosiek, 2020.02.12): Remove unneeded code and configuration

require 'fluent/plugin/input'
require 'fluent/plugin/parser'
require 'fluent/event'

require 'http/parser'
require 'webrick/httputils'
require 'uri'
require 'socket'
require 'json'

module Fluent::Plugin
  class ZipkinParser < Parser
    Fluent::Plugin.register_parser('in_zipkin', self)
    def parse(text)
      # this plugin is dummy implementation not to raise error
      yield nil, nil
    end
  end

  class ZipkinInput < Input
    Fluent::Plugin.register_input('zipkin', self)

    helpers :parser, :compat_parameters, :event_loop, :server

    EMPTY_GIF_IMAGE = "GIF89a\u0001\u0000\u0001\u0000\x80\xFF\u0000\xFF\xFF\xFF\u0000\u0000\u0000,\u0000\u0000\u0000\u0000\u0001\u0000\u0001\u0000\u0000\u0002\u0002D\u0001\u0000;".force_encoding("UTF-8")

    desc 'The port to listen to.'
    config_param :port, :integer, default: 9411
    desc 'The bind address to listen to.'
    config_param :bind, :string, default: '0.0.0.0'
    desc 'The size limit of the POSTed element. Default is 32MB.'
    config_param :body_size_limit, :size, default: 32*1024*1024  # TODO default
    desc 'The timeout limit for keeping the connection alive.'
    config_param :keepalive_timeout, :time, default: 10   # TODO default
    config_param :backlog, :integer, default: nil
    desc 'Add HTTP_ prefix headers to the record.'
    config_param :add_http_headers, :bool, default: false
    desc 'Add REMOTE_ADDR header to the record.'
    config_param :add_remote_addr, :bool, default: false
    config_param :blocking_timeout, :time, default: 0.5
    desc 'Set a white list of domains that can do CORS (Cross-Origin Resource Sharing)'
    config_param :cors_allow_origins, :array, default: nil
    desc 'Respond with empty gif image of 1x1 pixel.'
    config_param :respond_with_empty_img, :bool, default: false
    desc 'Respond status code with 204.'
    config_param :use_204_response, :bool, default: false

    config_section :parse do
      config_set_default :@type, 'in_zipkin'
    end

    EVENT_RECORD_PARAMETER = '_event_record'

    def configure(conf)
      compat_parameters_convert(conf, :parser)
      @first_trace = true

      super

      m = if @parser_configs.first['@type'] == 'in_zipkin'
            @parser_msgpack = parser_create(usage: 'parser_in_http_msgpack', type: 'msgpack')
            @parser_msgpack.estimate_current_event = false
            @parser_json = parser_create(usage: 'parser_in_http_json', type: 'json')
            @parser_json.estimate_current_event = false
            @parser_protobuf = parser_create(usage: 'parser_in_protobuf', type: 'zipkin_protobuf')
            @format_name = 'default'
            @parser_time_key = if parser_config = conf.elements('parse').first
                                 parser_config['time_key'] || 'time'
                               else
                                 'time'
                               end
            method(:parse_params_default)
          else
            @parser = parser_create
            @format_name = @parser_configs.first['@type']
            @parser_time_key = @parser.time_key
            method(:parse_params_with_parser)
          end
      self.singleton_class.module_eval do
        define_method(:parse_params, m)
      end
    end

    class KeepaliveManager < Coolio::TimerWatcher
      def initialize(timeout)
        super(1, true)
        @cons = {}
        @timeout = timeout.to_i
      end

      def add(sock)
        @cons[sock] = sock
      end

      def delete(sock)
        @cons.delete(sock)
      end

      def on_timer
        @cons.each_pair {|sock,val|
          if sock.step_idle > @timeout
            sock.close
          end
        }
      end
    end

    def multi_workers_ready?
      true
    end

    def start
      @_event_loop_run_timeout = @blocking_timeout

      super

      log.debug "listening http", bind: @bind, port: @port

      @km = KeepaliveManager.new(@keepalive_timeout)
      event_loop_attach(@km)

      server_create_connection(:in_zipkin, @port, bind: @bind, backlog: @backlog, &method(:on_server_connect))
      @float_time_parser = Fluent::NumericTimeParser.new(:float)
    end

    def close
      server_wait_until_stop
      super
    end

    def on_request(path_info, params)
      begin
        path = path_info[1..-1]  # remove /
        tag = path.split('/').unshift('tracing').join('.')
        mes = Fluent::MultiEventStream.new

        parse_params(params) do |single_time, single_record|
          mes.add(convert_timestamp(single_time), single_record)
        end

        router.emit_stream(tag, mes)

        if @first_trace
          log.info "First trace received"
          @first_trace = false
        end

      rescue Exception => exception
        return ["500 Internal Server Error", {'Content-Type'=>'text/plain'}, "500 Internal Server Error\n#{$!}\n"]
      end

      if @respond_with_empty_img
        return ["200 OK", {'Content-Type'=>'image/gif; charset=utf-8'}, EMPTY_GIF_IMAGE]
      else
        if @use_204_response
          return  ["204 No Content", {}]
        else
          return ["200 OK", {'Content-Type'=>'text/plain'}, ""]
        end
      end
    end

    private

    def on_server_connect(conn)
      handler = Handler.new(conn, @km, method(:on_request), @body_size_limit, @format_name, log, @cors_allow_origins)

      conn.on(:data) do |data|
        handler.on_read(data)
      end

      conn.on(:write_complete) do |_|
        handler.on_write_complete
      end

      conn.on(:close) do |_|
        handler.on_close
      end
    end

    def convert_timestamp(timestamp)
      return Fluent::EventTime.from_time(Time.at(timestamp/1e6.floor, timestamp%1e6))
    end

    def parse_params_default(params)
      if data = params['json']
        func = @parser_protobuf.method(:parse_json)
      elsif data = params['protobuf']
        func = @parser_protobuf.method(:parse)
      else
        raise "'json' or 'protobuf' parameter is required"
      end

      func.call(data) do |timestamp, record|
        yield timestamp, record
      end
    end

    def parse_params_with_parser(params)
      if content = params[EVENT_RECORD_PARAMETER]
        @parser.parse(content) { |time, record|
          raise "Received event is not #{@format_name}: #{content}" if record.nil?
          return time, record
        }
      else
        raise "'#{EVENT_RECORD_PARAMETER}' parameter is required"
      end
    end

    class Handler
      attr_reader :content_type

      def initialize(io, km, callback, body_size_limit, format_name, log, cors_allow_origins)
        @io = io
        @km = km
        @callback = callback
        @body_size_limit = body_size_limit
        @next_close = false
        @format_name = format_name
        @log = log
        @cors_allow_origins = cors_allow_origins
        @idle = 0
        @km.add(self)

        @remote_port, @remote_addr = io.remote_port, io.remote_addr
        @parser = Http::Parser.new(self)
      end

      def step_idle
        @idle += 1
      end

      def on_close
        @km.delete(self)
      end

      def on_read(data)
        @idle = 0
        @parser << data
      rescue
        @log.warn "unexpected error", error: $!.to_s
        @log.warn_backtrace
        @io.close
      end

      def on_message_begin
        @body = ''
      end

      def on_headers_complete(headers)
        expect = nil
        size = nil

        if @parser.http_version == [1, 1]
          @keep_alive = true
        else
          @keep_alive = false
        end
        @env = {}
        @content_type = ""
        @content_encoding = ""
        headers.each_pair {|k,v|
          @env["HTTP_#{k.gsub('-','_').upcase}"] = v
          case k
          when /\AExpect\z/i
            expect = v
          when /\AContent-Length\Z/i
            size = v.to_i
          when /\AContent-Type\Z/i
            @content_type = v
          when /\AContent-Encoding\Z/i
            @content_encoding = v
          when /\AConnection\Z/i
            if v =~ /close/i
              @keep_alive = false
            elsif v =~ /Keep-alive/i
              @keep_alive = true
            end
          when /\AOrigin\Z/i
            @origin  = v
          when /\AX-Forwarded-For\Z/i
            # For multiple X-Forwarded-For headers. Use first header value.
            v = v.first if v.is_a?(Array)
            @remote_addr = v.split(",").first
          when /\AAccess-Control-Request-Method\Z/i
            @access_control_request_method = v
          when /\AAccess-Control-Request-Headers\Z/i
            @access_control_request_headers = v
          end
        }
        if expect
          if expect == '100-continue'
            if !size || size < @body_size_limit
              send_response_nobody("100 Continue", {})
            else
              send_response_and_close("413 Request Entity Too Large", {}, "Too large")
            end
          else
            send_response_and_close("417 Expectation Failed", {}, "")
          end
        end
      end

      def on_body(chunk)
        if @body.bytesize + chunk.bytesize > @body_size_limit
          unless closing?
            send_response_and_close("413 Request Entity Too Large", {}, "Too large")
          end
          return
        end
        @body << chunk
      end

      # Web browsers can send an OPTIONS request before performing POST
      # to check if cross-origin requests are supported.
      def handle_options_request
        # Is CORS enabled in the first place?
        if @cors_allow_origins.nil?
          return send_response_and_close("403 Forbidden", {}, "")
        end

        # in_http does not support HTTP methods except POST
        if @access_control_request_method != 'POST'
          return send_response_and_close("403 Forbidden", {}, "")
        end

        header = {
          "Access-Control-Allow-Methods" => "POST",
          "Access-Control-Allow-Headers" => @access_control_request_headers || "",
        }

        # Check the origin and send back a CORS response
        if @cors_allow_origins.include?('*')
          header["Access-Control-Allow-Origin"] = "*"
          send_response_and_close("200 OK", header, "")
        elsif include_cors_allow_origin
          header["Access-Control-Allow-Origin"] = @origin
          send_response_and_close("200 OK", header, "")
        else
          send_response_and_close("403 Forbidden", {}, "")
        end
      end

      def on_message_complete
        return if closing?

        if @parser.http_method == 'OPTIONS'
          return handle_options_request()
        end

        # CORS check
        # ==========
        # For every incoming request, we check if we have some CORS
        # restrictions and white listed origins through @cors_allow_origins.
        unless @cors_allow_origins.nil?
          unless @cors_allow_origins.include?('*') or include_cors_allow_origin
            send_response_and_close("403 Forbidden", {'Connection' => 'close'}, "")
            return
          end
        end

        # Content Encoding
        # =================
        # Decode payload according to the "Content-Encoding" header.
        # For now, we only support 'gzip' and 'deflate'.
        begin
          if @content_encoding == 'gzip'
            @body = Zlib::GzipReader.new(StringIO.new(@body)).read
          elsif @content_encoding == 'deflate'
            @body = Zlib::Inflate.inflate(@body)
          end
        rescue
          @log.warn 'fails to decode payload', error: $!.to_s
          send_response_and_close("400 Bad Request", {}, "")
          return
        end

        @env['REMOTE_ADDR'] = @remote_addr if @remote_addr

        uri = URI.parse(@parser.request_url)
        params = WEBrick::HTTPUtils.parse_query(uri.query)

        if @format_name != 'default'
          params[EVENT_RECORD_PARAMETER] = @body
        elsif @content_type =~ /^application\/x-protobuf/
          params['protobuf'] = @body
        elsif @content_type =~ /^application\/json/
          params['json'] = @body
        end
        path_info = uri.path

        params.merge!(@env)
        @env.clear

        code, header, body = *@callback.call(path_info, params)
        body = body.to_s

        unless @cors_allow_origins.nil?
          if @cors_allow_origins.include?('*')
            header['Access-Control-Allow-Origin'] = '*'
          elsif include_cors_allow_origin
            header['Access-Control-Allow-Origin'] = @origin
          end
        end

        if @keep_alive
          header['Connection'] = 'Keep-Alive'
          send_response(code, header, body)
        else
          send_response_and_close(code, header, body)
        end
      end

      def close
        @io.close
      end

      def on_write_complete
        @io.close if @next_close
      end

      def send_response_and_close(code, header, body)
        send_response(code, header, body)
        @next_close = true
      end

      def closing?
        @next_close
      end

      def send_response(code, header, body)
        header['Content-Length'] ||= body.bytesize
        header['Content-Type'] ||= 'text/plain'

        data = %[HTTP/1.1 #{code}\r\n]
        header.each_pair {|k,v|
          data << "#{k}: #{v}\r\n"
        }
        data << "\r\n"
        @io.write(data)

        @io.write(body)
      end

      def send_response_nobody(code, header)
        data = %[HTTP/1.1 #{code}\r\n]
        header.each_pair {|k,v|
          data << "#{k}: #{v}\r\n"
        }
        data << "\r\n"
        @io.write(data)
      end

      def include_cors_allow_origin
        if @cors_allow_origins.include?(@origin)
          return true
        end
        filtered_cors_allow_origins = @cors_allow_origins.select {|origin| origin != ""}
        return filtered_cors_allow_origins.find do |origin|
          (start_str,end_str) = origin.split("*",2)
          @origin.start_with?(start_str) and @origin.end_with?(end_str)
        end != nil
      end
    end
  end
end
