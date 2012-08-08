module WebSocket
  class ServerHandshake < Http::Response

    def initialize(status = nil, version = "1.1", headers = {}, body = nil, &body_proc)
      @status, @version, @body, @body_proc = status, version, body, body_proc
      @headers = headers
    end
  end
end