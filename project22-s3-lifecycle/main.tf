provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_object" "log_archive" {
  bucket = "capstone-static-site-8ca2c17c"
  key    = "logs/app.log"
  source = "app.log"
}

resource "aws_s3_bucket_lifecycle_configuration" "log_lifecycle" {
  bucket = "capstone-static-site-8ca2c17c"

  rule {
    id     = "expire-logs-after-30-days"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    expiration {
      days = 30
    }
  }
}
