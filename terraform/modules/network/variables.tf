variable "name" {
  description = "Name prefix for network resources"
  type        = string
  default     = "laravel"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for the subnets"
  type        = string
  default     = "eu-north-1a"
}

variable "enable_nat_gateway" {
  description = "Whether to create a public NAT Gateway"
  type        = bool
  default     = true
}
