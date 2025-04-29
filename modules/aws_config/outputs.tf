output "config_bucket_name" {
  description = "The S3 bucket name for AWS Config"
  value       = aws_s3_bucket.config_bucket.bucket
}


