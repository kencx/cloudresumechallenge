# cloudresumechallenge
This repository builds a simple, static resume site that fetches the total count
of site visitors from a database. It is hosted entirely on AWS and features:

- Resume template from [Universal Resume](https://github.com/WebPraktikos/universal-resume)
- Infrastructure as Code with Terraform
- DNS and SSL management with Cloudflare
- CI/CD with Github Actions

This project is inspired entirely by
[cloudresumechallenge](https://cloudresumechallenge.dev/) and serves as a learning
experience for working with cloud services.

## Architecture

The static site is hosted on an Amazon S3 bucket and served with Cloudflare DNS.
It retrieves the visitor count from DynamoDB through an API. The API is served by
API Gateway and it invokes a Lambda function that accesses the database table.
The count is returned as a response on the site.

### CI/CD
The CI/CD pipelines are conditionally run based on modified files using
[paths-filter](https://github.com/dorny/paths-filter).

- Changes to `site/` synchronizes the new static files to the S3 bucket
- Changes to `api/` runs unit tests and updates the Lambda function with
  Terraform. Ideally, this should only change one resource
  `aws_lambda_function`.
- Changes to `*.tf` files updates the Terraform resource states. These changes
  must be committed with a pull request. A plan output would be produced and
  vetted before the PR can be merged to master.

## TODO
- [x] Python unit tests for Lambda function
- [ ] Add API Gateway CloudWatch logging
