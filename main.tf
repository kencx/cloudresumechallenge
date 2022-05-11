terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.13.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.14.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  site_url = "${var.subdomain}.${var.site_domain}"
}

data "aws_iam_policy_document" "policy_document" {
  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.resume.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket" "resume" {
  bucket = local.site_url
}

resource "aws_s3_bucket_policy" "resume" {
  bucket = aws_s3_bucket.resume.id
  policy = data.aws_iam_policy_document.policy_document.json
}

resource "aws_s3_bucket_website_configuration" "resume" {
  bucket = aws_s3_bucket.resume.id

  index_document {
    suffix = "index.html"
  }
}

data "cloudflare_zone" "domain" {
  name = var.site_domain
}

resource "cloudflare_record" "resume_cname" {
  zone_id = data.cloudflare_zone.domain.id
  name    = var.subdomain
  value   = aws_s3_bucket.resume.website_endpoint
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_page_rule" "https" {
  zone_id = data.cloudflare_zone.domain.id
  target  = "*.${local.site_url}/*"
  actions {
    always_use_https = true
  }
}
