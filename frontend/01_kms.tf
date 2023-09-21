resource "aws_kms_alias" "s3_main" {
  name          = "alias/${aws_kms_key.s3_main.tags["Name"]}"
  target_key_id = aws_kms_key.s3_main.key_id
}

resource "aws_kms_key" "s3_main" {
  enable_key_rotation = true
  description         = ""
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid": "Enable IAM User Permissions",
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action": "kms:*",
        "Resource": "*"
      },
      {
        "Sid": "AllowCloudFrontServicePrincipalSSE-KMS",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
          "Service": "cloudfront.amazonaws.com"
        },
        "Action": [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ],
        "Resource": "*",
        "Condition": {
          "StringEquals": {
            "AWS:SourceArn": "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.main.id}"
          }
        }
      }
    ]
  })
  tags = {
    Name = "${var.project}-s3-main-kms-${var.env}"
  }
}
