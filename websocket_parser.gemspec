# -*- encoding: utf-8 -*-
require File.expand_path('../lib/websocket/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Alberto Fernandez-Capel"]
  gem.email         = ["afcapel@gmail.com"]
  gem.description   = %q{WebsocketParser is a RFC6455 compliant parser for websocket messages}
  gem.summary       = %q{Parse websockets messages in Ruby}
  gem.homepage      = "http://github.com/afcapel/websocket_parser"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "websocket_parser"
  gem.require_paths = ["lib"]
  gem.version       = WebSocket::VERSION

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
