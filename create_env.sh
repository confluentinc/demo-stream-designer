#!/bin/bash

accounts_file=".accounts"
env_file=".env"

# Check if .accounts file exists
if [ ! -f "$accounts_file" ]; then
    echo "$accounts_file not found."
    exit 1
fi

# Define the environment variable content
env_content=$(cat <<EOF
CCLOUD_API_KEY=api-key
CCLOUD_API_SECRET=api-secret
CCLOUD_BOOTSTRAP_ENDPOINT=kafka-cluster-endpoint

CCLOUD_SCHEMA_REGISTRY_API_KEY=sr-key
CCLOUD_SCHEMA_REGISTRY_API_SECRET=sr-secret
CCLOUD_SCHEMA_REGISTRY_URL=sr-cluster-endpoint


SQL_USERNAME=admin
SQL_PASSWORD=db-sd-c0nflu3nt!
SQL_SERVER=sql-server
SQL_PORT=1433

MONGO_USERNAME=admin
MONGO_PASSWORD=db-sd-c0nflu3nt!
MONGO_ENDPOINT=mongodb-endpoint
MONGO_DATABASE_NAME=demo-stream-designer
EOF
)

# Combine the environment variable content with .accounts and write to .env
echo "$env_content" | cat - "$accounts_file" > "$env_file"

echo "Created an environment file named: $env_file"
