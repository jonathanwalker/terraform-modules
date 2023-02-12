resource "aws_ecs_task_definition" "jellyfin" {
  family = "jellyfin-media-server"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 4096
  memory = 8192

  container_definitions = jsonencode([
    {
      name: "jellyfin",
      image: "jellyfin/jellyfin:latest",
      memory: 512,
      environment: [
        {"name": "JELLYFIN_PublishedServerUrl", "value": "http://${var.dns_name}"}
      ],
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

