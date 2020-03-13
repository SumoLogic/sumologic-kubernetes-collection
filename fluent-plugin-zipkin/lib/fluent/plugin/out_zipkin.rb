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

require 'net/http'
require 'uri'
require 'openssl'
require 'fluent/plugin/output'
require 'fluent/plugin_helper/socket'
require 'fluent/event'
require 'google/protobuf'
require 'snappy'
require 'json'
require 'base64'
require 'oj'
require 'ipaddr'
require_relative '../../zipkin_pb'

module Fluent::Plugin
  class ZipkinOutput < Output
    Fluent::Plugin.register_output('zipkin', self)

    helpers :event_emitter

    class RetryableResponse < StandardError; end

    desc 'The endpoint for HTTP request, e.g. http://example.com/api'
    config_param :endpoint, :string
    desc 'The method for HTTP request'
    config_param :http_method, :enum, list: [:put, :post], default: :post
    desc 'The proxy for HTTP request'
    config_param :proxy, :string, default: ENV['HTTP_PROXY'] || ENV['http_proxy']
    desc 'Content-Type for HTTP request'
    config_param :content_type, :string, default: 'application/x-protobuf'
    desc 'Overwrite Content-Type with custom value'
    config_param :override_content_type, :string, default: nil
    desc 'Additional headers for HTTP request'
    config_param :headers, :hash, default: nil

    desc 'The connection open timeout in seconds'
    config_param :open_timeout, :integer, default: nil
    desc 'The read timeout in seconds'
    config_param :read_timeout, :integer, default: nil
    desc 'The TLS timeout in seconds'
    config_param :ssl_timeout, :integer, default: nil

    desc 'The CA certificate path for TLS'
    config_param :tls_ca_cert_path, :string, default: nil
    desc 'The client certificate path for TLS'
    config_param :tls_client_cert_path, :string, default: nil
    desc 'The client private key path for TLS'
    config_param :tls_private_key_path, :string, default: nil
    desc 'The client private key passphrase for TLS'
    config_param :tls_private_key_passphrase, :string, default: nil, secret: true
    desc 'The verify mode of TLS'
    config_param :tls_verify_mode, :enum, list: [:none, :peer], default: :peer
    desc 'The default version of TLS'
    config_param :tls_version, :enum, list: Fluent::PluginHelper::Socket::TLS_SUPPORTED_VERSIONS, default: Fluent::PluginHelper::Socket::TLS_DEFAULT_VERSION
    desc 'The cipher configuration of TLS'
    config_param :tls_ciphers, :string, default: Fluent::PluginHelper::Socket::CIPHERS_DEFAULT

    desc 'Raise UnrecoverableError when the response is non success, 4xx/5xx'
    config_param :error_response_as_unrecoverable, :bool, default: true
    desc 'The list of retryable response code'
    config_param :retryable_response_codes, :array, value_type: :integer, default: [503]

    desc 'Maximum number of spans per request'
    config_param :spans_per_request, :integer, default: 100

    config_section :auth, required: false, multi: false do
      desc 'The method for HTTP authentication'
      config_param :method, :enum, list: [:basic], default: :basic
      desc 'The username for basic authentication'
      config_param :username, :string, default: nil
      desc 'The password for basic authentication'
      config_param :password, :string, default: nil, secret: true
    end

    def initialize
      super

      @uri = nil
      @proxy_uri = nil
      @formatter = nil
    end

    def configure(conf)
      super

      @first_trace = true
      if @content_type == 'application/json' then
        define_singleton_method(:get_spans, method(:get_spans_for_json))
      elsif @content_type != 'application/x-protobuf'
        raise 'Invalid content-type'
      end
      @http_opt = setup_http_option
      @proxy_uri = URI.parse(@proxy) if @proxy
    end

    def multi_workers_ready?
      true
    end

    def write(chunk)
      uri = parse_endpoint(chunk)
      data = split_chunk(chunk, size: @spans_per_request)

      data.each do |spans|
        begin
          req = create_request(chunk, uri)
          payload = get_spans(spans)
          req.body = payload
          if not send_request(uri, req)
            mes = Fluent::MultiEventStream.new
            spans.each do |timestamp, record|
              mes.add(timestamp, record)
            end
            # ToDo (sumo-drosiek, 2020.03.06): Use chunk tag. It's hardcoded because sometimes chunk.metadata.tag is nil
            router.emit_stream("tracing.resend", mes)
          end
        rescue Exception => exception
          log.warn exception
          return
        end
      end

    end

    private

    def setup_http_option
      use_ssl = @endpoint.start_with?('https')
      opt = {
        open_timeout: @open_timeout,
        read_timeout: @read_timeout,
        ssl_timeout: @ssl_timeout,
        use_ssl: use_ssl
      }

      if use_ssl
        if @tls_ca_cert_path
          raise Fluent::ConfigError, "tls_ca_cert_path is wrong: #{@tls_ca_cert_path}" unless File.file?(@tls_ca_cert_path)
          opt[:ca_file] = @tls_ca_cert_path
        end
        if @tls_client_cert_path
          raise Fluent::ConfigError, "tls_client_cert_path is wrong: #{@tls_client_cert_path}" unless File.file?(@tls_client_cert_path)
          opt[:cert] = OpenSSL::X509::Certificate.new(File.read(@tls_client_cert_path))
        end
        if @tls_private_key_path
          raise Fluent::ConfigError, "tls_private_key_path is wrong: #{@tls_private_key_path}" unless File.file?(@tls_private_key_path)
          opt[:key] = OpenSSL::PKey.read(File.read(@tls_private_key_path), @tls_private_key_passphrase)
        end
        opt[:verify_mode] = case @tls_verify_mode
                            when :none
                              OpenSSL::SSL::VERIFY_NONE
                            when :peer
                              OpenSSL::SSL::VERIFY_PEER
                            end
        opt[:ciphers] = @tls_ciphers
        opt[:ssl_version] = @tls_version
      end

      opt
    end

    def parse_endpoint(chunk)
      endpoint = extract_placeholders(@endpoint, chunk)
      URI.parse(endpoint)
    end

    def set_headers(req)
      if @headers
        @headers.each do |k, v|
          req[k] = v
        end
      end
      if @override_content_type
        req['Content-Type'] = @override_content_type
      else
        req['Content-Type'] = @content_type
      end
    end

    def create_request(chunk, uri)
      req = case @http_method
            when :post
              Net::HTTP::Post.new(uri.request_uri)
            when :put
              Net::HTTP::Put.new(uri.request_uri)
            end
      if @auth
        req.basic_auth(@auth.username, @auth.password)
      end
      set_headers(req)
      req
    end

    def send_request(uri, req)
      res = if @proxy_uri
              Net::HTTP.start(uri.host, uri.port, @proxy_uri.host, @proxy_uri.port, @proxy_uri.user, @proxy_uri.password, @http_opt) { |http|
                http.request(req)
              }
            else
              Net::HTTP.start(uri.host, uri.port, @http_opt) { |http|
                http.request(req)
              }
            end
      if res.is_a?(Net::HTTPSuccess)
        log.debug { "#{res.code} #{res.message.rstrip}#{res.body.lstrip}" }

        if @first_trace
          log.info "First trace successfully sent to the receiver"
          @first_trace = false
        end

        return true
      else
        msg = "#{res.code} #{res.message.rstrip}"
        log.error "Error during sending traces: #{msg}"
        return false
      end
    end

    def base64_to_hexstring(value)
      if !value
        return value
      end
      return Base64.strict_decode64(value).bytes.pack("c*").unpack("H*").first
    end

    def string_to_hexstring(value)
      if !value then
        return value
      end

      return value.bytes.pack("c*").unpack("H*").first
    end

    def string_to_ipv4(value, length)
      if !value then
        return value
      end

      if value.length < length
        value = "\x00".force_encoding("ASCII-8BIT") * (length - value.length) + value
      end

      return IPAddr.new_ntoh(value).to_s
    end

    def split_chunk(chunk, size: 100)
      return_value = []
      spans = []

      chunk.each do |time, span|
        if !span['trace_id'] then
          next
        end
        if spans.length >= size
          return_value.push(spans)
          spans = []
        end
        spans.push([time, span])
      end

      if spans.length > 0
        return_value.push(spans)
      end

      return return_value
    end

    def get_spans(spans)
      return Zipkin::Proto3::ListOfSpans.encode(
            Zipkin::Proto3::ListOfSpans::new({
              'spans' => spans.map { |time, span| span }
              }))
    end

    def get_str_or_nil(value)
      if !value || value == ''
        return nil
      end

      return value
    end

    def get_spans_for_json(spans)
      return Oj.dump(spans.map { |time, span| get_span_for_json(span) })
    end

    def get_span_for_json(record)

      if value = get_str_or_nil(record.delete('trace_id'))
        record['traceId'] = string_to_hexstring(value)
      end
      if value = get_str_or_nil(record.delete('parent_id'))
        record['parentId'] = string_to_hexstring(value)
      end
      record['id'] = string_to_hexstring(record['id'])  # This line is failing during benchmark test (non-deterministic)

      if value = record.delete('local_endpoint')
        record['localEndpoint'] = value
      end

      if value = record.delete('remote_endpoint')
        record['remoteEndpoint'] = value
      end

      if record['localEndpoint'] then
        if value = get_str_or_nil(record['localEndpoint'].delete('ipv4'))
          record['localEndpoint']['ipv4'] = string_to_ipv4(value, 4)
        end

        if value = get_str_or_nil(record['localEndpoint'].delete('ipv6'))
          record['localEndpoint']['ipv6'] = string_to_ipv4(value, 16)
        end
        record['localEndpoint']['serviceName'] = record['localEndpoint'].delete('service_name')
      end

      if record['remoteEndpoint'] then
        if value = get_str_or_nil(record['remoteEndpoint'].delete('ipv4'))
          record['remoteEndpoint']['ipv4'] = string_to_ipv4(value, 4)
        end
        if value = get_str_or_nil(record['remoteEndpoint'].delete('ipv6'))
          record['remoteEndpoint']['ipv6'] = string_to_ipv4(value, 16)
        end
        record['remoteEndpoint']['serviceName'] = record['remoteEndpoint'].delete('service_name')
      end

      return record
    end

  end
end
