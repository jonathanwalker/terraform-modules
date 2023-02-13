resource "aws_efs_file_system" "media" {
  creation_token = "media-filesystem"
  tags = {
    Name = "jellyfin-media-fs"
  }
}

resource "aws_efs_mount_target" "media" {
  for_each = toset(var.private_subnets)

  file_system_id = aws_efs_file_system.media.id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.efs.id
  ]
}

resource "aws_security_group" "efs" {
  name        = "jellyfin-media-security-group"
  description = "Allow NFS traffic"

  vpc_id = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "media" {
  type = "ingress"

  security_group_id = aws_security_group.efs.id

  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr]
}

resource "aws_efs_access_point" "media" {
  file_system_id = aws_efs_file_system.media.id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    path = "/media"
    creation_info {
      owner_gid = 1000
      owner_uid = 1000
      permissions = "0777"
    }
  }
}
