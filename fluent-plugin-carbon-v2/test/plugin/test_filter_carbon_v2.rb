require "helper"
require "fluent/plugin/filter_carbon_v2.rb"

class CarbonV2FilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::CarbonV2Filter).configure(conf)
  end
end
