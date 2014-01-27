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
    client_handshake.valid?.should be_true
  end

  it "can generate an accept response for the client" do
    response = client_handshake.accept_response

    response.headers['Upgrade'].should eq('websocket')
    response.headers['Connection'].should eq('Upgrade')
    response.headers['Sec-WebSocket-Accept'].should eq('s3pPLMBiTxaQ9kYGzzhZRbK+xOo=')
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

    client_handshake.to_data.should eq expected_lines.join("\r\n")
  end
end
