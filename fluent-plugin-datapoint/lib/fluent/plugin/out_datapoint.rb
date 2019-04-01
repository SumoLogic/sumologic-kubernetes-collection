require 'fluent/plugin/output'

module Fluent
  module Plugin
    # fluentd output plugin for breaking timeseries record into datapoints
    class DatapointOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output('datapoint', self)

      helpers :event_emitter

      config_param :tag, :string, default: nil
      config_param :missing_values, :float, default: Float::NAN

      def configure(conf)
        super
      end

      def process(tag, es)
        es.each do |time, record|
          begin
            write_datapoints(tag, time, record)
          rescue StandardError => exception
            log.error('ERROR during processing', error: exception)
          end
        end
      end

      private

      KEY_METRIC = '@metric'.freeze
      KEY_TIMESTAMP = '@timestamp'.freeze
      KEY_VALUE = '@value'.freeze
      ORG_KEY_METRIC = '__name__'.freeze
      ORG_KEY_LABELS = 'labels'.freeze
      ORG_KEY_SAMPLES = 'samples'.freeze
      ORG_KEY_NAME = 'name'.freeze
      ORG_KEY_VALUE = 'value'.freeze
      ORG_KEY_TIMESTAMP = 'timestamp'.freeze

      def write_datapoints(org_tag, _time, record)
        labels = record[ORG_KEY_LABELS]
        samples = record[ORG_KEY_SAMPLES]
        new_tag = @tag || org_tag
        template = {}

        labels.each do |label|
          if label[ORG_KEY_NAME] == ORG_KEY_METRIC
            template[KEY_METRIC] = label[ORG_KEY_VALUE]
          else
            template[label[ORG_KEY_NAME]] = label[ORG_KEY_VALUE]
          end
        end

        samples.each do |sample|
          datapoint_record = template.clone
          timestamp = sample[ORG_KEY_TIMESTAMP]
          value = sample[ORG_KEY_VALUE]
          datapoint_record[KEY_TIMESTAMP] = timestamp
          if value.is_a?(Numeric) && !value.to_f.nan? && !value.to_f.infinite?
            datapoint_record[KEY_VALUE] = value.to_f
            router.emit(new_tag, timestamp, datapoint_record)
          elsif @missing_values.nan?
            log.trace(
              "skipping sample with value #{value}",
              metric: template[KEY_METRIC],
              timestamp: template[KEY_TIMESTAMP]
            )
          else
            datapoint_record[KEY_VALUE] = @missing_values.to_f
            router.emit(new_tag, timestamp, datapoint_record)
          end
        end
      end
    end
  end
end
