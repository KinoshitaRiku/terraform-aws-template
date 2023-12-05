locals {
  cluster_identifier = "${var.project}-aurora-cluster-${var.env}"
  parameter_list = [
    { name = "character_set_server", value = "utf8mb4" },
    { name = "character_set_client", value = "utf8mb4" },
    { name = "character_set_connection", value = "utf8mb4" },
    { name = "character_set_filesystem", value = "utf8mb4" },
    { name = "character_set_database", value = "utf8mb4" },
    { name = "character_set_results", value = "utf8mb4" },
    { name = "time_zone", value = "Asia/Tokyo" },
    { name = "max_connections", value = "1000" },
    { name = "general_log", value = "0" },
    { name = "slow_query_log", value = "1" },
    { name = "long_query_time", value = "0" }
  ]
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnet-group-${var.env}"
  subnet_ids = [aws_subnet.main["private_1a"].id, aws_subnet.main["private_1c"].id]
}

resource "aws_rds_cluster" "main" {
  cluster_identifier  = local.cluster_identifier
  engine              = "aurora-mysql"
  engine_version      = "8.0.mysql_aurora.3.04.0"
  port                = "3306"
  availability_zones  = ["ap-northeast-1a", "ap-northeast-1c"]
  skip_final_snapshot = false

  database_name   = "init_database"
  master_username = var.db_username
  master_password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  allow_major_version_upgrade     = true
  apply_immediately               = true # 即時変更
  backtrack_window                = 3600
  deletion_protection             = var.env == "prod" ? true : false # 削除保護
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  final_snapshot_identifier       = "${var.project}-final-snapshot-${var.env}-${data.external.generate_date.result.date}"
  preferred_maintenance_window    = "mon:17:00-mon:17:30" # +9時間が日本時間となる
  storage_encrypted               = true                  # データベースのデータを暗号化
  kms_key_id                      = aws_kms_key.rds.arn
  preferred_backup_window         = "18:00-21:00" # +9時間が日本時間となる
  backup_retention_period         = 14            # 自動バックアップの保持期間
}

resource "aws_rds_cluster_instance" "main" {
  count              = var.env == "prod" ? 2 : 1
  identifier         = "aurora-cluster-${var.env}-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t4g.medium"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
}

resource "aws_rds_cluster_parameter_group" "main" {
  name   = "${var.project}-parameter-group-${var.env}"
  family = "aurora-mysql8.0"

  dynamic "parameter" {
    for_each = local.parameter_list
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = "immediate"
    }
  }
}
