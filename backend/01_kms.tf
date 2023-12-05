resource "aws_kms_key" "rds" {
  enable_key_rotation = true
  tags = {
    Name = "${var.project}-rds-kms-${var.env}"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${aws_kms_key.rds.tags["Name"]}"
  target_key_id = aws_kms_key.rds.key_id
}
