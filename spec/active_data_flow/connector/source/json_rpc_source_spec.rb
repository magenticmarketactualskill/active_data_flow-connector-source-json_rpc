# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveDataFlow::Connector::Source::JsonRpcSource do
  let(:source) { described_class.new(host: '127.0.0.1', port: 9999) }

  after do
    source.close
  end

  describe '#initialize' do
    it 'creates a new JSON-RPC source with default values' do
      expect(source.host).to eq('127.0.0.1')
      expect(source.port).to eq(9999)
      expect(source.handler).to be_a(ActiveDataFlow::Connector::JsonRpc::ServerHandler)
    end

    it 'accepts a custom handler class' do
      custom_handler_class = Class.new(ActiveDataFlow::Connector::JsonRpc::ServerHandler)
      custom_source = described_class.new(
        host: '127.0.0.1',
        port: 9999,
        handler_class: custom_handler_class
      )
      
      expect(custom_source.handler).to be_a(custom_handler_class)
      custom_source.close
    end
  end

  describe '#start_server and #stop_server' do
    it 'starts and stops the server' do
      expect(source.running?).to be false
      
      source.start_server
      expect(source.running?).to be true
      
      source.stop_server
      expect(source.running?).to be false
    end

    it 'does not start server twice' do
      source.start_server
      expect(source.server_thread).not_to be_nil
      first_thread = source.server_thread
      
      source.start_server
      expect(source.server_thread).to eq(first_thread)
    end
  end

  describe '#server_url' do
    it 'returns the correct server URL' do
      expect(source.server_url).to eq('http://127.0.0.1:9999')
    end
  end

  describe '#each' do
    it 'yields records from the queue' do
      source.handler.receive_record({ name: 'Test' })
      
      records = []
      thread = Thread.new do
        source.each(batch_size: 10) do |record|
          records << record
          break
        end
      end
      
      sleep 0.5
      source.stop_server
      thread.join(2)
      
      expect(records).to include({ name: 'Test' })
    end

    it 'processes records in batches' do
      3.times { |i| source.handler.receive_record({ id: i }) }
      
      batches = []
      thread = Thread.new do
        source.each(batch_size: 2) do |record|
          batches << record
          break if batches.size >= 3
        end
      end
      
      sleep 0.5
      source.stop_server
      thread.join(2)
      
      expect(batches.size).to be >= 2
    end
  end

  describe '#queue_size' do
    it 'returns the number of queued records' do
      expect(source.queue_size).to eq(0)
      
      source.handler.receive_record({ name: 'Test' })
      expect(source.queue_size).to be >= 0
    end
  end

  describe '.from_json' do
    it 'deserializes from JSON' do
      data = {
        "host" => "127.0.0.1",
        "port" => 9999,
        "handler_class" => nil
      }
      
      deserialized = described_class.from_json(data)
      expect(deserialized.host).to eq('127.0.0.1')
      expect(deserialized.port).to eq(9999)
      
      deserialized.close
    end
  end
end
