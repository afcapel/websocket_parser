require 'spec_helper'

describe WebSocket::Message do
  it "knows its binary representation" do
    text = 1500.times.collect { 'All work and no play makes Jack a dull boy.' }.join("\n\n")
    message = WebSocket::Message.new(text)
    data = message.to_data

    # 2 bytes from header + 8 bytes from extended payload length + payload
    data.size.should eq(2 + 8 + text.length)

    first_byte, second_byte, ext_length, payload = data.unpack("CCQ>a#{text.length}")

    first_byte.should  eq(0b10000001) # Text frame with FIN bit set
    second_byte.should eq(0b01111111) # Unmasked. Payload length 127.
    ext_length.should  eq(text.length)
    payload.should     eq(text)
  end

  it "can be masked" do
    message = WebSocket::Message.new('The man with the Iron Mask')
    message.masked?.should be_false

    message.mask!

    message.masked?.should be_true
  end

  it "allows status codes for control frames" do
    msg = WebSocket::Message.close(1001, 'Bye')

    msg.status_code.should eq(1001)
    msg.payload.should eq([1001, 'Bye'].pack('S<a*'))
    msg.status.should eq(:peer_going_away)
    msg.status_message.should eq('Bye')
  end

  it "does not allow a status message without status code" do
    expect{ WebSocket::Message.close(nil, 'Bye') }.to raise_error(ArgumentError)
  end

  it "can create a pong message from a ping message" do
    ping = WebSocket::Message.ping('Roman Ping Pong')
    pong = WebSocket::Message.pong(ping.payload)

    pong.type.should    eq(:pong)
    pong.payload.should eq('Roman Ping Pong')
  end
end
