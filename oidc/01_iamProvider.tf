##########
# terraform cloud
##########
locals {
  policy_arn_list = toset([
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ])
}

data "tls_certificate" "tfc" {
  url = "https://${var.tfc_hostname}"
}

resource "aws_iam_openid_connect_provider" "tfc" {
  url             = data.tls_certificate.tfc.url
  client_id_list  = [var.tfc_aws_audience]
  thumbprint_list = [data.tls_certificate.tfc.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "tfc" {
  name                  = "oidc-terraform-cloud-role"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "${aws_iam_openid_connect_provider.tfc.arn}"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${var.tfc_hostname}:aud": "${one(aws_iam_openid_connect_provider.tfc.client_id_list)}"
          },
          "StringLike": {
            "${var.tfc_hostname}:sub": "organization:${var.tfc_organization_name}:project:*:workspace:*:run_phase:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tfc" {
  for_each = local.policy_arn_list
  role       = aws_iam_role.tfc.name
  policy_arn = each.key
}
