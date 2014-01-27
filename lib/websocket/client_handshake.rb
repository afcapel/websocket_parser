require 'digest/sha1'
require 'base64'

module WebSocket
  class ClientHandshake

    attr_reader :verb, :uri, :headers, :proxy, :body, :version

    def self.accept_token_for(websocket_key)
      Base64.encode64(Digest::SHA1.digest(websocket_key.strip + GUID)).strip
    end

    def initialize(verb, uri, headers = {}, proxy = {}, body = nil, version = '1.1')
      @verb, @headers, @proxy, @body, @version = verb, headers, proxy, body, version
      @uri = uri.is_a?(URI) ? uri : URI(uri.to_s)
    end

    def errors
      @errors ||= []
    end

    def valid?
      if headers['Upgrade'].downcase != 'websocket'
        errors << 'Connection upgrade is not for websocket'
        return false
      end

      if websocket_version_header.to_i != PROTOCOL_VERSION
        errors << "Protocol version not supported '#{websocket_version_header}'"
        return false
      end

      return true
    end

    def accept_response
      ServerHandshake.new(response_headers)
    end

    def response_headers
      {
        'Upgrade'    => 'websocket',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Accept' => ClientHandshake.accept_token_for(websocket_key_header)
      }
    end

    def websocket_version_header
      headers['Sec-WebSocket-Version'] || headers['Sec-Websocket-Version']
    end

    def websocket_key_header
      headers['Sec-Websocket-Key'] || headers['Sec-WebSocket-Key']
    end

    def to_data
      data = "#{verb.to_s.upcase} #{uri.path} HTTP/#{version}#{CRLF}"
      @headers.each do |field, value|
        data << "#{field}: #{value}#{CRLF}"
      end
      data << CRLF
      data
    end
  end
end