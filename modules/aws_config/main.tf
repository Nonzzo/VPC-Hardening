# S3 bucket for Config snapshots
resource "aws_s3_bucket" "config_bucket" {
  bucket = "${var.name_prefix}-config-bucket-${data.aws_caller_identity.current.account_id}" # Added account ID for uniqueness

  lifecycle {
    prevent_destroy = true
  }
}

# Apply Block Public Access settings using the dedicated resource
resource "aws_s3_bucket_public_access_block" "config_bucket_pab" {
  bucket = aws_s3_bucket.config_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add bucket policy after PAB is set
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = data.aws_iam_policy_document.config_bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.config_bucket_pab]
}

# S3 Bucket versioning configuration
resource "aws_s3_bucket_versioning" "config_bucket_versioning" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket_sse" {
  bucket = aws_s3_bucket.config_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Get current AWS Account ID and Region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM policy document for Config S3 Bucket Policy
data "aws_iam_policy_document" "config_bucket_policy" {
  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.config_bucket.arn]
  }

  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.config_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}


# IAM role AWS Config uses
resource "aws_iam_role" "config_role" {
  name = "${var.name_prefix}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach the AWS managed policy for Config role
resource "aws_iam_role_policy_attachment" "config_role_policy" {
  role       = aws_iam_role.config_role.name
  # Use the AWS managed policy ARN for simplicity and correctness
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole" 
}


# AWS Config Recorder
resource "aws_config_configuration_recorder" "recorder" {
  name     = "${var.name_prefix}-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    # Recording global resources like IAM users requires the recorder to be in us-east-1
    # Set to false if running in other regions unless you specifically need global types
    include_global_resource_types = data.aws_region.current.name == "us-east-1" 
  }
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "delivery_channel" {
  name           = "${var.name_prefix}-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket

  # Ensure the recorder exists before creating the channel
  depends_on = [aws_config_configuration_recorder.recorder]
}

# Start the configuration recorder automatically
resource "aws_config_configuration_recorder_status" "recorder_status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true

  # Ensure the delivery channel is set up before enabling the recorder
  depends_on = [aws_config_delivery_channel.delivery_channel]
}

resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.recorder_status]
}

resource "aws_config_config_rule" "s3_bucket_encrypted" {
  name = "s3-bucket-server-side-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.recorder_status]
}

resource "aws_config_config_rule" "ec2_no_public_ip" {
  name = "ec2-instance-no-public-ip"

  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
  }

  depends_on = [aws_config_configuration_recorder_status.recorder_status]
}

resource "aws_config_config_rule" "root_mfa_enabled" {
  name = "root-account-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.recorder_status]
}


resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  depends_on = [aws_config_configuration_recorder_status.recorder_status]
}

resource "aws_cloudwatch_event_rule" "config_noncompliance" {
  name        = "${var.name_prefix}-config-noncompliance"
  description = "Capture AWS Config non-compliant rule evaluations"
  event_pattern = jsonencode({
    source = ["aws.config"],
    detail-type = ["Config Rules Compliance Change"],
    detail = {
      complianceType = ["NON_COMPLIANT"]
    }
  })
}



resource "aws_sns_topic_policy" "config_sns_policy" {
arn    = var.sns_topic_arn

policy = jsonencode({
Version = "2012-10-17",
Statement: [
{
Effect: "Allow",
Principal: { Service: "config.amazonaws.com" },
Action: "SNS:Publish",
Resource: var.sns_topic_arn
}
]
})
}

resource "aws_cloudwatch_event_target" "config_to_sns" {
rule      = aws_cloudwatch_event_rule.config_noncompliance.name
arn       = var.sns_topic_arn
target_id = "SendConfigNonComplianceToSNS"
}



