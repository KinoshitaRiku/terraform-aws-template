resource "aws_cognito_user_pool" "main" {
  name = "${var.project}-cognito-pool-${var.env}"
  # mfa_configuration = "ON"
  password_policy {
    minimum_length    = 8    # 最小文字数
    require_lowercase = true # 少なくとも1つの小文字を含む
    require_numbers   = true # 少なくとも1つの数字を含む
    require_symbols   = true # 少なくとも1つの特殊文字（例: !@#$%^&*()）
    require_uppercase = true # 少なくとも1つの大文字を含む
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project}-cognito-client-${var.env}"
  user_pool_id = aws_cognito_user_pool.main.id
  generate_secret = true
}