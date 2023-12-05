####################
# APIGateway
####################
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.apigateway_logs.arn
}
