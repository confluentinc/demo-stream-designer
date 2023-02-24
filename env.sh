#!/bin/bash

# Source the .env file
source .env

# Use confluent environment
confluent login --save
export CCLOUD_ENV_ID=$(confluent environment list -o json \
    | jq -r '.[] | select(.name | contains('\"${CCLOUD_ENV_NAME:-Demo_Stream_Designer}\"')) | .id')

confluent env use $CCLOUD_ENV_ID

# Use kafka cluster
export CCLOUD_CLUSTER_ID=$(confluent kafka cluster list -o json \
    | jq -r '.[] | select(.name | contains('\"${CCLOUD_CLUSTER_NAME:-demo_kafka_cluster}\"')) | .id')

confluent kafka cluster use $CCLOUD_CLUSTER_ID

# Get cluster bootstrap endpoint
export CCLOUD_BOOTSTRAP_ENDPOINT=$(confluent kafka cluster describe -o json | jq -r .endpoint)
echo $CCLOUD_BOOTSTRAP_ENDPOINT

# Create a new pipeline for Stream Designer and grant permissions
echo "Creating a new pipeline in Stream Designer"
KSQL_CLUSTER_ID=$(confluent ksql cluster list -o json | jq -r '.[] | select(.name | contains("demo-ksql")) | .id')
# echo $KSQL_CLUSTER_ID

confluent pipeline create --name "demo-pipeline" \
    --description "Streaming data pipeline for a retail company." \
    --ksql-cluster ${KSQL_CLUSTER_ID}

PIPELINE_ID=$(confluent pipeline list -o json | jq -r '.[] | select(.name | contains("demo-pipeline")) | .id')
confluent pipeline update ${PIPELINE_ID} \
    --activation-privilege=true

# Create an API key pair to use for connectors
echo "Creating Kafka cluster API key"
confluent api-key create \
    --resource $CCLOUD_CLUSTER_ID \
    --description "demo-stream-designer"

# Get schema registry info
export CCLOUD_SCHEMA_REGISTRY_ID=$(confluent sr cluster describe -o json | jq -r .cluster_id)
export CCLOUD_SCHEMA_REGISTRY_ENDPOINT=$(confluent sr cluster describe -o json | jq -r .endpoint_url)

echo ""
echo "Creating schema registry API key"
confluent api-key create \
    --resource $CCLOUD_SCHEMA_REGISTRY_ID \
    --description "demo-stream-designer" \

echo ""
echo "Creating tags"
curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET \
--header 'Content-Type: application/json' \
--data '[ { "entityTypes" : [ "sr_schema", "sr_record", "sr_field", "sr_schema" ],"name" : "PII","description" : "Personally Identifiable Information"} ]' \
--url "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/tagdefs" | jq .

curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET \
--header 'Content-Type: application/json' \
--data '[ { "entityTypes" : [ "sr_schema", "sr_record", "sr_field", "sr_schema" ],"name" : "prod","description" : "Data for production environment."} ]' \
--url "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/tagdefs" | jq .


curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET \
--header 'Content-Type: application/json' \
--data '[ { "entityTypes" : [ "sr_schema", "sr_record", "sr_field", "sr_schema" ],"name" : "stag","description" : "Data for staging environment."} ]' \
--url "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/tagdefs" | jq .


curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET \
--header 'Content-Type: application/json' \
--data '[ { "entityTypes" : [ "sr_schema", "sr_record", "sr_field", "sr_schema" ],"name" : "dev","description" : "Data for development environment."} ]' \
--url "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/tagdefs" | jq .

echo ""
echo "Creating business metadata"
curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET  -X POST -H "Content-Type: application/json" \
--data @team.txt "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/businessmetadatadefs" | jq .
