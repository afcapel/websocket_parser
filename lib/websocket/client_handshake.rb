require 'digest/sha1'

module WebSocket
  class ClientHandshake < Http::Request

    def initialize(method, uri, headers = {}, proxy = {}, body = nil, version = "1.1")
      @method = method.to_s.downcase.to_sym
      @uri = uri.is_a?(URI) ? uri : URI(uri.to_s)

      @headers = headers
      @proxy, @body, @version = proxy, body, version
    end

    def valid?
      headers['Connection'] == 'Upgrade'   &&
      headers['Upgrade']    == 'websocket' &&
      headers['Sec-WebSocket-Version'].to_i == PROTOCOL_VERSION
    end

    def accept_response
      response_headers = {
        'Upgrade'    => 'websocket',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Accept' => accept_token
      }

      ServerHandshake.new(101, '1.1', response_headers)
    end

    private

    def accept_token
      Digest::SHA1.base64digest(headers['Sec-WebSocket-Key'].strip + GUID)
    end
  end
end