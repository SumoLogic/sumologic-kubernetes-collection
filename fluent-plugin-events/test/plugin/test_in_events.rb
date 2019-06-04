require "helper"
require "fluent/plugin/in_events.rb"

class EventsInputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::EventsInput).configure(conf)
  end
end
