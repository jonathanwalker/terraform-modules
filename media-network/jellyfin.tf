resource "aws_ecs_task_definition" "jellyfin" {
  family = "jellyfin-media-server"
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu = 4096
  memory = 8192

  container_definitions = jsonencode([
    {
      name: "jellyfin",
      image: "jellyfin/jellyfin:latest",
      memory: 8192,
      cpu: 4096,
      portMappings: [
        {
          containerPort: 8096,
          hostPort: 8096
        }
      ],
      environment: [
        {
          name: "PUID",
          value: "1000"
        },
        {
          name: "PGID",
          value: "1000"
        },
        {
          name: "JELLYFIN_PublishedServerUrl",
          value: "http://${var.dns_name}"
        }
      ],
      mountPoints: [
        {
          sourceVolume: "media",
          containerPath: "/media",
          readOnly: false
        }
      ]
    }
  ])

  volume {
    name = "media"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.media.id
      root_directory     = "/media"
      transit_encryption = "ENABLED"
    }
  }
}

# IAM Role for the ECS Task
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "jellyfin-ecs-task-execution-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_execution_role" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_role" {
  name = "jellyfin-ecs-task-execution-role"
  role = aws_iam_role.ecs_task_execution_role.id
  policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}