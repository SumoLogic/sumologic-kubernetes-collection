module SumoLogic
  module Kubernetes
    # Decorates single record with pod-related metadata
    module RecordDecorator

      def decorate_record(record)
        namespace_name = nil
        pod_name = nil
        @in_namespace_ac.each { |ac| namespace_name ||= ac.call(record) }
        @in_pod_ac.each { |ac| pod_name ||= ac.call(record) }
        if namespace_name.nil?
          log.trace "Record doesn't have [#{@in_namespace_path}] field"
        elsif pod_name.nil?
          log.trace "Record doesn't have [#{@in_pod_path}] field"
        else
          if record.key? 'service'
            record['prometheus_service'] = record['service']
            record.delete('service')
          end
          metadata = get_pod_metadata(namespace_name, pod_name)
          service = @pods_to_services[pod_name]
          metadata['service'] = {'service' => service.sort!.join('_')} if !(service.nil? || service.empty?)

          ['pod_labels', 'owners', 'service'].each do |metadata_type|
            attachment = metadata[metadata_type]
            if attachment.nil? || attachment.empty?
              log.trace "Cannot get #{metadata_type} for pod #{namespace_name}::#{pod_name}, skip."
            else
              case @data_type
              when 'logs'
                record['kubernetes'].merge! attachment if metadata_type != 'pod_labels'
              when 'metrics'
                record.merge! attachment
              else
                record.merge! attachment
              end
            end
          end
        end
      end

    end
  end
end
