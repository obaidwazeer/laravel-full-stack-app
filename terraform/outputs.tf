output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "web_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "web_private_ip" {
  description = "Private IP of the web server"
  value       = aws_instance.web.private_ip
}

output "database_private_ip" {
  description = "Private IP of the database server"
  value       = aws_instance.db.private_ip
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.network.nat_gateway_id
}
