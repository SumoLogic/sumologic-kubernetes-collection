require "helper"
require "fluent/plugin/parse_protobuf.rb"

class ProtobufParseTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    # flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Parser.new(Fluent::Plugin::ProtobufParse).configure(conf)
  end
end
