require 'test/unit'

class TestDocker < Test::Unit::TestCase
  DOCKER_TAG = 'sumologic/kubernetes-fluentd'.freeze
  CONTAINER_NAME = 'test-container'.freeze
  DUMMY_OUTPUT = 'dummy: {"hello":"world"}'.freeze

  def setup
    system("docker rm -f #{CONTAINER_NAME}", out: File::NULL, err: File::NULL)
  end

  def teardown
    system("docker rm -f #{CONTAINER_NAME}", out: File::NULL, err: File::NULL)
  end

  def test_docker_image_exist
    result = `docker images`
    assert result.include?(DOCKER_TAG)
  end

  def test_docker_image_runnable
    id = `docker run -d --rm --name #{CONTAINER_NAME} #{DOCKER_TAG}:latest`
    assert !id.nil? && !id.empty?
    [1..20].each do |i|
      sleep 1
      result = `docker ps --filter "name=#{CONTAINER_NAME}"`
      assert(
        result.include?(CONTAINER_NAME),
        "container stopped after #{i} seconds"
      )
    end
    logs = `docker logs #{CONTAINER_NAME}`
    puts logs
    assert logs.include?(DUMMY_OUTPUT)
  end
end
