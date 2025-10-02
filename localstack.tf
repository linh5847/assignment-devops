provider "aws" {
  region                      = "eu-west-2"
  access_key                  = "fake"
  secret_key                  = "fake"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

resource "random_pet" "random_name" {
  length = 1
}

# S3 bucket
resource "aws_s3_bucket" "devops_bucket" {
  bucket        = "devops-bucket-${random_pet.random_name.id}"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
}
# Define a bucket for the lambda zip
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket        = "devops-validator-bucket-${random_pet.random_name.id}"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
}

# Lambda source code
resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code_bucket.id
  key    = "devops-0.0.1-SNAPSHOT.jar"
  source = "target/devops-0.0.1-SNAPSHOT.jar"
}

# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambdaexecution" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Define IAM role policy for Lambda function
resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "lambda_exec_policy"
  role = aws_iam_role.lambdaexecution.id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": [
             "logs:CreateLogGroup",
             "logs:CreateLogStream",
             "logs:PutLogEvents"
           ],
           "Resource": "arn:aws:logs:*:*:*"
       },
       {
           "Effect": "Allow",
           "Action": [
             "s3:GetObject",
             "s3:PutObject"
           ],
           "Resource": [
             "arn:aws:s3:::devops-bucket-${random_pet.random_name.id}",
             "arn:aws:s3:::devops-bucket-${random_pet.random_name.id}/*"
           ]
       }
   ]
}
EOF
}

resource "aws_lambda_function" "lambdafunct" {
  function_name = "restapi"
  handler       = "com.gler.devops.ServiceHandler::handleRequest"
  runtime       = "java17"
  role          = aws_iam_role.lambdaexecution.arn
  s3_bucket     = aws_s3_bucket.lambda_code_bucket.id
  s3_key        = aws_s3_object.lambda_code.key
  memory_size   = 512
  timeout       = 60
  environment {
    variables = {
      BUCKET = aws_s3_bucket.devops_bucket.bucket
    }
  }

  tags = merge(
    {
      "Name" = format("%s", "restapi")
    },
    var.additional_tags,
  )
}

resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "RestApi-restapi"
  description = "Handle external request from outside"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambdafunct.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambdafunct.invoke_arn
}

resource "aws_api_gateway_deployment" "web" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.web.id
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  stage_name    = "local"
}

resource "aws_cloudwatch_event_rule" "warmup" {
  name                = "warmup-event-rule-restapi"
  schedule_expression = "rate(10 minutes)"

  event_pattern = jsonencode({
    "source" : [
      "aws.ec2",
      "aws.rds",
      "aws.s3"
    ],
    "detail-type" : [
      "AWS API Call via CloudTrail"
    ],
    "detail" : {
      "eventSource" : [
        "ec2.amazonaws.com",
        "rds.amazonaws.com",
        "s3.amazonaws.com"
      ],
      "eventName" : [
        "Create*",
        "Delete*",
        "Update*"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "warmup" {
  target_id = "warmup"
  rule      = aws_cloudwatch_event_rule.warmup.name
  arn       = aws_lambda_function.lambdafunct.arn
  input     = "{\"httpMethod\": \"SCHEDULE\", \"path\": \"warmup\"}"
}

resource "aws_lambda_permission" "warmup-permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdafunct.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.warmup.arn
}

resource "aws_lambda_permission" "apiw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdafunct.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}