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

data terraform_remote_state "vpc"{  
    backend = "local"
    config = {
        path = "../vpc/terraform.tfstate"
    }
}

resource "aws_launch_template" "ecs_lt" {
 name_prefix   = "ecs-template"
 image_id      = "ami-0b59bfac6be064b78"
 instance_type = "t3.micro"

 key_name               = "ec2ecsglog"
 vpc_security_group_ids = [data.terraform_remote_state.vpc.outputs.security_group_id]
 iam_instance_profile {
   name = "ecsInstanceRole"
 }

 block_device_mappings {
   device_name = "/dev/xvda"
   ebs {
     volume_size = 30
     volume_type = "gp2"
   }
 }

 tag_specifications {
   resource_type = "instance"
   tags = {
     Name = "ecs-instance"
   }
 }

 user_data = filebase64("${path.module}/ecs.sh")
}

resource "aws_lb" "ecs_alb" {
 name               = "ecs-alb"
 internal           = false
 load_balancer_type = "application"
 security_groups    = [data.terraform_remote_state.vpc.outputs.security_group_id]
 subnets            = [data.terraform_remote_state.vpc.outputs.subnet_id_a, data.terraform_remote_state.vpc.outputs.subnet_id_b]

 tags = {
   Name = "ecs-alb"
    Env = "Dev"
    Created = "Terraform"
 }
}

resource "aws_lb_listener" "ecs_alb_listener" {
 load_balancer_arn = aws_lb.ecs_alb.arn
 port              = 80
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.ecs_tg.arn
 }
}

resource "aws_lb_target_group" "ecs_tg" {
 name        = "ecs-target-group"
 port        = 80
 protocol    = "HTTP"
 target_type = "ip"
 vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

 health_check {
   path = "/"
 }
}