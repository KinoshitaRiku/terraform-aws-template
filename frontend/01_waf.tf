locals {
  whitelist_rule_group_name = "block-by-ip-exclude-rule"
  rule_list = [
    {
      # AWSが疑わしいまたは悪意のあると判断したIPアドレスからのトラフィックを検出・ブロックする
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = 1
    },{
      # 一般的に悪意のあるとされる入力に対処する
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 2
    },{
      # Cross-site scripting (XSS)、サイズ制約、HTTPメソッド制約、
      # 不正なボットからのトラフィックなど、多くの一般的な脅威を検出・ブロックします
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 3
    },{
      # SQLインジェクション攻撃を特定・阻止する
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 4
    }
  ]
}

resource "aws_wafv2_ip_set" "main" {
  provider           = aws.us_east_1
  name               = "${var.project}-whitelist-ip-set-${var.env}"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.ip_whitelist
}

resource "aws_wafv2_rule_group" "main" {
  provider    = aws.us_east_1
  name        = "${var.project}-whitelist-rule-group-${var.env}"
  scope       = "CLOUDFRONT"
  capacity    = 1

  # web acls単位でのメトリクス
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-whitelist-rule-group-${var.env}"
    # 許可した場合のアクセス元を記録(IPsetsで定義したIPアドレスのみ)
    sampled_requests_enabled = true
  }

  # ホワイトリスト以外からのアクセスをブロックするルール
  rule {
    name     = local.whitelist_rule_group_name
    priority = 0
    action {
      block {
        custom_response {
          response_code = 503
          response_header {
            name  = "Location"
            value = "https://maintenance.${var.domain}/"
          }
          response_header {
            name  = "Cache-Control"
            value = "private, no-store, no-cache, must-revalidate"
          }
          response_header {
            name  = "Pragma"
            value = "no-cache"
          }
        }
      }
    }
    statement {
      # ステートメントに一致しない場合
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.main.arn
          }
        }
      }
    }

    # ルール単位でのメトリクス
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = local.whitelist_rule_group_name
      # 拒否した場合のアクセス元を記録
      sampled_requests_enabled = true
    }
  }
}

resource "aws_wafv2_web_acl" "main" {
  provider    = aws.us_east_1
  name        = "${var.project}-web-acl-${var.env}"
  scope       = "CLOUDFRONT"
  default_action {
    allow {}
  }
  # デフォルトアクションのメトリクス
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-web-acl-${var.env}"
    sampled_requests_enabled   = true
  }
  dynamic "rule" {
    for_each = local.rule_list
    content {
      name     = rule.value.name
      priority = rule.value.priority
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }
}
