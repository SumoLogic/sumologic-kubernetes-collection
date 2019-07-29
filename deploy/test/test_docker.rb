require 'test/unit'

class TestDocker < Test::Unit::TestCase
  CONTAINER_NAME = 'test-container'.freeze
  DUMMY_OUTPUT = 'dummy: {"hello":"world"}'.freeze

  def setup
    system("docker rm -f #{CONTAINER_NAME}", out: File::NULL, err: File::NULL)
  end

  def teardown
    system("docker rm -f #{CONTAINER_NAME}", out: File::NULL, err: File::NULL)
  end

  def docker_tag
    ENV['DOCKER_TAG'].nil? ? 'sumologic/kubernetes-fluentd' : ENV['DOCKER_TAG']
  end

  def test_docker_image_exist
    result = `docker images`
    assert result.include?(docker_tag)
  end

  def test_docker_image_runnable
    id = `docker run -d --rm --name #{CONTAINER_NAME} #{docker_tag}:local`
    assert !id.nil? && !id.empty?
    sleep_time = 15
    sleep sleep_time
    result = `docker ps --filter "name=#{CONTAINER_NAME}"`
    assert(
      result.include?(CONTAINER_NAME),
      "container stopped after #{sleep_time} seconds"
    )
    logs = `docker logs #{CONTAINER_NAME}`
    puts logs
    assert logs.include?(DUMMY_OUTPUT)
  end
end
