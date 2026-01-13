variable "name" {
  type        = string
  description = "Name prefix for resources"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones (e.g., [\"eu-central-1a\", \"eu-central-1b\"])"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for public subnets (same length as azs)"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for private subnets (same length as azs)"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}