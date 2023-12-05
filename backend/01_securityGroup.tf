####################
# SG_ECS
####################
resource "aws_security_group" "ecs" {
  name   = "${var.project}-ecs-sg-${var.env}"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = [
    aws_subnet.main["private_1a"].cidr_block,
    aws_subnet.main["private_1c"].cidr_block
  ]
}

####################
# RDS_ECS
####################
resource "aws_security_group" "rds" {
  name   = "${var.project}-rds-sg-${var.env}"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_from_ecs" {
  security_group_id        = aws_security_group.ecs.id
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}
