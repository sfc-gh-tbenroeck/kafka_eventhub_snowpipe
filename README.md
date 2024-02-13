# Kafka Connect with Azure Event Hubs and Snowflake Snowpipe Streaming

## Overview

This repository contains the source code and configuration necessary to run Kafka Connect, facilitating the connection between Azure Event Hubs and Snowflake using the [Snowpipe Streaming](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-streaming-kafka). It leverages an Azure Managed Service Identity (MSI) for authentication to Event Hubs and dynamically generates configuration files using `envsubst`.

### Azure Event Hubs

To connect to Azure Event Hubs using an MSI a CustomAuthenticateCallbackHandler class is required.  This repo includes `azure_msi_oauth-1.0-SNAPSHOT.jar` which I compiled using the code from [Azure Event Hubs for Kafka](https://github.com/Azure/azure-event-hubs-for-kafka) GitHub repository.

### Snowflake Setup

 Following commands can  be executed in Snowflake to set up the required role and a user for the connector:

```sql
-- Create a Snowflake role with privileges
CREATE ROLE kafka_connector_role;

-- Grant privileges on the database
GRANT USAGE ON DATABASE STREAMINGDB TO ROLE kafka_connector_role;

-- Grant privileges on the schema
GRANT USAGE ON SCHEMA PUBLIC TO ROLE kafka_connector_role;
GRANT CREATE TABLE ON SCHEMA PUBLIC TO ROLE kafka_connector_role;
GRANT CREATE STAGE ON SCHEMA PUBLIC TO ROLE kafka_connector_role;
GRANT CREATE PIPE ON SCHEMA PUBLIC TO ROLE kafka_connector_role;

-- Create user for streaming (see below for how to create a public key)
CREATE OR REPLACE USER streaming_user RSA_PUBLIC_KEY='MIIBIjA______HIDDEN______2wIDAQAB' DEFAULT_ROLE=kafka_connector_role;

-- Grant role
GRANT ROLE kafka_connector_role TO USER streaming_user;

-- Setup table for messages (optional if not using an existing table)
CREATE OR REPLACE TABLE streaming_timestamp (
    timestamp TIMESTAMP_NTZ,
    message STRING
);

-- Grant ownership of the table to the role (if using an existing table)
GRANT OWNERSHIP ON TABLE streaming_timestamp TO ROLE kafka_connector_role;
```

### Generating User Certificate

Generate a private and public key pair for the Snowflake user:

```bash
# Create private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt

# Get private key value for configuration (adjust command for your OS)
cat rsa_key.p8 | grep -v 'PRIVATE KEY' | tr -d '\n' | pbcopy

# Create public key
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub

# Get public key value for Snowflake user creation (adjust command for your OS)
cat rsa_key.pub | grep -v 'PUBLIC KEY' | tr -d '\n' | pbcopy
```


### Building and Running the Connector

Update the environment variables in the `docker-compose.yml` file with your Eventhub and Snowflake information and run `docker compose build` then `docker compose up`
