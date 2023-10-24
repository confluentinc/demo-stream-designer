#!/bin/bash

# Source the .env file
source .env
sleep_time=5

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

# Deactive the pipeline and then delete
IFS=$'\n' read -d '' -r -a PIPELINE_ID < <(confluent pipeline list -o json | jq -r '.[] | select(.name | contains("demo-pipeline")) | .id')


for P_ID in "${PIPELINE_ID[@]}"
do
    confluent pipeline deactivate $P_ID
    sleep $sleep_time
    confluent pipeline delete $P_ID
done