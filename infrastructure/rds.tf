resource "aws_db_subnet_group" "db_subnet_group" {
  name = "loyaltri-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name = "loyaltri-db-subnet-group"
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "postgres" {
  identifier = "loyaltri-postgres-db"

  engine         = "postgres"
  engine_version = "14"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "rails"
  username = "postgres"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "loyaltri-postgres"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "rds_password" {
  value     = random_password.db_password.result
  sensitive = true
}