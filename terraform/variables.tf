variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}


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

variable "key_name" {
    description = "Access key name for AWS EC2"
    type = string
    default = "ec2_access_key"
}

variable "ssh_public_key" {

}

# variable "bucket_name" {
#     description = "Bucket name for Terraform state file"
#     type = string
# }

# variable "bucket_key" {
#     description = "Terraform state file along with full directory"
#     type = string
# }
