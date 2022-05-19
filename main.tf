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
  region = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  site_url = "${var.subdomain}.${var.site_domain}"
}

data "cloudflare_zone" "domain" {
  name = var.site_domain
}

resource "cloudflare_record" "resume_cname" {
  zone_id    = data.cloudflare_zone.domain.id
  name       = var.subdomain
  value      = aws_s3_bucket.resume.website_endpoint
  type       = "CNAME"
  proxied    = true
  depends_on = [aws_s3_bucket.resume]
}

resource "cloudflare_page_rule" "https" {
  zone_id = data.cloudflare_zone.domain.id
  target  = "*.${local.site_url}/*"
  actions {
    always_use_https = true
  }
}

# s3
resource "aws_s3_bucket" "resume" {
  bucket        = local.site_url
  force_destroy = true
}

resource "aws_s3_bucket_policy" "resume" {
  bucket     = aws_s3_bucket.resume.id
  policy     = data.aws_iam_policy_document.s3_policy_doc.json
  depends_on = [aws_s3_bucket.resume]
}

resource "aws_s3_bucket_website_configuration" "resume" {
  bucket = aws_s3_bucket.resume.id

  index_document {
    suffix = "index.html"
  }
  depends_on = [aws_s3_bucket.resume]
}

data "aws_iam_policy_document" "s3_policy_doc" {
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
  depends_on = [aws_s3_bucket.resume]
}

# dynamodb
resource "aws_dynamodb_table" "table" {
  name           = var.table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "url"

  attribute {
    name = "url"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "items" {
  table_name = aws_dynamodb_table.table.name
  hash_key   = aws_dynamodb_table.table.hash_key

  for_each   = toset(var.sites)
  item       = <<ITEM
{
  "url": {"S": "${each.key}"}
}
ITEM
  depends_on = [aws_dynamodb_table.table]
}

# lambda
resource "aws_lambda_function" "counter" {
  function_name = "counterUpdate"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_counter.arn

  filename         = "${path.module}/lambda.zip"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  depends_on       = [aws_iam_role.lambda_counter]
}

resource "aws_iam_role" "lambda_counter" {
  name               = "counterUpdate"
  assume_role_policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name       = "counterUpdatePolicy"
  role       = aws_iam_role.lambda_counter.id
  policy     = data.aws_iam_policy_document.lambda_dynomodb_policy_doc.json
  depends_on = [aws_iam_role.lambda_counter]
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_dynomodb_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
    ]
    resources = ["${aws_dynamodb_table.table.arn}"]
  }
  depends_on = [aws_dynamodb_table.table]
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "${path.module}/${var.lambda_source_path}"
  output_path = "${path.module}/lambda.zip"
}

# api gateway
resource "aws_apigatewayv2_api" "counter" {
  name          = "counter"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["*"]
    allow_methods = ["OPTIONS", "POST"]
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "counter" {
  api_id      = aws_apigatewayv2_api.counter.id
  name        = "$default"
  auto_deploy = true
  depends_on  = [aws_apigatewayv2_api.counter]

  # access_log_settings {
  #   destination_arn = aws_cloudwatch_log_group.api_gw.arn
  #   format = jsonencode({
  #
  #   })
  # }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.counter.id

  integration_uri    = aws_lambda_function.counter.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"

  payload_format_version = "2.0"
  depends_on             = [aws_apigatewayv2_api.counter, aws_lambda_function.counter]
}

resource "aws_apigatewayv2_route" "counter" {
  api_id = aws_apigatewayv2_api.counter.id

  api_key_required = false
  route_key        = "POST /"
  target           = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  depends_on       = [aws_apigatewayv2_api.counter, aws_apigatewayv2_integration.lambda]
}

# resource "aws_cloudwatch_log_group" "api_gw" {
#   name              = "aws/api_gw/${aws_apigatewayv2_api.counter.name}"
#   retention_in_days = 30
# }

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.counter.function_name
  principal     = "apigateway.amazonaws.com"
  depends_on    = [aws_lambda_function.counter]
}

resource "local_file" "outputs" {
  content         = <<EOF
api_url='{"url" : "${aws_apigatewayv2_stage.counter.invoke_url}"}';
EOF
  filename        = "${path.module}/site/docs/api_url.json"
  file_permission = "0744"
}
