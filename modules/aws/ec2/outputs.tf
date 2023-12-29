output "ecs_lt_id" {
  value = aws_launch_template.ecs_lt.id
}

output "tg_arn" {
  value = aws_lb_target_group.ecs_tg.arn
}

output "tg"{
  value = aws_lb_target_group.ecs_tg
}