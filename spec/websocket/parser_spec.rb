require 'spec_helper'

describe WebSocket::Parser do

  let(:received_messages) { [] }
  let(:received_errors)   { [] }
  let(:received_closes)   { [] }
  let(:received_pings)    { [] }
  let(:received_pongs)    { [] }

  let(:parser) do
    parser = WebSocket::Parser.new

    parser.on_message { |m| received_messages << m }
    parser.on_error   { |m| received_errors << m }
    parser.on_close   { |status, message| received_closes << [status, message] }
    parser.on_ping    { received_pings << 'ping' }
    parser.on_pong    { received_pongs << 'pong' }

    parser
  end

  it "recognizes a text message" do
    parser << WebSocket::Message.new('Once upon a time').to_data

    received_messages.first.should == 'Once upon a time'
  end

  it "can receive a message in parts" do
    data = WebSocket::Message.new('Once upon a time').to_data
    parser << data.slice!(0, 5)

    received_messages.should be_empty

    parser << data

    received_messages.first.should == 'Once upon a time'
  end

  it "can receive succesive messages" do
    msg1 = WebSocket::Message.new('Now is the winter of our discontent')
    msg2 = WebSocket::Message.new('Made glorious summer by this sun of York')

    parser << msg1.to_data
    parser << msg2.to_data

    received_messages[0].should == 'Now is the winter of our discontent'
    received_messages[1].should == 'Made glorious summer by this sun of York'
  end

  it "can receive medium size messages" do
    # Medium size messages has a payload length between 127 and 65_535 bytes

    text = 4.times.collect { 'All work and no play makes Jack a dull boy.' }.join("\n\n")
    text.length.should > 127
    text.length.should < 65_536

    parser << WebSocket::Message.new(text).to_data
    received_messages.first.should == text
  end

  it "can receive large size messages" do
    # Large size messages has a payload length greater than 65_535 bytes

    text = 1500.times.collect { 'All work and no play makes Jack a dull boy.' }.join("\n\n")
    text.length.should > 65_536

    parser << WebSocket::Message.new(text).to_data

    # Check lengths first to avoid gigantic error message
    received_messages.first.length.should == text.length
    received_messages.first.should == text
  end

  it "can receive multiframe messages" do
    frame1 = WebSocket::Message.new("It is a truth universally acknowledged,", :continuation)
    frame2 = WebSocket::Message.new("that a single man in possession of a good fortune,", :continuation)
    frame3 = WebSocket::Message.new("must be in want of a wife.")

    parser << frame1.to_data

    received_messages.should be_empty

    parser << frame2.to_data

    received_messages.should be_empty

    parser << frame3.to_data

    received_messages.first.should == "It is a truth universally acknowledged," +
    "that a single man in possession of a good fortune," +
    "must be in want of a wife."
  end

  it "recognizes a ping message" do
    parser << WebSocket::Message.ping.to_data

    received_pings.size.should == 1
  end

  it "recognizes a pong message" do
    parser << WebSocket::Message.pong.to_data

    received_pongs.size.should == 1
  end

  it "recognizes a close message with status code and message" do
    parser << WebSocket::Message.close(1001, 'Browser leaving page').to_data

    status, message = received_closes.first
    status.should  == :peer_going_away # Status code 1001
    message.should == 'Browser leaving page'
  end

  it "recognizes a close message without status code" do
    parser << WebSocket::Message.close.to_data

    status, message = received_closes.first
    status.should  be_nil
    message.should be_empty
  end

  it "recognizes a masked frame" do
    msg = WebSocket::Message.new('Once upon a time')
    msg.mask!

    parser << msg.to_data

    received_messages.first.should == 'Once upon a time'
  end
end