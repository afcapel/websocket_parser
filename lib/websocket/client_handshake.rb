require 'digest/sha1'
require 'base64'

module WebSocket
  class ClientHandshake < Http::Request

    def self.accept_token_for(websocket_key)
      Base64.encode64(Digest::SHA1.digest(websocket_key.strip + GUID)).strip
    end

    def errors
      @errors ||= []
    end

    def valid?
      if headers['Connection'].downcase != 'upgrade'
        errors << 'Not connection upgrade'
        return false
      end

      if headers['Upgrade'].downcase != 'websocket'
        errors << 'Connection upgrade is not for websocket'
        return false
      end

      # Careful: Http gem changes header capitalization,
      # so Sec-WebSocket-Version becomes Sec-Websocket-Version
      if headers['Sec-Websocket-Version'].to_i != PROTOCOL_VERSION
        errors << "Protocol version not supported '#{headers['Sec-Websocket-Version']}'"
        return false
      end

      return true
    end

    def accept_response
      websocket_key = headers['Sec-Websocket-Key']
      response_headers = {
        'Upgrade'    => 'websocket',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Accept' => ClientHandshake.accept_token_for(websocket_key)
      }

      ServerHandshake.new(101, '1.1', response_headers)
    end
  end
end