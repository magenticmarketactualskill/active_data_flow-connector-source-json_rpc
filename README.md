# ActiveDataFlow JSON-RPC Source Connector

A source connector for ActiveDataFlow that receives data via JSON-RPC server. This connector implements a Jimson server that accepts incoming RPC calls and provides the received data as a source for data flows.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_dataflow-connector-source-json_rpc'
```

And then execute:

```bash
bundle install
```

## Features

The JSON-RPC source connector provides a server that receives data via JSON-RPC calls and makes it available to ActiveDataFlow pipelines. Key features include:

- **Automatic Server Management**: Starts and stops the JSON-RPC server automatically
- **Queue-Based Buffering**: Buffers incoming records in a thread-safe queue
- **Batch Processing**: Processes records in configurable batch sizes
- **Custom Handlers**: Support for custom RPC handler classes
- **Health Monitoring**: Built-in health check and queue monitoring

## Usage

### Basic Usage

```ruby
require 'active_data_flow-connector-source-json_rpc'

# Create a JSON-RPC source
source = ActiveDataFlow::Connector::Source::JsonRpcSource.new(
  host: '0.0.0.0',
  port: 8999
)

# Start the server
source.start_server

# Process incoming records
source.each(batch_size: 100) do |record|
  puts "Received: #{record}"
end

# Clean up
source.close
```

### In a Data Flow

```ruby
# Create the source
source = ActiveDataFlow::Connector::Source::JsonRpcSource.new(
  host: '0.0.0.0',
  port: 8999
)

# Create a sink (e.g., ActiveRecord)
sink = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
  model_class: User,
  batch_size: 100
)

# Create the data flow
runtime = ActiveDataFlow::Runtime::Heartbeat.new(interval: 60)

ActiveDataFlow::DataFlow.create!(
  name: "json_rpc_to_database",
  source: source,
  sink: sink,
  runtime: runtime
)
```

### Sending Data to the Source

From any JSON-RPC client:

```ruby
require 'jimson'

client = Jimson::Client.new("http://localhost:8999")

# Send a single record
client.receive_record({ name: 'John Doe', email: 'john@example.com' })

# Send multiple records
records = [
  { name: 'Alice', email: 'alice@example.com' },
  { name: 'Bob', email: 'bob@example.com' }
]
client.receive_records(records)

# Check server health
health = client.health
puts health # => { status: 'ok', queue_size: 2, timestamp: '...' }
```

### Custom Handler

You can provide a custom handler class for specialized RPC methods:

```ruby
class MyCustomHandler < ActiveDataFlow::Connector::JsonRpc::ServerHandler
  # Add custom RPC methods
  def process_user(user_data)
    # Transform data before queuing
    transformed = transform_user(user_data)
    @queue.push(transformed)
    { status: 'success', message: 'User processed' }
  end
  
  private
  
  def transform_user(data)
    # Your transformation logic
    data.merge(processed_at: Time.now.iso8601)
  end
end

# Use custom handler
source = ActiveDataFlow::Connector::Source::JsonRpcSource.new(
  host: '0.0.0.0',
  port: 8999,
  handler_class: MyCustomHandler
)
```

## Configuration Options

### Initialization Parameters

- **host** (String): The host to bind the server to (default: `'0.0.0.0'`)
- **port** (Integer): The port to bind the server to (default: `8999`)
- **handler_class** (Class): Custom handler class (default: `ActiveDataFlow::Connector::JsonRpc::ServerHandler`)

### Processing Parameters

- **batch_size** (Integer): Number of records to process per batch in `each` method
- **start_id** (Integer): Not used for JSON-RPC sources (included for interface compatibility)

## API Reference

### Instance Methods

#### `#start_server`
Starts the JSON-RPC server in a background thread.

#### `#stop_server`
Stops the JSON-RPC server and terminates the background thread.

#### `#running?`
Returns `true` if the server is currently running.

#### `#each(batch_size:, start_id: nil, &block)`
Iterates through received records in batches. Automatically starts the server if not running.

#### `#close`
Stops the server and cleans up resources.

#### `#server_url`
Returns the full server URL (e.g., `"http://0.0.0.0:8999"`).

#### `#queue_size`
Returns the current number of queued records.

### JSON-RPC Endpoints

The server exposes the following RPC methods:

- `receive_record(record)` - Receive a single record
- `receive_records(records)` - Receive multiple records
- `health` - Get server health status

## Architecture

The JSON-RPC source connector operates as follows:

1. **Server Initialization**: Creates a Jimson server with a handler that manages an internal queue
2. **Record Reception**: Incoming RPC calls add records to the thread-safe queue
3. **Batch Processing**: The `each` method pulls records from the queue in batches
4. **Data Flow Integration**: Records are passed to the data flow pipeline for processing

This architecture allows the source to receive data asynchronously while providing synchronous batch processing to the data flow.

## Thread Safety

The connector uses a thread-safe `Queue` for buffering records between the RPC server thread and the data flow processing thread. This ensures that records are not lost or corrupted during concurrent access.

## Error Handling

The connector includes error handling for common scenarios such as server startup failures and connection issues. Errors are logged to Rails logger if available, or printed to stdout otherwise.

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
bundle exec rspec
```

To run Cucumber tests:

```bash
bundle exec cucumber
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magenticmarketactualskill/active_dataflow-connector-source-json_rpc.

## License

The gem is available as open source under the terms of the MIT License.
