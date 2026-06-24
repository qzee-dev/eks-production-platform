resource "aws_efs_file_system" "eks" {
  creation_token = "eks"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  # lifecycle_policy {
  #   transition_to_ia = "AFTER_30_DAYS"
  # }
}

resource "aws_efs_mount_target" "eks" {
  for_each = toset(aws_subnet.private[*].id)

  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

