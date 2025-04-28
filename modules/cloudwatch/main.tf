resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "${var.name_prefix}-vpc-flow-logs"
  retention_in_days = var.retention_in_days
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "${var.name_prefix}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination_type = "cloud-watch-logs"
  log_destination       = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
  vpc_id               = var.vpc_id
  traffic_type         = "ALL" # capture accepted and rejected traffic
}


resource "aws_cloudwatch_log_stream" "instance" {
  name           = "${var.name_prefix}-vpc-log-stream"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
}

resource "aws_sns_topic" "alarms" {
  name = "${var.name_prefix}-vpc-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_ssm_document" "cloudwatch_agent_install" {
  name          = "CloudWatchAgentInstall"
  document_type = "Command"
  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Install CloudWatch Agent",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "installCloudWatchAgent",
        inputs = {
          runCommand = [
  # Download the CloudWatch Agent .deb package for Ubuntu
  # Make sure wget is installed: 
  "sudo apt-get update && sudo apt-get install -y wget",
  "wget https://s3.${var.aws_region}.amazonaws.com/amazoncloudwatch-agent-${var.aws_region}/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb",

  # Install the package
  "sudo dpkg -i -E /tmp/amazon-cloudwatch-agent.deb",

  # Fetch the configuration from SSM Parameter Store and start the agent
  # Assumes your config is stored in Parameter Store under the name 'AmazonCloudWatch-linux'
  # The '-s' flag starts the agent after fetching the config.
  "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:AmazonCloudWatch-linux -s",

  # (Optional but recommended) Enable the agent service to start on boot
  "sudo systemctl enable amazon-cloudwatch-agent"
]
        }
      }
    ]
  })
}

resource "aws_ssm_association" "cloudwatch_agent_run" {
  name = aws_ssm_document.cloudwatch_agent_install.name

  targets  {
      key    = "InstanceIds"
      values = [var.instance_id]
    }
  
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name        = "AmazonCloudWatch-linux"
  description = "CloudWatch Agent Config for Ubuntu instances"
  type        = "String"
  tier        = "Standard"
  value       = file("${path.module}/cloudwatch-agent-config.json")
}


