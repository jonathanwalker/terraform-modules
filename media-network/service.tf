resource "aws_ecs_service" "jellyfin" {
  name            = "jellyfin-service"
  task_definition = aws_ecs_task_definition.jellyfin.arn
  cluster         = aws_ecs_cluster.jellyfin.id
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    awsvpc_configuration {
      subnets = var.private_subnets
      security_groups = [
        aws_security_group.jellyfin.id
      ]
    }
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.jellyfin.arn
  }
}

resource "aws_security_group" "jellyfin" {
  name = "jellyfin-security-group"

  tags = var.tags
}

resource "aws_security_group_rule" "jellyfin_ingress" {
  type                     = "ingress"
  from_port                = 8096
  to_port                  = 8096
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jellyfin_alb.id
  security_group_id        = aws_security_group.jellyfin.id
}

resource "aws_alb" "jellyfin" {
  name     = "jellyfin-alb"
  internal = false
  security_groups = [
    aws_security_group.jellyfin_alb.id
  ]
  subnets = var.public_subnets
}

resource "aws_security_group" "jellyfin_alb" {
  name = "jellyfin-alb-security-group"

  tags = var.tags
}

resource "aws_security_group_rule" "alb_ingress" {
  type              = "ingress"
  from_port         = 8096
  to_port           = 8096
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ips
  security_group_id = aws_security_group.jellyfin_alb.id
}


resource "aws_route53_record" "jellyfin" {
  name    = var.dns_name
  type    = "A"
  zone_id = var.zone_id
  alias {
    name                   = aws_alb.jellyfin.dns_name
    zone_id                = aws_alb.jellyfin.zone_id
    evaluate_target_health = true
  }
}
