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
}
