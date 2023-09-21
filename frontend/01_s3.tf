################################
# メンテナンスページ用バケット
################################
data "aws_iam_policy_document" "s3_main_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket" "main" {
  bucket        = "${var.project}-frontend-main-${data.aws_caller_identity.current.account_id}-${var.env}"
  force_destroy = false
  tags = {
    Name = "${var.project}-frontend-main-${data.aws_caller_identity.current.account_id}-${var.env}"
  }
}

# オブジェクト所有者をバケット所有者の強制とする
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.s3_main_policy.json
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      # sse_algorithmがaws:kmsのときにこの要素がない場合、デフォルトのaws/s3 AWS KMSマスターキーが使用されます。
      kms_master_key_id = aws_kms_key.s3_main.key_id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
