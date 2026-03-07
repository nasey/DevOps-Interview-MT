resource "aws_ecs_task_definition" "app" {
  family                   = "loyaltri-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([

    {
      name  = "rails_app"
      image = "993409157137.dkr.ecr.ap-south-1.amazonaws.com/rails_app:latest"

      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]

      environment = [
        { name = "RDS_DB_NAME", value = "rails" },
        { name = "RDS_USERNAME", value = "postgres" },
        { name = "RDS_PASSWORD", value = random_password.db_password.result },
        { name = "RDS_HOSTNAME", value = aws_db_instance.postgres.address },
        { name = "RDS_PORT", value = "5432" },
        { name = "S3_BUCKET_NAME", value = aws_s3_bucket.app_bucket.bucket },
        { name = "S3_REGION_NAME", value = "ap-south-1" },
        { name = "LB_ENDPOINT", value = aws_lb.app_alb.dns_name }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "rails"
        }
      }
    },

    {
      name  = "nginx"
      image = "993409157137.dkr.ecr.ap-south-1.amazonaws.com/webserver:latest"

      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      dependsOn = [
        {
          containerName = "rails_app"
          condition     = "START"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "nginx"
        }
      }
    }

  ])
}