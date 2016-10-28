# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'api_presenter/version'

Gem::Specification.new do |spec|
  spec.name          = "api_presenter"
  spec.version       = ApiPresenter::VERSION
  spec.authors       = ["Yuval Kordov", "Little Blimp"]
  spec.email         = ["yuval@littleblimp.com"]
  spec.summary       = "Return associations and policies with API responses"
  spec.description   = "Facilitates optimized side loading of associated resources and permission policies from RESTful endpoints"
  spec.homepage      = "http://github.com/uberllama/api_presenter"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "activesupport", ">= 3.0.0"
  spec.add_dependency "pundit"
  spec.add_development_dependency "activerecord", ">= 4.2.3"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3"
end
