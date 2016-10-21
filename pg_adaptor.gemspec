# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pg_adaptor/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jon Rowe"]
  gem.email         = ["hello@jonrowe.co.uk"]
  gem.description   = %q{A simple pg handler. Translates Structs into PG and back.}
  gem.summary       = %q{A simple pg handler. Translates Structs into PG and back.}
  gem.homepage      = "https://github.com/JonRowe/PGAdaptor"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pg_adaptor"
  gem.require_paths = ["lib"]
  gem.version       = PGAdaptor::VERSION

  gem.add_dependency 'pg'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
