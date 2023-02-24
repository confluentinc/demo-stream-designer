variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "rds_instance_class" {
  description = "Amazon RDS (Microsoft SQL Server) instance size"
  type        = string
  default     = "db.m5.large"
}

variable "rds_instance_identifier" {
  description = "Amazon RDS (Microsoft SQL Server) instance identifier"
  type        = string
  default     = "demo-stream-designer"
}

variable "rds_username" {
  description = "Amazon RDS (Microsoft SQL Server) master username"
  type        = string
  default     = "admin"
}

variable "rds_password" {
  description = "Amazon RDS (Microsoft SQL Server) database password. You can change it through command line"
  type        = string
  default     = "db-sd-c0nflu3nt!"
}


variable "mongodbatlas_public_key" {
  description = "The public API key for MongoDB Atlas"
  type        = string
}

variable "mongodbatlas_private_key" {
  description = "The private API key for MongoDB Atlas"
  type        = string
}

variable "mongodbatlas_project_id" {
  description = "Project ID for MongoDB Atlas"
  type        = string
  default     = "63dc53eda8fab265979cafd9"
}

variable "mongodbatlas_region" {
  description = "MongoDB Atlas region https://www.mongodb.com/docs/atlas/reference/amazon-aws/#std-label-amazon-aws"
  type        = string
  default     = "US_WEST_2"
}

variable "mongodbatlas_database_username" {
  description = "MongoDB Atlas database username. You can change it through command line"
  type        = string
  default     = "admin"
}

variable "mongodbatlas_database_password" {
  description = "MongoDB Atlas database password. You can change it through command line"
  type        = string
  default     = "db-sd-c0nflu3nt!"
}