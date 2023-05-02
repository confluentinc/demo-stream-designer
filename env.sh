#!/bin/bash

# Source the .env file
source .env
sleep_time=2

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
STRIPPED_CCLOUD_BOOTSTRAP_ENDPOINT=$(echo $CCLOUD_BOOTSTRAP_ENDPOINT | sed 's/SASL_SSL:\/\///')

# use sed to replace kafka-cluster-endpoint with the replacement string
sed -i .bak "s/kafka-cluster-endpoint/$STRIPPED_CCLOUD_BOOTSTRAP_ENDPOINT/g" .env
sleep $sleep_time

# Create a new pipeline for Stream Designer and grant permissions
echo "Creating a new pipeline in Stream Designer"
KSQL_CLUSTER_ID=$(confluent ksql cluster list -o json | jq -r '.[] | select(.name | contains("demo-ksql")) | .id')
# echo $KSQL_CLUSTER_ID

confluent pipeline create --name "demo-pipeline" \
    --description "Streaming data pipeline for a retail company." \
    --ksql-cluster ${KSQL_CLUSTER_ID}

sleep $sleep_time

PIPELINE_ID=$(confluent pipeline list -o json | jq -r '.[] | select(.name | contains("demo-pipeline")) | .id')
confluent pipeline update ${PIPELINE_ID} \
    --activation-privilege=true

sleep $sleep_time

# Create an API key pair to use for connectors
echo "Creating Kafka cluster API key"
CREDENTIALS=$(confluent api-key create --resource $CCLOUD_CLUSTER_ID --description "demo-stream-designer" -o json)
kafka_api_key=$(echo $CREDENTIALS | jq -r '.api_key')
kafka_api_secret=$(echo $CREDENTIALS | jq -r '.api_secret')
sleep $sleep_time

# # print the values
# echo "API key: $kafka_api_key"
# echo "API secret: $kafka_api_secret"

# use sed to replace all instances of $kafka_api_key with the replacement string
sed -i .bak "s^api-key^\"$kafka_api_key\"^g" .env 
sed -i .bak "s^api-secret^\"$kafka_api_secret\"^g" .env 


# Get schema registry info
export CCLOUD_SCHEMA_REGISTRY_ID=$(confluent sr cluster describe -o json | jq -r .cluster_id)
export CCLOUD_SCHEMA_REGISTRY_ENDPOINT=$(confluent sr cluster describe -o json | jq -r .endpoint_url)

echo ""
echo "Creating schema registry API key"
SR_CREDENTIALS=$(confluent api-key create --resource $CCLOUD_SCHEMA_REGISTRY_ID --description "demo-stream-designer" -o json)
sr_api_key=$(echo $SR_CREDENTIALS | jq -r '.api_key')
sr_api_secret=$(echo $SR_CREDENTIALS | jq -r '.api_secret')
sleep $sleep_time

# # print the values
# echo "API key: $sr_api_key"
# echo "API secret: $sr_api_secret"

# use sed to replace all instances of $sr_api_key and $sr_api_secret with the replacement string
sed -i .bak "s^sr-key^\"$sr_api_key\"^g" .env 
sed -i .bak "s^sr-secret^\"$sr_api_secret\"^g" .env
sed -i .bak "s^sr-cluster-endpoint^$CCLOUD_SCHEMA_REGISTRY_ENDPOINT^g" .env
sleep $sleep_time

# source the .env file
source .env
sleep $sleep_time

echo ""
echo "Creating tags"
curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET \
--header 'Content-Type: application/json' \
--data '[ { "entityTypes" : [ "cf_entity" ],"name" : "PII","description" : "Personally Identifiable Information"} ]' \
--url "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/tagdefs" | jq .

curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET \
--header 'Content-Type: application/json' \
--data '[ { "entityTypes" : [ "cf_entity" ],"name" : "prod","description" : "Data for production environment."} ]' \
--url "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/tagdefs" | jq .


curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET \
--header 'Content-Type: application/json' \
--data '[ { "entityTypes" : [ "cf_entity" ],"name" : "stag","description" : "Data for staging environment."} ]' \
--url "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/tagdefs" | jq .


curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET \
--header 'Content-Type: application/json' \
--data '[ { "entityTypes" : [ "cf_entity" ],"name" : "dev","description" : "Data for development environment."} ]' \
--url "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/tagdefs" | jq .

echo ""
echo "Creating business metadata"
curl -u $CCLOUD_SCHEMA_REGISTRY_API_KEY:$CCLOUD_SCHEMA_REGISTRY_API_SECRET  -X POST -H "Content-Type: application/json" \
--data @team.txt "{$CCLOUD_SCHEMA_REGISTRY_URL}/catalog/v1/types/businessmetadatadefs" | jq .

# Read values from resources.json and update the .env file.
# These resources are created by Terraform
json=$(cat resources.json)

sql_server=$(echo "$json" | jq -r '.sql_endpoint.value.address')
mongodbatlas_connection_string=$(echo "$json" | jq -r '.mongodbatlas_connection_string.value'| sed 's/mongodb+srv:\/\///')
sr_endpoint=$(echo "$json" | jq -r '.schema_registry_rest_endpoint.value')

# Updating the .env file with sed command
sed -i .bak "s^sql-server^$sql_server^g" .env 
sed -i .bak "s^mongodb-endpoint^$mongodbatlas_connection_string^g" .env 
sed -i .bak "s^sr-cluster-endpoint^$sr_endpoint^g" .env 

sleep $sleep_time

#source the .env file 
echo "Sourcing the .env file"
source .env