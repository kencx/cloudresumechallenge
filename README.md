# cloudresumechallenge

This repo contains the code for my take on the [cloudresumechallenge](https://cloudresumechallenge.dev/).

It builds a simple static site with a visitor counter on AWS and includes:

- Resume template from [Universal Resume](https://github.com/WebPraktikos/universal-resume)
- Infrastructure as Code with Terraform
- DNS and SSL management with Cloudflare
- CI/CD with Github Actions

## Architecture

The static site is hosted on an Amazon S3 bucket and Cloudflare. It also retrieves
the visitor count from DynamoDB. An API (served by API Gateway) invokes a Lambda
function to access the database table, retrieving the counter when a user
accesses the page.

#### CI/CD
CI/CD pipelines are conditionally run based on files modified using the
[paths-filter](https://github.com/dorny/paths-filter) action.

- Changes to `site/` synchronizes the new static files to the S3 bucket
- Changes to `api/` updates the Lambda function with Terraform. Ideally, this
  should only change one resource `aws_lambda_function`.
- Changes to `*.tf` files updates the Terraform resource states. These changes
  must be committed with a pull request. A plan output would be produced and
  vetted before the PR can be merged to master.

## TODO
- [ ] Store remote state in S3 bucket
- [ ] Python unit tests for Lambda function
- [ ] Add API Gateway CloudWatch logging
