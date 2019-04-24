require 'fluent/plugin/filter'

module Fluent
  module Plugin
    # fluentd plugin for convert data point json to carbon v2
    class CarbonV2Filter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter('carbon_v2', self)

      helpers :record_accessor

      config_param(
        :relabel,
        :hash,
        default: {},
        symbolize_keys: false,
        value_type: :string
      )
      config_param(
        :inclusions,
        :hash,
        default: {},
        symbolize_keys: false,
        value_type: :string
      )
      config_param(
        :exclusions,
        :hash,
        default: {},
        symbolize_keys: false,
        value_type: :string
      )
      config_param :strict_inclusions, :bool, default: false
      config_param :strict_exclusions, :bool, default: false
      config_param :space_as, :string, default: '_'
      config_param :sort_labels, :bool, default: true

      def configure(conf)
        super
        @inclusions.each do |key, value|
          @inclusions[key] = Regexp.new(value)
        end
        @exclusions.each do |key, value|
          @exclusions[key] = Regexp.new(value)
        end
        @metric_accessor = record_accessor_create("$.#{KEY_METRIC}")
        @timestamp_accessor = record_accessor_create("$.#{KEY_TIMESTAMP}")
        @value_accessor = record_accessor_create("$.#{KEY_VALUE}")
      end

      def filter(_tag, _time, record)
        dotified = dotify_record(record)
        relabeled = relabel_record(dotified)
        wrap(to_carbon_line(relabeled)) if valid?(relabeled)
      end

      private

      KEY_METRIC = '@metric'.freeze
      KEY_TIMESTAMP = '@timestamp'.freeze
      KEY_VALUE = '@value'.freeze
      KEY_MESSAGE = 'message'.freeze
      SPLITOR = '.'.freeze

      ORIGIN_KEY = '_origin'.freeze
      ORIGIN_VALUE = 'kubernetes'.freeze

      def to_carbon_line(record)
        metric = @metric_accessor.call(record).gsub(/\s/, @space_as)
        timestamp = @timestamp_accessor.call(record)
        value = @value_accessor.call(record)
        "metric=#{metric} #{to_tags(record)}  #{ORIGIN_KEY}=#{ORIGIN_VALUE} #{value} #{timestamp}"
      end

      def valid?(record)
        validate_inclusions(record) && validate_exclusions(record)
      end

      def validate_inclusions(record)
        @inclusions.each do |key, regex|
          return false unless validate_inclusion(key, regex, record)
        end
        true
      end

      def validate_inclusion(key, regex, record)
        if record.key?(key)
          !regex.match(record[key]).nil?
        else
          !@strict_inclusions
        end
      end

      def validate_exclusions(record)
        @exclusions.each do |key, regex|
          return false unless validate_exclusion(key, regex, record)
        end
        true
      end

      def validate_exclusion(key, regex, record)
        if record.key?(key)
          regex.match(record[key]).nil?
        else
          !@strict_exclusions
        end
      end

      def relabel_record(record)
        @relabel.flat_map do |org_key, new_key|
          if record.key?(org_key)
            value = record[org_key]
            record.delete(org_key)
            record[new_key] = value unless new_key.nil? || new_key.empty?
          end
        end
        record
      end

      def to_tags(hash)
        array = @sort_labels ? hash.sort : hash.to_a
        array.map do |key, value|
          "#{key.gsub(/\s/, @space_as)}=#{value.gsub(/\s/, @space_as)}"\
            unless [KEY_METRIC, KEY_TIMESTAMP, KEY_VALUE].include?(key)
        end.compact.join(' ')
      end

      def dotify_record(record)
        dotified = {}
        record.keys.each do |field|
          value = record[field]
          dotify(dotified, field, value, nil)
        end
        dotified
      end

      def dotify(hash, key, value, prefix)
        pk = prefix ? "#{prefix}#{SPLITOR}#{key}" : key.to_s
        if value.is_a?(Hash)
          value.each do |k, v|
            dotify(hash, k, v, pk)
          end
        elsif value.is_a?(Array)
          value.each_with_index.each do |v, i|
            dotify(hash, i.to_s, v, pk)
          end
        else # all non-container types
          hash[pk] = value
        end
      end

      def wrap(message)
        record = {}
        record[KEY_MESSAGE] = message
        record
      end
    end
  end
end
