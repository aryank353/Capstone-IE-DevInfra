terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_iam_user" "dev_user" {
  name = "capstone-dev-user"
  tags = {
    Project = "Capstone-Project-4"
  }
}

resource "aws_iam_user_policy_attachment" "dev_readonly" {
  user       = aws_iam_user.dev_user.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

output "iam_user_arn" {
  value = aws_iam_user.dev_user.arn
}
