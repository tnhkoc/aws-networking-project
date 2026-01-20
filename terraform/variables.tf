variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources into"
  default     = "eu-central-1"
}

variable "project" {
  type        = string
  description = "Project name for tagging/naming"
  default     = "aws-networking-project"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "app_port" {
  type        = number
  description = "Application port"
  default     = 80
}

variable "db_port" {
  type        = number
  description = "Database port"
  default     = 5432
}