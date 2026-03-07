resource "aws_ecs_service" "app_service" {
  name            = "loyaltri-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

network_configuration {
  subnets = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  security_groups = [aws_security_group.ecs_sg.id]

  assign_public_ip = false
}

  load_balancer {
  target_group_arn = aws_lb_target_group.app_tg.arn
  container_name   = "nginx"
  container_port   = 80
}
}