# frozen_string_literal: true

Given('a JSON-RPC source connector') do
  @source = ActiveDataFlow::Connector::Source::JsonRpcSource.new(
    host: '127.0.0.1',
    port: 9998
  )
end

Given('a JSON-RPC source connector on port {int}') do |port|
  @source = ActiveDataFlow::Connector::Source::JsonRpcSource.new(
    host: '0.0.0.0',
    port: port
  )
end

Given('the server is started') do
  @source.start_server
  sleep 0.5 # Give server time to start
end

When('I start the server') do
  @source.start_server
  sleep 0.5
end

When('I stop the server') do
  @source.stop_server
end

Then('the server should be running') do
  expect(@source.running?).to be true
end

Then('the server should not be running') do
  expect(@source.running?).to be false
end

When('I send a record to the server') do
  @record = { name: 'John Doe', email: 'john@example.com' }
  @source.handler.receive_record(@record)
end

Then('the record should be queued') do
  expect(@source.handler.has_records?).to be true
end

Then('I should be able to retrieve the record') do
  retrieved = @source.handler.next_record
  expect(retrieved).to eq(@record)
end

When('I send multiple records to the server') do
  @records = [
    { name: 'Alice', email: 'alice@example.com' },
    { name: 'Bob', email: 'bob@example.com' },
    { name: 'Charlie', email: 'charlie@example.com' }
  ]
  @source.handler.receive_records(@records)
end

Then('the records should be processed in batches') do
  collected = []
  @source.each(batch_size: 2) do |record|
    collected << record
    break if collected.size >= @records.size
  end
  
  expect(collected.size).to eq(@records.size)
  @source.stop_server
end

Then('the server URL should be {string}') do |expected_url|
  expect(@source.server_url).to eq(expected_url)
end

After do
  @source&.close
end
