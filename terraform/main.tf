# --------------------------------------------------
# 1. Reusable Network Module
# --------------------------------------------------

module "network" {
  source = "./modules/network"

  name                = "laravel"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  availability_zone   = "eu-north-1a"

  enable_nat_gateway = true
}


# --------------------------------------------------
# 2. Find the Latest Ubuntu 24.04 AMI
# --------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


# --------------------------------------------------
# 3. Web Server Security Group
# --------------------------------------------------

resource "aws_security_group" "web_sg" {
  name        = "laravel-web-sg"
  description = "Security group for the Laravel web server"
  vpc_id      = module.network.vpc_id

  # Allow HTTP traffic
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH only from your trusted public IP
  ingress {
    description = "SSH from administrator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # cidr_blocks = [var.admin_cidr]
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound connections
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "laravel-web-sg"
  }
}


# --------------------------------------------------
# 4. Database Security Group
# --------------------------------------------------

resource "aws_security_group" "db_sg" {
  name        = "laravel-db-sg"
  description = "Security group for the MySQL database"
  vpc_id      = module.network.vpc_id

  # Allow MySQL only from the web server security group
  ingress {
    description     = "MySQL from Laravel web server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # Allow outbound connections when required
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "laravel-db-sg"
  }
}


# --------------------------------------------------
# 5. Web Server EC2 Instance
# --------------------------------------------------

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.web_instance_type
  subnet_id                   = module.network.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "laravel-web-server"
  }
}


# --------------------------------------------------
# 6. Database EC2 Instance
# --------------------------------------------------

resource "aws_instance" "db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.db_instance_type
  subnet_id              = module.network.private_subnet_id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  # Install MySQL and permit remote connections.
  # Network access is still restricted by db_sg.
  user_data = <<-EOF
    #!/bin/bash
    set -e

    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y mysql-server

    sed -i 's/^bind-address[[:space:]]*=.*/bind-address = 0.0.0.0/' \
      /etc/mysql/mysql.conf.d/mysqld.cnf

    systemctl enable mysql
    systemctl restart mysql
  EOF

  tags = {
    Name = "laravel-mysql-server"
  }
}
