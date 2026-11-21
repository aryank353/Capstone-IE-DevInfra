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

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "capstone-p10-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "capstone-p10-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_security_group" "p10_sg" {
  name        = "capstone-p10-egress-only-sg"
  description = "Egress only - zero inbound ports"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dns_client" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.p10_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  tags = {
    Name    = "Capstone-Project-10-DNS-Client"
    Project = "Capstone-Project-10"
  }
}

resource "aws_route53_zone" "private" {
  name = "capstone.internal"

  vpc {
    vpc_id = data.aws_vpc.default.id
  }
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "app.capstone.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.dns_client.private_ip]
}

output "instance_id" {
  value = aws_instance.dns_client.id
}

output "expected_private_ip" {
  value = aws_instance.dns_client.private_ip
}
