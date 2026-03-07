resource "aws_s3_bucket" "app_bucket" {
  bucket = "loyaltri-app-bucket"

  tags = {
    Name = "loyaltri-app-bucket"
  }
}