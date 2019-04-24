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

      def multi_workers_ready?
        true
      end

      def process(tag, es)
        es.each do |_time, record|
          write_batch(tag, record)
        end
      end

      private

      KEY_TIMESERIES = 'timeseries'.freeze
      KEY_METRIC = '@metric'.freeze
      KEY_TIMESTAMP = '@timestamp'.freeze
      KEY_VALUE = '@value'.freeze
      ORG_KEY_METRIC = '__name__'.freeze
      ORG_KEY_LABELS = 'labels'.freeze
      ORG_KEY_SAMPLES = 'samples'.freeze
      ORG_KEY_NAME = 'name'.freeze
      ORG_KEY_VALUE = 'value'.freeze
      ORG_KEY_TIMESTAMP = 'timestamp'.freeze

      def write_batch(tag, batch)
        new_tag = @tag || tag
        records = batch[KEY_TIMESERIES].flat_map do |ts|
          create_datapoints(ts)
        end.compact
        records.each do |time, record|
          router.emit(new_tag, time, record)
        end
        log.trace "datapoint::write_batch - in: #{batch[KEY_TIMESERIES].length}, out: #{records.length}"
      end

      def create_datapoints(record)
        labels = record[ORG_KEY_LABELS]
        samples = record[ORG_KEY_SAMPLES]
        template = {}

        labels.each do |label|
          if label[ORG_KEY_NAME] == ORG_KEY_METRIC
            template[KEY_METRIC] = label[ORG_KEY_VALUE]
          else
            template[label[ORG_KEY_NAME]] = label[ORG_KEY_VALUE]
          end
        end

        samples.map do |sample|
          create_sample(sample, template.clone)
        end
      end

      def create_sample(sample, record)
        timestamp = sample[ORG_KEY_TIMESTAMP]
        value = sample[ORG_KEY_VALUE]
        event_time = Fluent::EventTime.new(timestamp / 1000)
        record[KEY_TIMESTAMP] = timestamp
        if value.is_a?(Numeric) && !value.to_f.nan? && !value.to_f.infinite?
          record[KEY_VALUE] = value.to_f
          return event_time, record
        elsif @missing_values.nan?
          log.trace "skipping sample with value #{value} - #{record}"
          return nil
        else
          record[KEY_VALUE] = @missing_values.to_f
          return event_time, record
        end
      end
    end
  end
end
