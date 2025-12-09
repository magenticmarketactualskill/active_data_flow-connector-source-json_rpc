Feature: JSON-RPC Source Connector
  As a developer using ActiveDataFlow
  I want to receive data via JSON-RPC
  So that I can integrate external systems as data sources

  Scenario: Start and stop JSON-RPC server
    Given a JSON-RPC source connector
    When I start the server
    Then the server should be running
    When I stop the server
    Then the server should not be running

  Scenario: Receive records via JSON-RPC
    Given a JSON-RPC source connector
    And the server is started
    When I send a record to the server
    Then the record should be queued
    And I should be able to retrieve the record

  Scenario: Process records in batches
    Given a JSON-RPC source connector
    And the server is started
    When I send multiple records to the server
    Then the records should be processed in batches

  Scenario: Get server URL
    Given a JSON-RPC source connector on port 9999
    Then the server URL should be "http://0.0.0.0:9999"
