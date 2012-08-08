module WebSocket
  class ServerHandshake < Http::Response

    def initialize(status = 101, version = "1.1", headers = {}, body = nil, &body_proc)
      @status, @version, @body, @body_proc = status, version, body, body_proc
      @headers = headers
    end

    def render(out)
      response_header = "#{@version} #{@status} #{@reason}#{CRLF}"

      unless @headers.empty?
        response_header << @headers.map do |header, value|
          "#{header}: #{value}"
        end.join(CRLF) << CRLF
      end

      response_header << CRLF

      out << response_header
    end
  end
end