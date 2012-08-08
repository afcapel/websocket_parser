require "websocket/version"
require "websocket/client_handshake"
require "websocket/server_handshake"
require "websocket/message"
require "websocket/parser"

module WebSocket
  extend self

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

  # FRAME_FORMAT = {
  #   :small  => 'CCa',   # 2 bytes for header. N bytes for payload.
  #   :medium => 'CCS<a', # 2 bytes for header. 2 bytes for extended length. N bytes for payload.
  #   :large  => 'CCQ<a'  # 2 bytes for header. 4 bytes for extended length. N bytes for payload.
  # }

  def frame_format(payload_length, masked = false)
    format = 'CC'

    if payload_length > 65_535
      format += 'Q<'
    elsif payload_length > 125
      format += 'S<'
    end

    if masked
      format += 'a4'
    end

    format += "a#{payload_length}"
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
