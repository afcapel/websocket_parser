require 'spec_helper'

describe WebSocket::ClientHandshake do
  let :handshake_headers do
    {
      "Host"                   => "server.example.com",
      "Upgrade"                => "websocket",
      "Connection"             => "Upgrade",
      "Sec-WebSocket-Key"      => "dGhlIHNhbXBsZSBub25jZQ==",
      "Origin"                 => "http://example.com",
      "Sec-WebSocket-Protocol" => "chat, superchat",
      "Sec-WebSocket-Version"  => "13"
    }
  end

  let(:client_handshake) { WebSocket::ClientHandshake.new(:get, '/', handshake_headers) }

  it "can validate handshake format" do
    expect(client_handshake.valid?).to be_truthy
  end

  it "can generate an accept response for the client" do
    response = client_handshake.accept_response

    expect(response.headers['Upgrade']).to eq('websocket')
    expect(response.headers['Connection']).to eq('Upgrade')
    expect(response.headers['Sec-WebSocket-Accept']).to eq('s3pPLMBiTxaQ9kYGzzhZRbK+xOo=')
  end

  it "can be seariakized to data" do
    expected_lines = [
      "GET / HTTP/1.1",
      "Host: server.example.com",
      "Upgrade: websocket",
      "Connection: Upgrade",
      "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==",
      "Origin: http://example.com",
      "Sec-WebSocket-Protocol: chat, superchat",
      "Sec-WebSocket-Version: 13",
      "\r\n"
    ]

    expect(client_handshake.to_data).to eq expected_lines.join("\r\n")
  end
end
