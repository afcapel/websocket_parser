# WebSocketParser
[![Build Status](https://secure.travis-ci.org/afcapel/websocket_parser.png)](http://travis-ci.org/afcapel/websocket_parser)

WebsocketParser is a RFC6455 compliant parser for websocket messages written in Ruby. It
is intended to write websockets servers in Ruby, but it only handles the parsing of the
WebSocket protocol, leaving I/O to the server.

## Installation

Add this line to your application's Gemfile:

    gem 'websocket_parser'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install websocket_parser

## Usage

```ruby
require 'websocket_parser'

socket = # Handle I/O with your server/event loop.

parser = WebSocket::Parser.new

parser.on_message do |m|
  puts "Received message #{m}"
end

parser.on_error do |m|
  puts "Received error #{m}"
  socket.close!
end

parser.on_close do |status, message|
  # According to the spec the server must respond with another
  # close message before closing the connection

  socket << WebSocket::Message.close.to_data
  socket.close!

  puts "Client closed connection. Status: #{status}. Reason: #{m}"
end

parser.on_ping do
  socket << WebSocket::Message.pong.to_data
end

parser << socket.read(4096)

# To send a message:

socket << WebSocket::Message.new('Hi there!').to_data

```

## Status

Websocket Parser is still in early development phase.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
