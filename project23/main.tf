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

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_iam_role" "ec2_s3_role" {
  name = "capstone-ec2-s3-readonly-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_readonly" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "capstone-ec2-s3-profile"
  role = aws_iam_role.ec2_s3_role.name
}

resource "aws_key_pair" "p23_key" {
  key_name   = "capstone-p23-key"
  public_key = file("${path.module}/project23-key.pub")
}

resource "aws_security_group" "p23_ssh" {
  name        = "capstone-p23-ssh-sg"
  description = "Allow SSH for Project 23 verification"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "s3_test_ec2" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.p23_key.key_name
  vpc_security_group_ids = [aws_security_group.p23_ssh.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3_profile.name

  tags = {
    Name    = "Capstone-Project-23-EC2"
    Project = "Capstone-Project-23"
  }
}

output "ec2_public_ip" {
  value = aws_instance.s3_test_ec2.public_ip
}
