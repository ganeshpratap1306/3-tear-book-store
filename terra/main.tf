provider "aws" {
  region = var.region
}

# ---------------- VPC ----------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

# ---------------- IGW ----------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------- SECURITY GROUPS ----------------
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
}

# ---------------- EC2 INSTANCES ----------------

# Web Tier (Docker run)
resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = var.key_name
  security_groups = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install docker.io -y
              systemctl start docker
              docker run -d -p 80:80 ${var.web_image}
              EOF

  tags = {
    Name = "Web-Tier"
  }
}

# App Tier (Docker Compose)
resource "aws_instance" "app" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = var.key_name
  security_groups = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install docker.io docker-compose -y
              systemctl start docker

              git clone ${var.app_repo} /app
              cd /app

              docker-compose up -d
              EOF

  tags = {
    Name = "App-Tier"
  }
}

# DB Tier (Postgres container)
resource "aws_docdb_subnet_group" "docdb_subnet" {
  name       = "docdb-subnet-group"
  subnet_ids = [aws_subnet.private.id]

  tags = {
    Name = "DocDB Subnet Group"
  }
}

resource "aws_docdb_cluster" "mongo" {
  cluster_identifier      = "docdb-cluster"
  engine                  = "docdb"
  master_username         = "mongo"
  master_password         = "StrongPassword123"

  db_subnet_group_name    = aws_docdb_subnet_group.docdb_subnet.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]

  skip_final_snapshot     = true
}

resource "aws_docdb_cluster_instance" "mongo_instance" {
  identifier         = "docdb-instance-1"
  cluster_identifier = aws_docdb_cluster.mongo.id
  instance_class     = "db.t3.medium"
}