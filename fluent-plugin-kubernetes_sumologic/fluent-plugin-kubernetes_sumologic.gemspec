# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-kubernetes_sumologic"
  gem.version       = "0.0.0"
  gem.authors       = ["Sumo Logic"]
  gem.email         = ["collection@sumologic.com"]
  gem.description   = %q{FluentD plugin to extract logs from Kubernetes clusters, enrich and ship to Sumo logic.}
  gem.summary       = %q{FluentD plugin to extract logs from Kubernetes clusters, enrich and ship to Sumo logic.}
  gem.homepage      = "https://github.com/SumoLogic/fluentd-kubernetes-sumologic"
  gem.license       = "Apache-2.0"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_development_dependency "bundler", "~> 2"
  gem.add_development_dependency "rake"
  gem.add_development_dependency 'test-unit', '~> 3.1.0'
  gem.add_development_dependency "codecov", ">= 0.1.10"
  gem.add_runtime_dependency "fluentd", ">= 0.14.12"
  gem.add_runtime_dependency 'httpclient', '~> 2.8.0'
end
