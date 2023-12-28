# ecs/variables.tf

variable "ecs_cluster_name" {
  default = "MyECSCluster"
}

variable "ecs_service1_task_definition" {
  default = "YourTaskDefinitionArn1"
}

variable "ecs_service2_task_definition" {
  default = "YourTaskDefinitionArn2"
}

variable "ecs_service1_security_group" {
  default = "YourSecurityGroupId1"
}

variable "ecs_service2_security_group" {
  default = "YourSecurityGroupId2"
}
