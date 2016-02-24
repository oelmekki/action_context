# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'action_context/version'

Gem::Specification.new do |spec|
  spec.name          = "action_context2"
  spec.version       = ActionContext::VERSION
  spec.authors       = ["Olivier El Mekki"]
  spec.email         = ["olivier@el-mekki.com"]

  spec.summary       = %q{Context class to help acting on context}
  spec.description   = %q{ActionContext allow to trim controllers by extracting all the contextual logic into well designed classes}
  spec.homepage      = "http://gitlab.el-mekki.fr:8081/kik/action_context"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
