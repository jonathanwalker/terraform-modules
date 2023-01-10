output "function_name" { 
  value = aws_lambda_function.lambda_function.name 
}

output "function_region" { 
  value = aws_lambda_function.lambda_function.region 
}