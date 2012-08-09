module WebSocket
  class ServerHandshake < Http::Response
    CRLF = "\r\n"

    def initialize(status = 101, version = "1.1", headers = {}, body = nil, &body_proc)
      @status, @version, @body, @body_proc = status, version, body, body_proc
      @headers = headers
    end

    def render(out)
      out << to_data
    end

    def to_data
      data = "#{@version} #{@status} #{@reason}#{CRLF}"

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