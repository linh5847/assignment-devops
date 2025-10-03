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
/*
resource "null_resource" "wait_for_lambda_authorizer_jwt" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nWaiting for the JWT Token...\n"
      rm -rf *.zip
      rm -rf lambda_authorizer/jwt
      rm -rf lambda_authorizer/PyJWT*
      sleep 3
      pip install --target lambda_authorizer PyJWT
      sleep 5
    EOF
  }
}
*/
resource "random_pet" "random_name" {
  length = 4

  #depends_on = [null_resource.wait_for_lambda_authorizer_jwt]
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
/*
# Policy for DynamoDB
resource "aws_iam_policy" "DynamoDBAccessPolicy" {
  name        = "DynamoDBAccessPolicy"
  description = "DynamoDBAccessPolicy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "dynamodb:List*",
            "dynamodb:DescribeReservedCapacity*",
            "dynamodb:DescribeLimits",
            "dynamodb:DescribeTimeToLive"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "dynamodb:BatchGet*",
            "dynamodb:DescribeStream",
            "dynamodb:DescribeTable",
            "dynamodb:Get*",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:BatchWrite*",
            "dynamodb:CreateTable",
            "dynamodb:Delete*",
            "dynamodb:Update*",
            "dynamodb:PutItem"
          ],
          "Resource" : [
            "arn:aws:dynamodb:*:*:table/Books_Table"
          ],
          "Effect" : "Allow"
        }
      ]
    }
  )
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda_basic_execution"
  roles      = [aws_iam_role.lambdaexecution.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy_attachment" "lambda_dynamodb_access" {
  name       = "lambda_dynamodb_access"
  roles      = [aws_iam_role.lambdaexecution.name]
  policy_arn = aws_iam_policy.DynamoDBAccessPolicy.arn
}

# Create DynamoDB for future Order moving from inside Java added list into JSON file
resource "aws_dynamodb_table" "order_table" {
  name = "orders"
  #billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 5

  hash_key = "orderId"

  attribute {
    name = "orderId"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"


  warm_throughput {
    read_units_per_second  = 12000
    write_units_per_second = 4000
  }

}

# Data process via JSON file. 
locals {
  json_data = file("${path.module}/files/order.json")
  orders    = jsondecode(local.json_data)
}

resource "aws_dynamodb_table_item" "orders" {
  for_each   = local.orders
  table_name = aws_dynamodb_table.order_table.name
  hash_key   = aws_dynamodb_table.order_table.hash_key
  item       = jsonencode(each.value)
}
*/
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

resource "aws_cloudwatch_log_group" "lambda_function_cloudwatch" {
  name              = "/aws/lambda/${aws_lambda_function.lambdafunct.function_name}"
  retention_in_days = 7
}

resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "RestApi-restapi"
  description = "Handle external request from outside"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "{proxy+}"
}

# Lambda Authorizer
resource "aws_api_gateway_authorizer" "my_authorizer" {
  name                             = "my_authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.lambda_api.id
  authorizer_uri                   = "arn:aws:apigateway:eu-west-2:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_authorizer.arn}/invocations"
  identity_source                  = "method.request.header.authorizationToken"
  authorizer_result_ttl_in_seconds = 0
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.my_authorizer.id
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambdafunct.invoke_arn
}

resource "aws_api_gateway_method_response" "GET_one_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration_response" "GET_one_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.GET_one_method_response_200.status_code

  depends_on = [aws_api_gateway_integration.lambda]

  response_templates = {
    "application/json" = <<EOF
    #set($inputRoot = $input.path('$.body'))
    {
      \"statusCode\": $input.path('$.statusCode'),
      \"body\": $inputRoot,
      \"headers\": {
        \"Content-Type\": \"application/json\"
      }
    }
    EOF
  }
}

resource "aws_api_gateway_resource" "proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "lists"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy_root.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.my_authorizer.id
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambdafunct.invoke_arn
}

resource "aws_api_gateway_method_response" "GET_all_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy_root.id
  http_method = aws_api_gateway_method.proxy_root.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration_response" "GET_all_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_root.http_method
  status_code = aws_api_gateway_method_response.GET_all_method_response_200.status_code

  depends_on = [aws_api_gateway_integration.lambda_root]

  response_templates = {
    "application/json" = <<EOF
    #set($inputRoot = $input.path('$.body'))
    {
      \"statusCode\": $input.path('$.statusCode'),
      \"body\": $inputRoot,
      \"headers\": {
        \"Content-Type\": \"application/json\"
      }
    }
    EOF
  }
}

# POST
resource "aws_api_gateway_method" "POST_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.my_authorizer.id
}

resource "aws_api_gateway_integration" "POST_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.POST_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.lambdafunct.invoke_arn
}

