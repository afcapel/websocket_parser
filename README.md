# WebSocketParser
[![Build Status](https://secure.travis-ci.org/afcapel/websocket_parser.png)](http://travis-ci.org/afcapel/websocket_parser)
[![Code Climate](https://codeclimate.com/github/afcapel/websocket_parser.png)](https://codeclimate.com/github/afcapel/websocket_parser)

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

## Usage. TMTOWTDI.

### Return values

The simplest way to use the websocket parser is to create a new one, fetch
it with data and query it for new messages.

```ruby
require 'websocket_parser'

parser = WebSocket::Parser.new

parser.append data

parser.next_message  # return next message or nil
parser.next_messages # return an array with all parsed messages

# To send a message:

socket << WebSocket::Message.new('Hi there!').to_data

```

Only text or binary messages are returned on the parse methods. To intercept
control frames use the parser's callbacks.

### Use callbacks

In addition to return values, you can register callbacks to get notified when a certain event
happens.

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

  puts "Client closed connection. Status: #{status}. Reason: #{message}"
end

parser.on_ping do |payload|
  socket << WebSocket::Message.pong(payload).to_data
end

parser << socket.read(4096)

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
