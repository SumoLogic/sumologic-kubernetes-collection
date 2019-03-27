require 'fluent/plugin/output'

module Fluent
  module Plugin
    # fluentd output plugin for breaking timeseries record into datapoints
    class DatapointOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output('datapoint', self)

      DEFAULT_TAG = 'kubernetes.datapoint'.freeze
      LABEL_METRIC = '@metric'.freeze
      LABEL_TIMESTAMP = '@timestamp'.freeze
      LABEL_VALUE = '@value'.freeze
      LABEL_NAME = '__name__'.freeze

      helpers :compat_parameters, :event_emitter, :record_accessor

      config_param :tag, :string, default: DEFAULT_TAG
      config_param :missing_values, :float, default: Float::NAN

      def configure(conf)
        super
      end

      def process(_tag, es)
        es.each do |time, record|
          begin
            write_datapoints(time, record)
          rescue => exception
            puts exception.message
            puts exception.backtrace
            log.error('ERROR during processing', error: exception)
          end
        end
      end

      private

      def write_datapoints(_time, record)
        labels = record['labels']
        samples = record['samples']
        template = {}

        labels.each do |label|
          if label['name'] == LABEL_NAME
            template[LABEL_METRIC] = label['value']
          else
            template[label['name']] = label['value']
          end
        end

        samples.each do |sample|
          datapoint_record = template.clone
          timestamp = sample['timestamp']
          value = sample['value']
          datapoint_record[LABEL_TIMESTAMP] = timestamp
          if value.is_a?(Numeric) && !value.to_f.nan? && !value.to_f.infinite?
            datapoint_record[LABEL_VALUE] = value.to_f
            router.emit(@tag, timestamp, datapoint_record)
          elsif @missing_values.nan?
            log.trace(
              "skipping sample with value #{value}",
              metric: template[LABEL_METRIC],
              timestamp: template[LABEL_TIMESTAMP]
            )
          else
            datapoint_record[LABEL_VALUE] = @missing_values.to_f
            router.emit(@tag, timestamp, datapoint_record)
          end
        end
      end
    end
  end
end
