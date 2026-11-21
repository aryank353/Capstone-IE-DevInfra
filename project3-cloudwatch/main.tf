provider "aws" {
  region = "eu-west-1"
}

data "aws_instance" "web" {
  filter {
    name   = "tag:Name"
    values = ["capstone-web-server"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "capstone-ec2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Triggers when EC2 CPU exceeds 50%"

  dimensions = {
    InstanceId = data.aws_instance.web.id
  }
}
