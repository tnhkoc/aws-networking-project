variable "name" {
  description = "Base name prefix for security groups"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "app_port" {
  description = "Application listening port (behind ALB)"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Database port (placeholder)"
  type        = number
  default     = 5432
}

variable "admin_cidr_blocks" {
  description = "CIDRs allowed to access bastion via SSH (e.g. your public IP /32)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}