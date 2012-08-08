require "websocket/version"
require "websocket/client_handshake"
require "websocket/server_handshake"
require "websocket/message"
require "websocket/parser"

module WebSocket
  PROTOCOL_VERSION = 13 # RFC 6455
  GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  # see http://tools.ietf.org/html/rfc6455#section-11.8
  OPCODES = {
    0  => :continuation,
    1  => :text,
    2  => :binary,
    8  => :close,
    9  => :ping,
    10 => :pong
  }

  OPCODE_VALUES = {
    :continuation => 0,
    :text         => 1,
    :binary       => 2,
    :close        => 8,
    :ping         => 9,
    :pong         => 10
  }

  FRAME_FORMAT = {
    :small  => 'CCa',   # 2 bytes for header. N bytes for payload.
    :medium => 'CCS<a', # 2 bytes for header. 2 bytes for extended length. N bytes for payload.
    :large  => 'CCQ<a'  # 2 bytes for header. 4 bytes for extended length. N bytes for payload.
  }
end
