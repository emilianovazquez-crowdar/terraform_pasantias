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

data terraform_remote_state "asg"{
  backend = "local"
  config = {
    path = "../asg/terraform.tfstate"
  }
}


resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = var.ecs_cluster_name
}

#resource "aws_iam_service_linked_role" "ecs" {
#  aws_service_name = "ecs.amazonaws.com"
#}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "test1"

 auto_scaling_group_provider {
   auto_scaling_group_arn = data.terraform_remote_state.asg.outputs.asg_arn

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 1
   }
 }

  #depends_on = [
  #  aws_iam_service_linked_role.ecs
  #]
}

resource "aws_ecs_cluster_capacity_providers" "example" {
 cluster_name = aws_ecs_cluster.my_ecs_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
 }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
 family             = "my-ecs-task"
 network_mode       = "awsvpc"
 execution_role_arn = "arn:aws:iam::403811705992:role/ecsTaskExecutionRole"
 cpu                = 256
 runtime_platform {
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
 }
 container_definitions = jsonencode([
   {
     name      = "test1"
     image     = "docker/getting-started:latest"
     cpu       = 256
     memory    = 512
     essential = true
     portMappings = [
       {
         containerPort = 80
         hostPort      = 80
         protocol      = "tcp"
       }
     ]
   }
 ])
}

resource "aws_ecs_service" "ecs_service" {
 name            = "my-ecs-service"
 cluster         = aws_ecs_cluster.my_ecs_cluster.id
 task_definition = aws_ecs_task_definition.ecs_task_definition.arn
 desired_count   = 2

 network_configuration {
   subnets         = [data.terraform_remote_state.vpc.outputs.subnet_id_a]
   security_groups = [data.terraform_remote_state.vpc.outputs.security_group_id]
 }

 force_new_deployment = true
 placement_constraints {
   type = "distinctInstance"
 }

 triggers = {
   redeployment = timestamp()
 }

 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
   weight            = 100
 }

 load_balancer {
   target_group_arn = data.terraform_remote_state.ec2.outputs.tg_arn
   container_name   = "test1"
   container_port   = 80
 }

 #depends_on = [data.terraform_remote_state.outputs.tg]
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.my_ecs_cluster.id
}
