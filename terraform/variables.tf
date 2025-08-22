variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.small"
}

variable "db_username" {
  description = "Database username"
}

variable "db_password" {
  description = "Database password"
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  default = 5432
}

variable "db_name" {
  description = "Database name"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for Label Studio"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"
}

variable "labelstudio_username" {
  description = "LabelStudio Admin Username"
}

variable "labelstudio_password" {
  description = "LabelStudio Admin password"
  sensitive   = true
}

variable "labelstudio_token" {
  description = "LabelStudio User Token"
  sensitive   = true
}
