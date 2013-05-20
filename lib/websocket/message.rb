module WebSocket
  class Message
    attr_reader :type, :mask_key, :status_code, :payload, :status_message

    # Return a new ping message
    def self.ping(payload = '')
      new(payload, :ping)
    end

    # Return a new pong message
    def self.pong(payload = '')
      new(payload, :pong)
    end

    # Return a new close message
    def self.close(status_code = nil, reason = nil)
      if status_code && STATUS_CODES[status_code] == nil
        raise ArgumentError.new('Invalid status')
      end

      if reason && status_code == nil
        raise ArgumentError.new("Can't set a status message without status code")
      end

      new(reason, :close, status_code)
    end

    def initialize(message = '', type = :text, status_code = nil)
      @type = type

      @payload = if status_code
        @status_code    = status_code
        @status_message = message

        [status_code, message].pack('S<a*')
      else
        message.force_encoding("ASCII-8BIT") if message
      end
    end

    def mask!
      @second_byte = second_byte | 0b10000000 # Set masked bit
      @mask_key = Random.new.bytes(4)
      @payload = WebSocket.mask(@payload, @mask_key)
    end

    def payload_length
      @payload ? @payload.length : 0
    end

    def masked?
      second_byte & 0b10000000 != 0
    end

    def to_data
      to_a.pack(pack_format)
    end

    def write(io)
      io << to_data
    end

    def control_frame?
      [:close, :ping, :pong].include?(type)
    end

    def status
      STATUS_CODES[status_code]
    end

    private

    def to_a
      [first_byte, second_byte, extended_payload_length, mask_key, payload].compact
    end

    def pack_format
      WebSocket.frame_format(payload_length, masked?)
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

    def extended_payload_length
      message_size == :small ? nil : payload_length
    end

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