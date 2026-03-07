resource "aws_ecs_cluster" "main" {
  name = "loyaltri-ecs-cluster"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/loyaltri-app"
  retention_in_days = 7
}