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
    Name = "ECS"
    Env = "Dev"
    Created = "Terraform"
  }
}

resource "aws_subnet" "my_subnet_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_cidr_blocka
  availability_zone       = "us-east-2a"  # Change to your desired availability zone

  tags = {
    Name = "Subnet A"
    Env = "Dev"
    Created = "Terraform"
  }
}

resource "aws_subnet" "my_subnet_b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_cidr_blockb
  availability_zone       = "us-east-2b"  # Change to your desired availability zone

  tags = {
    Name = "Subnet A"
    Env = "Dev"
    Created = "Terraform"
  }
}

resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyInternetGateway"
  }
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.my_subnet_a.id
  depends_on    = [aws_internet_gateway.my_internet_gateway]
}

resource "aws_eip" "my_eip" {
  domain = "vpc"
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my_nat_gateway.id
  }

  tags = {
    Name = "ECS"
    Env = "Dev"
    Created = "Terraform"
  }
}

resource "aws_route_table_association" "my_subnet_a_association" {
  subnet_id      = aws_subnet.my_subnet_a.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "my_subnet_b_association" {
  subnet_id      = aws_subnet.my_subnet_b.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "security_group" {
 name   = "ecs-security-group"
 vpc_id = aws_vpc.my_vpc.id

 ingress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
   description = "any"
 }

 egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}
