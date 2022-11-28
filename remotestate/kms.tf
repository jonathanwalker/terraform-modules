data "aws_caller_identity" "current" {}

locals {
    # Convert role/role-name and user/user-name to arn
    kms_key_admins = [for admin in var.kms_key_admins : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:${admin}"]
    kms_key_users = [for user in var.kms_key_users : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:${user}"]
}

data "aws_iam_policy_document" "key_policy" {
    statement {
        sid         = "AllowRootAccess"
        actions     = ["kms:*"]
        resources   = ["*"]
        principals {
            type        = "AWS"
            identifiers = ["arn::aws::iam::${data.aws_caller_identity.current.account_id}:root"]
        }
        condition {
            test        = "StringEquals"
            variable    = "aws:principaltype"
            values      = ["Account"]
        }
    }

    statement {
        sid         = "AllowGeneralAcess"
        actions     = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
        ]
        resources   = ["*"]
        principals {
            type        = "AWS"
            identifiers = local.kms_key_users
        }
    }

    statement {
        sid         = "AllowAdmins"
        actions     = [
            "kms:Describe*",
            "kms:Get*",
            "kms:List*",
            "kms:RevokeGrant",
            "kms:Disable*",
            "kms:Enable*",
            "kms:Put*",
            "kms:Create*",
            "kms:Update*",
            "kms:Delete*",
            "kms:TagResource",
            "kms:UntagResource",
            "kms:ScheduleKeyDeletion",
            "kms:CancelKeyDeletion"
        ]
        resources   = ["*"]
        principals {
            type        = "AWS"
            identifiers = local.kms_key_admins
        }
    }
}

resource "aws_kms_key" "kms_key" {
    name        = "terraform-state-kms-key"
    description = "Key for the terraform state"

    deletion_window_in_days = "14"
    enable_key_rotation     = true
    policy                  = data.aws_iam_policy_document.key_policy.json

    tags                    = var.tags
}

resource "aws_kms_alias" "kms_key_alias" {
    name          = "alias/terraform-state-kms-key"
    target_key_id = aws_kms_key.kms_key.key_id
}