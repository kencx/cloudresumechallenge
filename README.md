# Cloud Resume Challenge AWS

This repository builds a simple, static resume site that fetches the total count
of site visitors from a database. It is hosted entirely on AWS and features:

- Resume template from [Universal Resume](https://github.com/WebPraktikos/universal-resume)
- Infrastructure as Code with Terraform
- DNS and SSL management with Cloudflare
- CI/CD with Github Actions

This project is inspired entirely by
[cloudresumechallenge](https://cloudresumechallenge.dev/) and serves as a
learning experience for working with cloud services. It is a simple hands-on
project to practice working with cloud service and DevOps tools.

## Goals

- [x] Static site hosted on S3 bucket
- [x] Request visitor count from API Gateway
- [x] Lambda function that calls DynamoDB
- [x] Infrastructure as Code
- [x] Good Git hygiene and pull request discipline
- [x] Full CI/CD deployment for any code changes
- [x] SSL/TLS
- [x] Units tests for Lambda function
- [x] Remote state in separate S3 bucket
- [ ] API Gateway CloudWatch Logging

## Architecture

The static site is hosted on an Amazon S3 bucket and served with Cloudflare DNS.
It retrieves the visitor count from DynamoDB through an API. The API is served
by API Gateway and it invokes a Lambda function that accesses the database
table. The count is returned as a response on the site.

All infrastructure is managed with Terraform, including the Cloudflare DNS
records and  the Python code in the Lambda function.

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

## Usage

Prerequisites:
- AWS account (with free tier if possible)
- Terraform v1.2.0
- Python 3.9
- Docker (for npm Docker image or install npm locally)

To build the site locally:

```bash
$ make install
$ make build
$ make serve
```

To provision infrastructure, populate `auto.tfvars` with relevant variables and
run:

```bash
$ terraform init
$ make tplan
$ make tapply
```

This provisions:
- S3 bucket
- Cloudflare CNAME DNS record
- Lambda function
- DynamoDB table and items
- API Gateway routes

Static files in S3 bucket must be added manually OR can be added via CI job on
push to `master`.

```bash
$ aws s3 sync ./site/docs/ s3://[bucket_name]
```

To destroy infrastructure at the end of the day,

```bash
$ make tdestroy
```

#### CI/CD

The following secrets must be added for the CI/CD workflow to run successfully:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `CLOUDFLARE_TOKEN`
- `AWS_S3_BUCKET`

>`AWS_REGION` is hard-coded to be `ap-southeast-1`. Please change this if you
>are in a different region.

## Issues

#### CORS Support

To enable CORS support for Lambda proxy integrations in API Gateway, the
[documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-cors.html)
(and
[others](https://stackoverflow.com/questions/31911898/configure-cors-response-headers-on-aws-lambda))
mentions that the appropriate CORS headers must be included in **the response of
the Lambda function** manually, instead of being configured directly in API
Gateway.

However, I was not able to get this to work, with the browser still throwing a
`No access-control-allow-origin header present` error. As such, the CORS headers
are directly configured in API Gateway in the `cors_configuration` block. I hope
to understand and fix this in the future.

From the
[documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-cors.html),
it also mentions that API Gateway **ignores** CORS headers returned from the
backend integration if CORS is configured directly in the API.

#### Passing API endpoint to front-end

Currently, the API endpoint URL is passed to the front-end by uploading a JSON
file `api_url.json` to the S3 bucket. This file is then referenced in `index.js`
to update the visitor counter. There is probably a better way to pass the
endpoint URL to the site's front-end.
