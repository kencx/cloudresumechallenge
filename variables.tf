variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-1"
}

variable "subdomain" {
  type        = string
  description = "Subdomain name of site"
}

variable "site_domain" {
  type        = string
  description = "Root domain name of site"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token"
  sensitive   = true
}

variable "table_name" {
  type        = string
  description = "DynamoDB table name"
  default     = "siteVisits"
}

variable "sites" {
  type        = list(any)
  description = "List of site's URLs"
  default     = []
}

variable "lambda_source_path" {
  type        = string
  description = "Path to Lambda function source file"
}
