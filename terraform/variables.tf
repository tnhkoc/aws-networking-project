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