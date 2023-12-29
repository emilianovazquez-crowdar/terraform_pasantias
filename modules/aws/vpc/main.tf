locals {
  aws_region       = "us-east-2"
  environment_name = "test"
  tags             = {
    ops_env              = "${local.environment_name}"
    ops_managed_by       = "terraform",
    ops_source_repo_path = "environments/${local.environment_name}/ecs"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.37.0"
    }
  }
}

provider "aws" {
  region = local.aws_region
  profile = "sandbox"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ECS VPC"
  }
}

resource "aws_subnet" "my_public_subnet_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_cidr_block_public_1
  availability_zone       = "us-east-2a"  # Change to your desired availability zone

  tags = {
    Name = "Public Subnet A"
  }
}

resource "aws_subnet" "my_public_subnet_b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_cidr_block_public_2
  availability_zone       = "us-east-2b"  # Change to your desired availability zone

  tags = {
    Name = "Public Subnet B"
  }
}

resource "aws_subnet" "my_private_subnet_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_cidr_block_private_1
  availability_zone       = "us-east-2a"  # Change to your desired availability zone

  tags = {
    Name = "Private Subnet A"
  }
}

resource "aws_subnet" "my_private_subnet_b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_cidr_block_private_2
  availability_zone       = "us-east-2b"  # Change to your desired availability zone

  tags = {
    Name = "Private Subnet B"
  }
}

resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "ECS Internet Gateway"
  }
}

resource "aws_route_table" "my_public_route_table_1" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "Public RouteTable A"
  }
}

resource "aws_route_table" "my_public_route_table_2" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "Public RouteTable B"
  }
}

resource "aws_route_table" "my_private_route_table_1" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Private RouteTable A"
  }
}

resource "aws_route_table" "my_private_route_table_2" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Private RouteTable B"
  }
}

resource "aws_route" "private_route_1" {
  route_table_id         = aws_route_table.my_private_route_table_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.my_nat_gateway.id
}

resource "aws_route" "private_route_2" {
  route_table_id         = aws_route_table.my_private_route_table_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.my_nat_gateway.id
}

resource "aws_route_table_association" "my_public_subnet_association_1" {
  subnet_id      = aws_subnet.my_public_subnet_a.id
  route_table_id = aws_route_table.my_public_route_table_1.id
}

resource "aws_route_table_association" "my_public_subnet_association_2" {
  subnet_id      = aws_subnet.my_public_subnet_b.id
  route_table_id = aws_route_table.my_public_route_table_2.id
}

resource "aws_route_table_association" "my_private_subnet_association_1" {
  subnet_id      = aws_subnet.my_private_subnet_a.id
  route_table_id = aws_route_table.my_private_route_table_1.id
}

resource "aws_route_table_association" "my_private_subnet_association_2" {
  subnet_id      = aws_subnet.my_private_subnet_b.id
  route_table_id = aws_route_table.my_private_route_table_2.id
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.my_public_subnet_a.id
  depends_on    = [aws_internet_gateway.my_internet_gateway]
}

resource "aws_eip" "my_eip" {
  domain = "vpc"
}

resource "aws_security_group" "security_group" {
  vpc_id = aws_vpc.my_vpc.id

  name        = "MySecurityGroup"
  description = "Allow inbound and outbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allowed_ip]
  }
}

