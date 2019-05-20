require "helper"
require "fluent/plugin/filter_enhance_k8s_metadata.rb"

class EnhanceK8sMetadataFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::EnhanceK8sMetadataFilter).configure(conf)
  end
end
