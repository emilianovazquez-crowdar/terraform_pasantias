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


data terraform_remote_state "ec2"{  
    backend = "local"
    config = {
        path = "../ec2/terraform.tfstate"
    }
}

resource "aws_autoscaling_group" "ecs_asg" {
 vpc_zone_identifier = [data.terraform_remote_state.vpc.outputs.subnet_id_a]
 desired_capacity    = 1
 max_size            = 1
 min_size            = 1

 launch_template {
   id      = data.terraform_remote_state.ec2.outputs.ecs_lt_id
   version = "$Latest"
 }

 tag {
   key                 = "AmazonECSManaged"
   value               = true
   propagate_at_launch = true
 }
}