resource "aws_ecs_service" "jellyfin" {
  name            = "jellyfin-service"
  task_definition = aws_ecs_task_definition.jellyfin.arn
  cluster         = aws_ecs_cluster.cluster.id
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.private_subnets
    security_groups = [
      aws_security_group.jellyfin.id
    ]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.jellyfin.arn
    container_port   = 8096
    container_name   = "jellyfin"
  }

  depends_on = [
    aws_ecs_task_definition.jellyfin,
    aws_ecs_cluster.cluster,
    aws_security_group.jellyfin,
    aws_security_group_rule.jellyfin_ingress,
    aws_alb.jellyfin,
    aws_alb_listener.jellyfin,
    aws_alb_target_group.jellyfin,
    aws_security_group.jellyfin_alb,
    aws_security_group_rule.alb_ingress,
    aws_route53_record.jellyfin
  ]
}

resource "aws_security_group" "jellyfin" {
  name = "jellyfin-security-group"
  vpc_id = var.vpc_id

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

resource "aws_security_group_rule" "jellyfin_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jellyfin.id
}

resource "aws_alb" "jellyfin" {
  name     = "jellyfin-alb"
  internal = false
  security_groups = [
    aws_security_group.jellyfin_alb.id
  ]
  subnets = var.public_subnets
}

resource "aws_alb_listener" "jellyfin" {
  load_balancer_arn = aws_alb.jellyfin.arn
  port              = "8096"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.jellyfin.arn
  }
}

resource "aws_alb_target_group" "jellyfin" {
  name      = "jellyfin-target-group"
  port      = 8096
  protocol  = "HTTP"
  vpc_id    = var.vpc_id

  target_type = "ip"
}

resource "aws_security_group" "jellyfin_alb" {
  name = "jellyfin-alb-security-group"
  vpc_id = var.vpc_id

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

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 8096
  to_port           = 8096
  protocol          = "tcp"
  security_group_id = aws_security_group.jellyfin.id
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
