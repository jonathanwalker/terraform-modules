resource "aws_efs_file_system" "media" {
  creation_token = "media-filesystem"
  tags = {
    Name = "jellyfin-media-fs"
  }
}

resource "aws_efs_mount_target" "media" {
  file_system_id = aws_efs_file_system.media.id
  subnet_id      = var.private_subnets[0]
  security_groups = [
    aws_security_group.efs.id
  ]
}

resource "aws_security_group" "efs" {
  name        = "jellyfin-media-security-group"
  description = "Allow NFS traffic"

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