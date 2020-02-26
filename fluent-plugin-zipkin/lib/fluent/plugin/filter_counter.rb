# Count and show data processing speed in records per second.
# Time resolution: 5 seconds
require 'fluent/plugin/filter'
require 'time'

module Fluent::Plugin
  class CounterFilter < Filter
    Fluent::Plugin.register_filter('counter', self)

    def configure(conf)
      super
      @count = 0
      @last_timestamp = Time.now.to_f
      @timestamp = Time.now.to_f
    end

    def multi_workers_ready?
      true
    end

    def filter(tag, time, record)
      @count = @count + 1
      @timestamp = Time.now.to_f
      if @timestamp > @last_timestamp + 5 then
        @log.info "Current speed: #{@count/(@timestamp-@last_timestamp)}"
        @last_timestamp = @timestamp
        @count = 0
      end
      record
    end
  end
end