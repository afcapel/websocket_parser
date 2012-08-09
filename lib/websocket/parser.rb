module WebSocket
  #
  # This class parses WebSocket messages and frames.
  #
  # Each message is divied in frames as described in RFC 6455.
  #
  #    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  #   +-+-+-+-+-------+-+-------------+-------------------------------+
  #   |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
  #   |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
  #   |N|V|V|V|       |S|             |   (if payload len==126/127)   |
  #   | |1|2|3|       |K|             |                               |
  #   +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
  #   |     Extended payload length continued, if payload len == 127  |
  #   + - - - - - - - - - - - - - - - +-------------------------------+
  #   |                               |Masking-key, if MASK set to 1  |
  #   +-------------------------------+-------------------------------+
  #   | Masking-key (continued)       |          Payload Data         |
  #   +-------------------------------- - - - - - - - - - - - - - - - +
  #   :                     Payload Data continued ...                :
  #   + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
  #   |                     Payload Data continued ...                |
  #   +---------------------------------------------------------------+
  #
  # for more info on the frame format see: http://tools.ietf.org/html/rfc6455#section-5
  #
  class Parser
    def initialize
      @data =  ''.force_encoding("ASCII-8BIT")
      @state = :header
    end

    def on_message(&callback)
      @on_message = callback
    end

    def on_error(&callback)
      @on_error = callback
    end

    def on_close(&callback)
      @on_close = callback
    end

    def on_ping(&callback)
      @on_ping = callback
    end

    def on_pong(&callback)
      @on_pong = callback
    end

    def receive(data)
      @data << data

      read_header         if @state == :header
      read_payload_length if @state == :payload_length
      read_mask_key       if @state == :mask
      read_payload        if @state == :payload

      process_frame if @state == :complete
    end

    alias_method :<<, :receive

    private

    def read_header
      return unless @data.length >= 2 # Not enough data

      @first_byte, @second_byte = @data.slice!(0,2).unpack('C2')
      @state = :payload_length
    end

    def read_payload_length
      @payload_length = if message_size == :small
         payload_length_field
      else
        read_extended_payload_length
      end

      return unless @payload_length

      @state = masked? ? :mask : :payload
    end

    def read_extended_payload_length
      if message_size == :medium && @data.size >= 2
         unpack_bytes(2,'S<')
      elsif message_size == :large && @data.size >= 4
        unpack_bytes(8,'Q<')
      end
    end

    def read_mask_key
      return unless @data.size >= 4

      @mask_key = unpack_bytes(4,'a4')
      @state = :payload
    end

    def read_payload
      return unless @data.length >= @payload_length # Not enough data

      payload_data = unpack_bytes(@payload_length, "a#{@payload_length}")

      @payload = if masked?
        WebSocket.unmask(payload_data, @mask_key)
      else
        payload_data
      end

      @state = :complete if @payload
    end

    def unpack_bytes(num, format)
      @data.slice!(0,num).unpack(format).first
    end

    def control_frame?
      [:close, :ping, :pong].include?(opcode)
    end

    def process_frame
      if @current_message
        @current_message << @payload
      else
        @current_message = @payload
      end

      if fin?
        process_message
      end

      reset_frame!
    end

    def process_message
      case opcode
      when :text
        @on_message.call(@current_message.force_encoding("UTF-8")) if @on_message
      when :binary
        @on_message.call(@current_message) if @on_message
      when :ping
        @on_ping.call if @on_ping
      when :pong
        @on_pong.call if @on_ping
      when :close
        status_code, message = @current_message.unpack('S<a*')
        status = STATUS_CODES[status_code]

        @on_close.call(status, message) if @on_close
      end

      @current_message = nil
    end

    # Whether the FIN bit is set. The FIN bit indicates that
    # this is the final fragment in a message
    def fin?
      @first_byte & 0b10000000 != 0
    end

    def opcode
      @opcode ||= OPCODES[@first_byte & 0b00001111]
    end

    def masked?
      @second_byte & 0b10000000 != 0
    end

    def payload_length_field
      @second_byte & 0b01111111
    end

    def message_size
      if payload_length_field < 126
        :small
      elsif payload_length_field == 126
        :medium
      elsif payload_length_field == 127
        :large
      end
    end

    def pack_format
      WebSocket.frame_format(actual_payload_length, masked?)
    end

    def reset_frame!
      @state = :header

      @first_byte  = nil
      @second_byte = nil

      @mask = nil

      @payload_length = nil
      @payload        = nil
    end
  end
end