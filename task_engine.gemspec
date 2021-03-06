# -*- encoding: utf-8 -*-
require File.expand_path('../lib/task_engine/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Matthew Sperry"]
  gem.email         = ["mbsperry@gmail.com"]
  gem.description   = ["A simple ruby wrapper for the google tasks api"]
  gem.summary       = ["Google tasks via ruby"]
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  #gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.executables << 'task_client'
  gem.executables << 'task_server'
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "task_engine"
  gem.require_paths = ["lib"]

  gem.add_dependency('google-api-client', '>=0.5')
  gem.add_dependency('launchy', '>= 2.1.1')
  gem.add_dependency('encryptor')

  gem.add_development_dependency('guard')
  gem.add_development_dependency('guard-test')
  gem.add_development_dependency('rb-fsevent')
  gem.add_development_dependency('terminal-notifier-guard')
  gem.add_development_dependency('pry-debugger')

  gem.version       = TaskEngine::VERSION
end
