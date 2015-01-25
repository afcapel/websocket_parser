require 'spec_helper'

describe WebSocket::Message do
  it "knows binary representation of messages with more than 65,535 bytes" do
    text = 1500.times.collect { 'All work and no play makes Jack a dull boy.' }.join("\n\n")
    message = WebSocket::Message.new(text)
    data = message.to_data

    # 2 bytes from header + 8 bytes from extended payload length + payload
    expect(data.size).to eq(2 + 8 + text.length)

    first_byte, second_byte, ext_length, payload = data.unpack("CCQ>a#{text.length}")

    expect(first_byte).to  eq(0b10000001) # Text frame with FIN bit set
    expect(second_byte).to eq(0b01111111) # Unmasked. Payload length 127.
    expect(ext_length).to  eq(text.length)
    expect(payload).to     eq(text)
  end

  it "knows binary representation of messages between 126 and 65,535 bytes" do
    text = '0'*127
    data = WebSocket::Message.new(text).to_data

    # 2 bytes from header + 2 bytes from extended payload length + payload
    expect(data.size).to eq(2 + 2 + text.length)
    # extended payload length should respect endianness
    expect(data[2..3]).to eq([0x00, 0x7F].pack('C*'))

    first_byte, second_byte, ext_length, payload = data.unpack("CCna#{text.length}")

    expect(first_byte).to  eq(0b10000001) # Text frame with FIN bit set
    expect(second_byte).to eq(0b01111110) # Unmasked. Payload length 126.
    expect(ext_length).to  eq(text.length)
    expect(payload).to     eq(text)
  end

  it "knows binary representation of messages with less than 126 bytes" do
    text = '0'*125
    data = WebSocket::Message.new(text).to_data

    # 2 bytes from header + payload
    expect(data.size).to eq(2 + text.length)

    first_byte, second_byte, payload = data.unpack("CCa#{text.length}")

    expect(first_byte).to  eq(0b10000001) # Text frame with FIN bit set
    expect(second_byte).to eq(0b01111101) # Unmasked. Payload length 125.
    expect(payload).to     eq(text)
  end

  it "can be masked" do
    message = WebSocket::Message.new('The man with the Iron Mask')
    expect(message.masked?).to be_falsey

    message.mask!

    expect(message.masked?).to be_truthy
  end

  it "allows status codes for control frames" do
    msg = WebSocket::Message.close(1001, 'Bye')

    expect(msg.status_code).to eq(1001)
    expect(msg.payload).to eq([1001, 'Bye'].pack('S<a*'))
    expect(msg.status).to eq(:peer_going_away)
    expect(msg.status_message).to eq('Bye')
  end

  it "does not allow a status message without status code" do
    expect{ WebSocket::Message.close(nil, 'Bye') }.to raise_error(ArgumentError)
  end

  it "can create a pong message from a ping message" do
    ping = WebSocket::Message.ping('Roman Ping Pong')
    pong = WebSocket::Message.pong(ping.payload)

    expect(pong.type).to    eq(:pong)
    expect(pong.payload).to eq('Roman Ping Pong')
  end
end
