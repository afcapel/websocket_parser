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

    response.status.should == 101
    response.headers['Upgrade'].should == 'websocket'
    response.headers['Connection'].should == 'Upgrade'
    response.headers['Sec-WebSocket-Accept'].should == 's3pPLMBiTxaQ9kYGzzhZRbK+xOo='
  end
end