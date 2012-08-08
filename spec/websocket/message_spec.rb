require 'spec_helper'

describe WebSocket::Message do

  it "knows its binary representation" do
    text = 1500.times.collect { 'All work and no play makes Jack a dull boy.' }.join("\n\n")
    message = WebSocket::Message.new(text)
    data = message.to_data

    # 2 bytes from header + 8 bytes from extended payload length + payload
    data.size.should == 2 + 8 + text.length

    first_byte, second_byte, ext_length, payload = data.unpack("CCQ<a#{text.length}")

    first_byte.should  == 0b10000001 # Text frame with FIN bit set
    second_byte.should == 0b01111111 # Unmasked. Payload length 127.
    ext_length.should  == text.length
    payload.should     == text
  end
end