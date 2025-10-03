output "api_gateway_id" {
  value = aws_api_gateway_rest_api.lambda_api.id
}

output "lambda_function_name" {
  value = aws_lambda_function.lambdafunct.function_name
}

output "lambda_authorizer_name" {
  value = aws_lambda_function.lambda_authorizer.function_name
}