resource "aws_api_gateway_method_response" "POST_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.POST_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration_response" "POST_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.POST_method.http_method
  status_code = aws_api_gateway_method_response.POST_method_response_200.status_code

  depends_on = [aws_api_gateway_integration.POST_lambda_integration]

  response_templates = {
    "application/json" = <<EOF
    #set($inputRoot = $input.path('$.body'))
    {
      \"statusCode\": 200,
      \"body\": $inputRoot,
      \"headers\": {
        \"Content-Type\": \"application/json\"
      }
    }
    EOF
  }
}

# PATCH
resource "aws_api_gateway_method" "PATCH_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "PATCH"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.my_authorizer.id
}

resource "aws_api_gateway_integration" "PATCH_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.PATCH_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.lambdafunct.invoke_arn
}

resource "aws_api_gateway_method_response" "PATCH_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.PATCH_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "PATCH_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.PATCH_method.http_method
  status_code = aws_api_gateway_method_response.PATCH_method_response_200.status_code

  depends_on = [aws_api_gateway_integration.PATCH_lambda_integration]

  response_templates = {
    "application/json" = <<EOF
    #set($inputRoot = $input.path('$.body'))
    {
      \"statusCode\": 200,
      \"body\": $inputRoot,
      \"headers\": {
        \"Content-Type\": \"application/json\"
      }
    }
    EOF
  }
}

# DELETE
resource "aws_api_gateway_method" "DELETE_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.my_authorizer.id
}

resource "aws_api_gateway_integration" "DELETE_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.DELETE_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.lambdafunct.invoke_arn
}

resource "aws_api_gateway_method_response" "DELETE_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.DELETE_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "DELETE_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.DELETE_method.http_method
  status_code = aws_api_gateway_method_response.DELETE_method_response_200.status_code

  depends_on = [aws_api_gateway_integration.DELETE_lambda_integration]

  response_templates = {
    "application/json" = <<EOF
    #set($inputRoot = $input.path('$.body'))
    {
      \"statusCode\": 200,
      \"body\": $inputRoot,
      \"headers\": {
        \"Content-Type\": \"application/json\"
      }
    }
    EOF
  }
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

resource "aws_lambda_permission" "authorizer-warmup-permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_authorizer.function_name
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

# Setup Lambda permission to allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "allow_api_gateway_invoke_authorizer" {
  statement_id  = "AllowAPIGatewayInvoke_authorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "web" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
    aws_api_gateway_integration.PATCH_lambda_integration,
    aws_api_gateway_integration.POST_lambda_integration,
    aws_api_gateway_integration.DELETE_lambda_integration
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy,
      aws_api_gateway_method.proxy,
      aws_api_gateway_integration.lambda,
      aws_api_gateway_method.proxy_root,
      aws_api_gateway_integration.lambda_root,
      aws_api_gateway_method.POST_method,
      aws_api_gateway_integration.POST_lambda_integration,
      aws_api_gateway_method.PATCH_method,
      aws_api_gateway_integration.PATCH_lambda_integration,
      aws_api_gateway_method.DELETE_method,
      aws_api_gateway_integration.DELETE_lambda_integration
    ]))
  }

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.web.id
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_execution_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }
}

# CloudWatch log group for api execution logs
resource "aws_cloudwatch_log_group" "api_gateway_execution_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.lambda_api.id}/prod"
  retention_in_days = 7
}

resource "aws_api_gateway_method_settings" "method_settings" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"
  settings {
    logging_level      = "INFO"
    data_trace_enabled = true
    metrics_enabled    = true
  }
}

# Authorizer IAM Role
resource "aws_iam_role" "lambda_authorizer_role" {
  name = "lambda_auth_execution_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "lambda.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

# Define IAM role policy for Lambda function
resource "aws_iam_role_policy" "lambda_authorizer_exec_policy" {
  name = "lambda_exec_policy"
  role = aws_iam_role.lambda_authorizer_role.id

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

resource "aws_iam_policy_attachment" "lambda_basic_execution_authorizer" {
  name       = "lambda_basic_execution_authorizer"
  roles      = [aws_iam_role.lambda_authorizer_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Compressing lambda authorizer code
data "archive_file" "lambda_authorizer_archive" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_authorizer"
  output_path = "${path.module}/lambda_authorizer.zip"
}

# Creating Lambda authorizer
resource "aws_lambda_function" "lambda_authorizer" {
  function_name = "LambdaAuthorizer"
  filename      = "${path.module}/lambda_authorizer.zip"

  runtime     = "python3.12"
  handler     = "lambda_authorizer.lambda_handler"
  memory_size = 128
  timeout     = 10

  source_code_hash = data.archive_file.lambda_authorizer_archive.output_base64sha256

  role = aws_iam_role.lambda_authorizer_role.arn

  environment {
    variables = {
      JWT_SECRET_KEY = "secret_api_tutorial"
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_authorizer_cloudwatch" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_authorizer.function_name}"
  retention_in_days = 7
}