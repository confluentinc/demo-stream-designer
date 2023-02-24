output "sql_endpoint" {
  value = aws_db_instance.demo-stream-designer
  sensitive = true
}

output "mongodbatlas_connection_string" {
  description = "Connection string for MongoDB Atlas database to be used in Confluent Cloud connector"
  value       = mongodbatlas_cluster.demo-stream-designer.connection_strings[0].standard_srv
}

output "kafka_cluster_bootsrap_endpoint"{
    description = "The bootstrap endpoint used by Kafka clients to connect to the Kafka cluster."
    value = confluent_kafka_cluster.basic.bootstrap_endpoint
}

output "schema_registry_rest_endpoint" {
  description = "The HTTP endpoint of the Schema Registry cluster."
  value = confluent_schema_registry_cluster.advanced.rest_endpoint
}