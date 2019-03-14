require "helper"
require "fluent/plugin/out_datapoint.rb"

class DatapointOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::DatapointOutput).configure(conf)
  end
end
