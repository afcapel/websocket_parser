require 'digest/sha1'

module WebSocket
  class ClientHandshake < Http::Request

    def self.accept_token_for(websocket_key)
      Digest::SHA1.base64digest(websocket_key.strip + GUID)
    end

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
        'Sec-WebSocket-Accept' => ClientHandshake.accept_token_for(headers['Sec-WebSocket-Key'])
      }

      ServerHandshake.new(101, '1.1', response_headers)
    end
  end
end