variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "app_port" {
  type        = number
  description = "Target group port for the application"
  default     = 80
}
