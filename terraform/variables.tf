variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

# variable "admin_cidr" {
#   description = "Your trusted public IP in CIDR notation for SSH access"
#   type        = string

#   validation {
#     condition     = can(cidrhost(var.admin_cidr, 0))
#     error_message = "admin_cidr must be a valid CIDR block, such as 203.0.113.10/32."
#   }
# }

variable "web_instance_type" {
  description = "EC2 instance type for the web server"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "EC2 instance type for the database server"
  type        = string
  default     = "t3.micro"
}
