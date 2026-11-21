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

data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "capstone-p9-ssm-role"
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
  name = "capstone-p9-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_security_group" "p9_sg" {
  name        = "capstone-p9-egress-only-sg"
  description = "Egress only - zero RDP/SSH ports"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dc" {
  ami                    = data.aws_ami.windows_2022.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.p9_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  tags = {
    Name    = "Capstone-Project-9-DC"
    Project = "Capstone-Project-9"
  }
}

output "instance_id" {
  value = aws_instance.dc.id
}
