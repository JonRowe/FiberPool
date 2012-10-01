# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fiberpool/version"

Gem::Specification.new do |s|
  s.name        = "fiberpool"
  s.version     = FiberPool::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jon Rowe"]
  s.email       = ["hello@jonrowe.co.uk"]
  s.homepage    = "http://github.com/jonrowe/fiberpool"
  s.summary     = %q{A Fiberpool implementation for running tasks cooperatively}
  s.description = %q{A Fiberpool implementation for running tasks cooperatively, allows throttling to max concurrency, best used with event machine and non blocking operations.}

  s.rubyforge_project = "fiberpool"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'autotest-standalone'
end
