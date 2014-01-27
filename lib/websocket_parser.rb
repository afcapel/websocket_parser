require "websocket/version"
require "websocket/client_handshake"
require "websocket/server_handshake"
require "websocket/message"
require "websocket/parser"

module WebSocket
  extend self

  class WebSocket::ParserError < StandardError; end

  PROTOCOL_VERSION = 13 # RFC 6455
  GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
  CRLF = "\r\n"

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

  # See: http://tools.ietf.org/html/rfc6455#section-7.4.1
  STATUS_CODES = {
    1000 => :normal_closure,
    1001 => :peer_going_away,
    1002 => :protocol_error,
    1003 => :data_error,
    1007 => :data_not_consistent,
    1008 => :policy_violation,
    1009 => :message_too_big,
    1010 => :extension_required,
    1011 => :unexpected_condition
  }

  # Determines how to unpack the frame depending on
  # the payload length and wether the frame is masked
  def frame_format(payload_length, masked = false)
    format = 'CC'

    if payload_length > 65_535
      format += 'Q>'
    elsif payload_length > 125
      format += 'n'
    end

    if masked
      format += 'a4'
    end

    if payload_length > 0
      format += "a#{payload_length}"
    end

    format
  end

  def mask(data, mask_key)
    masked_data = ''.encode!("ASCII-8BIT")
    mask_bytes = mask_key.bytes.to_a

    data.bytes.each_with_index do |byte, i|
      masked_data << (byte ^ mask_bytes[i%4])
    end

    masked_data
  end

  # The same algorithm applies regardless of the direction of the translation,
  # e.g., the same steps are applied to mask the data as to unmask the data.
  alias_method :unmask, :mask

end
