module WebSocket
  class ServerHandshake
    attr_reader :headers

    def initialize(headers = {})
      @headers = headers
    end

    def render(out)
      out << to_data
    end

    def to_data
      data = "HTTP/1.1 101 Switching Protocols#{CRLF}"

      unless @headers.empty?
        data << @headers.map do |header, value|
          "#{header}: #{value}"
        end.join(CRLF) << CRLF
      end

      data << CRLF
      data
    end
  end
end