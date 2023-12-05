# Application Load Balancer (ALB)
# - トラフィックタイプ: 主にHTTP/HTTPSトラフィックを処理。
# - ルーティングニーズ: ホスト名やパスベースなど、複雑なルーティングルールに対応。
# - 特長: WebSocketやHTTP/2トラフィックのサポート、詳細な監視とロギング機能。

# Network Load Balancer (NLB)
# - トラフィックタイプ: 主にTCP/UDPトラフィックを処理。
# - パフォーマンス要件: 高いスループットと超低レイテンシに対応。
# - 接続の持続性: 長期間持続する接続に適しており、状態を持たない。
# - 特長: 静的IPアドレスやElastic IPアドレスの利用可能。

####################
# NLB
####################
resource "aws_lb" "main" {
  name                       = "${var.project}-nlb-${var.env}"
  load_balancer_type         = "network"
  internal                   = true
  enable_deletion_protection = false
  subnets = [
    aws_subnet.main["private_1a"].id,
    aws_subnet.main["private_1c"].id
  ]
}

resource "aws_lb_target_group" "main" {
  name = "${var.project}-lb-target-${var.env}"
  vpc_id = aws_vpc.main.id
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  health_check {
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
