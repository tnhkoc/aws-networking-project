variable "name" {
  type        = string
  description = "Name prefix for NACL resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block (e.g., 10.0.0.0/16)"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs to associate with the public NACL"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs to associate with the private NACL"
}

variable "app_port" {
  type        = number
  description = "Application port (target group / app listener port)"
}

variable "db_port" {
  type        = number
  description = "Database port for optional DB traffic"
  default     = 5432
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}