locals {
  appautoscaling_map = {
    scale_out = {
      name               = "scale-out"
      scaling_adjustment = 1
      comparison_operator = "GreaterThanOrEqualToThreshold"
    }
    scale_out = {
      name               = "scale-in"
      scaling_adjustment = -1
      comparison_operator = "LessThanOrEqualToThreshold"
    }
  }
}

####################
# ECS_クラスター
####################
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-ecs-cluster-${var.env}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

####################
# ECS_タスク定義
####################
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project}-ecs-task-definition-${var.env}"
  cpu                      = 2048
  memory                   = 4096
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  requires_compatibilities = ["FARGATE"]
  container_definitions    = jsonencode([
    {
      "name": "${var.project}_nginx_${var.env}",
      "image": "public.ecr.aws/nginx/nginx:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ]
    }
  ])
}

####################
# ECS_サービスディスカバリー
####################
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "local"
  description = "${var.project}-ecs-service-discovery-dns-${var.env}"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "main" {
  name = "${var.project}-ecs-service-discovery-${var.env}"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

####################
# ECS_サービス
####################
resource "aws_ecs_service" "main" {
  name                              = "${var.project}-ecs-service-${var.env}"
  cluster                           = aws_ecs_cluster.main.name
  launch_type                       = "FARGATE"
  desired_count                     = 1
  platform_version                  = "1.4.0"
  task_definition                   = aws_ecs_task_definition.main.arn
  health_check_grace_period_seconds = 60
  enable_execute_command            = false
  deployment_controller {
    type = "ECS"
  }
  network_configuration {
    subnets          = [
      aws_subnet.main["private_1a"].id, 
      aws_subnet.main["private_1c"].id
    ]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${var.project}_nginx_${var.env}"
    container_port   = "80"
  }
  service_registries {
    registry_arn = aws_service_discovery_service.main.arn
  }
  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}

####################
# ECS_アラーム
####################
resource "aws_cloudwatch_metric_alarm" "main" {
  for_each = local.appautoscaling_map
  alarm_name = "${var.project}-${each.value.name}-alarm-${var.env}"
  # アラーム検知ルール 指標の値がxx以上
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
  alarm_actions = [aws_appautoscaling_policy.main[each.key].arn]
}

####################
# ECS_オートスケーリング
####################
resource "aws_appautoscaling_target" "main" {
  min_capacity       = 1
  max_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "main" {
  for_each           = local.appautoscaling_map
  name               = each.value.name
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    # スケールアウトしてから、クールダウンとして10分間待機する
    cooldown = 600
    # 平均値を指標とする
    metric_aggregation_type = "Average"
    step_adjustment {
      # 追加するタスク数
      scaling_adjustment          = each.value.scaling_adjustment
      metric_interval_lower_bound = 0
    }
  }
}
