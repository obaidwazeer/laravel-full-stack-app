# --------------------------------------------------
# 1. Read the existing Secrets Manager secret metadata
# --------------------------------------------------

data "aws_secretsmanager_secret" "laravel_database" {
  name = "prod/laravel/database-bootstrap"
}


# --------------------------------------------------
# 2. Web EC2 IAM role
# --------------------------------------------------

resource "aws_iam_role" "web_role" {
  name = "laravel-web-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "web_secret_access" {
  name = "laravel-web-database-secret"
  role = aws_iam_role.web_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "secretsmanager:GetSecretValue"
      ]

      Resource = data.aws_secretsmanager_secret.laravel_database.arn
    }]
  })
}

resource "aws_iam_instance_profile" "web" {
  name = "laravel-web-instance-profile"
  role = aws_iam_role.web_role.name
}


# --------------------------------------------------
# 3. Database EC2 IAM role
# --------------------------------------------------

resource "aws_iam_role" "db_role" {
  name = "laravel-db-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "db_secret_access" {
  name = "laravel-db-database-secret"
  role = aws_iam_role.db_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "secretsmanager:GetSecretValue"
      ]

      Resource = data.aws_secretsmanager_secret.laravel_database.arn
    }]
  })
}

resource "aws_iam_instance_profile" "db" {
  name = "laravel-db-instance-profile"
  role = aws_iam_role.db_role.name
}

# --------------------------------------------------
#  AWS key pair for EC2 instances
# --------------------------------------------------

resource "aws_key_pair" "deployer" {
    key_name = var.key_name
    public_key = var.ssh_public_key
}

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
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # Attach IAM role to the web EC2.
  iam_instance_profile = aws_iam_instance_profile.web.name

  # Install and configure web server software on first boot.
  user_data = file("${path.module}/bootstrap/web-user-data.sh")

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Wait until network and IAM permissions exist.
  depends_on = [
    module.network,
    aws_iam_role_policy.web_secret_access
  ]

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
  key_name               = aws_key_pair.deployer.key_name

  # Attach IAM role to the database EC2.
  iam_instance_profile = aws_iam_instance_profile.db.name

  # Bootstrap MySQL and create application database/users.
  user_data = templatefile(
    "${path.module}/bootstrap/db-user-data.sh.tftpl",
    {
      aws_region           = "eu-north-1"
      database_secret_name = data.aws_secretsmanager_secret.laravel_database.name
      mysql_user_host      = "10.0.1.%"
    }
  )

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Ensure the NAT route and database secret permissions exist
  # before launching the private database instance.
  depends_on = [
    module.network,
    aws_iam_role_policy.db_secret_access
  ]

  tags = {
    Name = "laravel-mysql-server"
  }
}
