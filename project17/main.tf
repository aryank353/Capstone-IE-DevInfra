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

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/capstone/project17/app-logs"
  retention_in_days = 7
}

resource "aws_iam_role" "cw_agent_role" {
  name = "capstone-p17-cw-agent-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw_agent_policy" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cw_agent_profile" {
  name = "capstone-p17-cw-agent-profile"
  role = aws_iam_role.cw_agent_role.name
}

resource "aws_security_group" "p17_sg" {
  name        = "capstone-p17-egress-only-sg"
  description = "Egress only - zero inbound ports"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "log_source" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.p17_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.cw_agent_profile.name

  user_data = <<-USERDATA
    #!/bin/bash
    dnf install -y amazon-cloudwatch-agent

    cat << 'LOG' > /var/log/capstone-app.log
    [INFO] Capstone Project 17 application started
    [INFO] Connected to eu-west-1 logging pipeline
    [SUCCESS] CloudWatch Agent log shipping verified
    LOG

    cat << 'CWCONFIG' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/capstone-app.log",
                "log_group_name": "/capstone/project17/app-logs",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      }
    }
    CWCONFIG

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  USERDATA

  tags = {
    Name    = "Capstone-Project-17-Logger"
    Project = "Capstone-Project-17"
  }
}

output "instance_id" {
  value = aws_instance.log_source.id
}
