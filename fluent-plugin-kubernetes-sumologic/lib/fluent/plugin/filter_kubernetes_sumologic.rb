require "fluent/filter"

module Fluent::Plugin
  class SumoContainerOutput < Fluent::Plugin::Filter
    # Register type
    Fluent::Plugin.register_filter("kubernetes_sumologic", self)

    config_param :source_category, :string, :default => "%{namespace}/%{pod_name}"
    config_param :source_category_replace_dash, :string, :default => "/"
    config_param :source_category_prefix, :string, :default => "kubernetes/"
    config_param :source_name, :string, :default => "%{namespace}.%{pod}.%{container}"
    config_param :log_format, :string, :default => "json"
    config_param :source_host, :string, :default => ""
    config_param :exclude_container_regex, :string, :default => ""
    config_param :exclude_facility_regex, :string, :default => ""
    config_param :exclude_host_regex, :string, :default => ""
    config_param :exclude_namespace_regex, :string, :default => ""
    config_param :exclude_pod_regex, :string, :default => ""
    config_param :exclude_priority_regex, :string, :default => ""
    config_param :exclude_unit_regex, :string, :default => ""
    config_param :tracing_format, :bool, :default => false
    config_param :tracing_namespace, :string, :default => 'namespace'
    config_param :tracing_pod, :string, :default => 'pod'
    config_param :tracing_pod_id, :string, :default => 'pod_id'
    config_param :tracing_container_name, :string, :default => 'container_name'
    config_param :tracing_host, :string, :default => 'hostname'
    config_param :tracing_label_prefix, :string, :default => 'pod_label_'
    config_param :tracing_annotation_prefix, :string, :default => 'pod_annotation_'
    config_param :source_host_key_name, :string, :default => '_sourceHost'
    config_param :source_category_key_name, :string, :default => '_sourceCategory'
    config_param :source_name_key_name, :string, :default => '_sourceName'
    config_param :collector_key_name, :string, :default => '_collector'
    config_param :collector_value, :string, :default => 'undefined'

    def configure(conf)
      super
    end

    def is_number?(string)
      true if Float(string) rescue false
    end

    def sanitize_pod_name(k8s_metadata)
      # Strip out dynamic bits from pod name.
      # NOTE: Kubernetes deployments append a template hash.
      # At the moment this can be in 3 different forms:
      #   1) pre-1.8: numeric in pod_template_hash and pod_parts[-2]
      #   2) 1.8-1.11: numeric in pod_template_hash, hash in pod_parts[-2]
      #   3) post-1.11: hash in pod_template_hash and pod_parts[-2]

      pod_parts = k8s_metadata[:pod].split("-")
      pod_template_hash = k8s_metadata[:"label:pod-template-hash"]
      if (pod_template_hash == pod_parts[-2] ||
          to_hash(pod_template_hash) == pod_parts[-2])
        k8s_metadata[:pod_name] = pod_parts[0..-3].join("-")
      else
        k8s_metadata[:pod_name] = pod_parts[0..-2].join("-")
      end
    end

    def to_hash(pod_template_hash)
      # Convert the pod_template_hash to an alphanumeric string using the same logic Kubernetes
      # uses at https://github.com/kubernetes/apimachinery/blob/18a5ff3097b4b189511742e39151a153ee16988b/pkg/util/rand/rand.go#L119
      alphanums = "bcdfghjklmnpqrstvwxz2456789"
      pod_template_hash.each_byte.map { |i| alphanums[i.to_i % alphanums.length] }.join("")
    end

    def get_kubernetes(record)
      if not @tracing_format
        if record.key?("kubernetes") and not record.fetch("kubernetes").nil?
          # Clone kubernetes hash so we don't override the cache
          # Note (sam 10/9/19): this is a shallow copy; nested hashes can still be overriden
          return record["kubernetes"].clone
        end
        return nil
      else
        return_value = {
          'namespace_name' => record['tags'][@tracing_namespace],
          'pod_name' => record['tags'][@tracing_pod],
          'pod_id' => record['tags'][@tracing_pod_id],
          'container_name' => record['tags'][@tracing_container_name],
          'host' => record['tags'][@tracing_host],
          'labels' => {},
          'annotations' => {}
        }

        label_length = @tracing_label_prefix.length
        annotation_length = @tracing_annotation_prefix.length

        record['tags'].select { |key, value|
          if key.match(/^#{@tracing_label_prefix}./)
            return_value['labels'][key[label_length..-1]] = value
          elsif key.match(/^#{@tracing_annotation_prefix}./)
            return_value['annotations'][key[annotation_length..-1]] = value
          end
        }

        return return_value
      end
    end

    def filter(tag, time, record)
      begin
        return proper_filter(tag, time, record)
      rescue => exception
        log.warn "Error during tagging record #{record}"
        return record
      end
    end

    def proper_filter(tag, time, record)
      log_fields = {}

      # Set the sumo metadata fields
      sumo_metadata = record["_sumo_metadata"] || {}

      if not @tracing_format
        record["_sumo_metadata"] = sumo_metadata
      end

      sumo_metadata[:log_format] = @log_format
      sumo_metadata[:host] = @source_host if @source_host
      sumo_metadata[:source] = @source_name if @source_name
      unless @source_category.nil?
        sumo_metadata[:category] = @source_category.dup
        unless @source_category_prefix.nil?
          sumo_metadata[:category].prepend(@source_category_prefix)
        end
      end
      sumo_metadata[:category].gsub!("-", @source_category_replace_dash)

      # Check systemd exclude filters
      if record.key?("_SYSTEMD_UNIT") and not record.fetch("_SYSTEMD_UNIT").nil?
        unless @exclude_unit_regex.empty?
          return nil if Regexp.compile(@exclude_unit_regex).match(record["_SYSTEMD_UNIT"])
        end
        unless @exclude_facility_regex.empty?
          return nil if Regexp.compile(@exclude_facility_regex).match(record["SYSLOG_FACILITY"])
        end
        unless @exclude_priority_regex.empty?
          return nil if Regexp.compile(@exclude_priority_regex).match(record["PRIORITY"])
        end
        unless @exclude_host_regex.empty?
          return nil if Regexp.compile(@exclude_host_regex).match(record["_HOSTNAME"])
        end
      end

      kubernetes = get_kubernetes(record)
      if not kubernetes.nil?
        # Populate k8s_metadata to use later in sumo_metadata
        k8s_metadata = {
            :namespace => kubernetes["namespace_name"],
            :pod => kubernetes["pod_name"],
            :pod_id => kubernetes['pod_id'],
            :container => kubernetes["container_name"],
            :source_host => kubernetes["host"],
        }
        if kubernetes.has_key? "labels"
          kubernetes["labels"].each { |k, v| k8s_metadata["label:#{k}".to_sym] = v }
        end
        if kubernetes.has_key? "namespace_labels"
          kubernetes["namespace_labels"].each { |k, v| k8s_metadata["namespace_label:#{k}".to_sym] = v }
        end
        k8s_metadata.default = "undefined"

        # Fetch annotations for config
        annotations = kubernetes.fetch("annotations", {})

        unless annotations["sumologic.com/include"] == "true"
          # Check kubernetes exclude filters
          unless @exclude_namespace_regex.empty?
            return nil if Regexp.compile(@exclude_namespace_regex).match(k8s_metadata[:namespace])
          end
          unless @exclude_pod_regex.empty?
            return nil if Regexp.compile(@exclude_pod_regex).match(k8s_metadata[:pod])
          end
          unless @exclude_container_regex.empty?
            return nil if Regexp.compile(@exclude_container_regex).match(k8s_metadata[:container])
          end
          unless @exclude_host_regex.empty?
            return nil if Regexp.compile(@exclude_host_regex).match(k8s_metadata[:source_host])
          end
        end

        sanitize_pod_name(k8s_metadata)

        if annotations["sumologic.com/exclude"] == "true"
          return nil
        end

        sumo_metadata[:log_format] = annotations["sumologic.com/format"] if annotations["sumologic.com/format"]

        unless annotations["sumologic.com/sourceHost"].nil?
          sumo_metadata[:host] = annotations["sumologic.com/sourceHost"]
        end
        unless annotations["sumologic.com/sourceName"].nil?
          sumo_metadata[:source] = annotations["sumologic.com/sourceName"]
        end
        unless annotations["sumologic.com/sourceCategory"].nil?
          sumo_metadata[:category] = annotations["sumologic.com/sourceCategory"].dup.prepend(@source_category_prefix)
        end
        sumo_metadata[:host] = sumo_metadata[:host] % k8s_metadata
        sumo_metadata[:source] = sumo_metadata[:source] % k8s_metadata
        sumo_metadata[:category] = sumo_metadata[:category] % k8s_metadata
        sumo_metadata[:category].gsub!("-", @source_category_replace_dash)

        # Strip sumologic.com annotations
        # Note (sam 10/9/19): we're stripping from the copy, so this has no effect on output
        kubernetes.delete("annotations") if annotations

        if @tracing_format
          # Move data to record in tracing format
          record['tags'][@source_host_key_name] = sumo_metadata[:host]
          record['tags'][@source_name_key_name] = sumo_metadata[:source]
          record['tags'][@source_category_key_name] = sumo_metadata[:category]
          record['tags']['_source'] = 'traces'
          record['tags'][@collector_key_name] = @collector_value
          return record
        end

        if record.key?("docker") and not record.fetch("docker").nil?
          record["docker"].each {|k, v| log_fields[k] = v}
          record.delete("docker") if @log_format == "fields"
        end

        if record.key?("kubernetes") and not record.fetch("kubernetes").nil?
          if kubernetes.has_key? "labels"
            kubernetes["labels"].each { |k, v| log_fields["pod_labels_#{k}".to_sym] = v }
          end
          if kubernetes.has_key? "namespace_labels"
            kubernetes["namespace_labels"].each { |k, v| log_fields["namespace_labels_#{k}".to_sym] = v }
          end
          log_fields["container"] = kubernetes["container_name"] unless kubernetes["container_name"].nil?
          log_fields["namespace"] = kubernetes["namespace_name"] unless kubernetes["namespace_name"].nil?
          log_fields["pod"] = kubernetes["pod_name"] unless kubernetes["pod_name"].nil?
          ["pod_id", "host", "master_url", "namespace_id", "service", "deployment", "daemonset", "replicaset", "statefulset"].each do |key|
            log_fields[key] = kubernetes[key] unless kubernetes[key].nil?
          end
          log_fields["node"] = kubernetes["host"] unless kubernetes["host"].nil?
          record.delete("kubernetes") if @log_format == "fields"
        end
      end

      unless log_fields.nil?
        sumo_metadata[:fields] = log_fields.select{|k,v| !(v.nil? || v.empty?)}.map{|k,v| "#{k}=#{v}"}.join(',')
      end
      record
    end
  end
end