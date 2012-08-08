module WebSocket
  class Message
    attr_reader :type, :mask_key, :payload

    # Return a new ping message
    def self.ping(message = '')
      new(message, :ping)
    end

    # Return a new pong message
    def self.pong(message = '')
      new(message, :pong)
    end

    # Return a new close message
    def self.close(reason = '')
      new(reason, :close)
    end

    def initialize(message, type = :text)
      @type, @payload = type, message.force_encoding("ASCII-8BIT")
    end

    def mask!
      @second_byte = second_byte | 0b10000000 # Set masked bit
      @mask_key = Random.new.bytes(4)
      @payload = WebSocket.mask(@payload, @mask_key)
    end

    def message_size
      if payload_length < 126
        :small
      elsif payload_length < 65_536 # fits in 2 bytes
        :medium
      else
        :large
      end
    end

    def payload_length
      @payload.length
    end

    def masked?
      second_byte & 0b10000000 != 0
    end

    def extended_payload_length
      message_size == :small ? nil : payload_length
    end

    def to_a
      [first_byte, second_byte, extended_payload_length, mask_key, payload].compact
    end

    def pack_format
      WebSocket.frame_format(payload_length, masked?)
    end

    def to_data
      to_a.pack(pack_format)
    end

    def write(io)
      io << to_data
    end

    private

    def first_byte
      @first_byte ||= if type == :continuation
        OPCODE_VALUES[type]
      else
        0b10000000 | OPCODE_VALUES[type] # set FIN bit to true
      end
    end

    def second_byte
      @second_byte ||= case message_size
      when :small  then payload_length
      when :medium then 126
      when :large  then 127
      end
    end
  end
end