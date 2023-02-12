resource "aws_ecs_task_definition" "jellyfin" {
  family = "jellyfin-media-server"

  container_definitions = <<EOF
[
  {
    name: "jellyfin",
    image: "jellyfin/jellyfin:latest",
    memory: 512,
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
]
EOF

  volume {
    name = "media"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.media.id
      root_directory     = "/media"
      transit_encryption = "ENABLED"
      file_system_arn    = aws_efs_file_system.media.arn
    }
  }

  environment {
    name  = "JELLYFIN_PublishedServerUrl"
    value = "http://${var.dns_name}"
  }
}

