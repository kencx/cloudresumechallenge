output "bucket_name" {
  value       = aws_s3_bucket.resume.id
  description = "Name of bucket"
}

output "bucket_endpoint" {
  value       = aws_s3_bucket.resume.website_endpoint
  description = "Bucket Endpoint URL"
}

output "domain_name" {
  value       = local.site_url
  description = "Website URL"
}

