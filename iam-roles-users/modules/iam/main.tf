############################
# Groups and inline policies
############################
resource "aws_iam_group" "this" {
  for_each = var.groups
  name     = each.key
}

# Build and attach inline policies to groups
locals {
  group_policies = merge(
    {
      for gk, gv in var.groups : gk => (
        gv.inline_policies != null ? gv.inline_policies : {}
      )
    }
  )
}

data "aws_iam_policy_document" "group_inline" {
  for_each = length(local.group_policies) > 0 ? merge([
    for gk, policies in local.group_policies : {
      for pk, pv in policies : "${gk}:${pk}" => pv
    }
  ]...) : {}

  dynamic "statement" {
    for_each = each.value.statements
    content {
      effect    = try(statement.value.effect, "Allow")
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_group_policy" "this" {
  for_each = data.aws_iam_policy_document.group_inline
  name     = split(":", each.key)[1]
  group    = aws_iam_group.this[split(":", each.key)[0]].name
  policy   = each.value.json
}

############################
# Users and group memberships
############################
resource "aws_iam_user" "this" {
  for_each = var.users
  name     = each.key
  tags     = each.value.tags
}

resource "aws_iam_user_group_membership" "this" {
  for_each = var.users
  user     = aws_iam_user.this[each.key].name
  groups   = [for g in each.value.groups : aws_iam_group.this[g].name]
}

############################
# Roles, trust policy and inline policies
############################
# Identity helpers
data "aws_caller_identity" "current" {}

# Map role -> list of user ARNs allowed to assume it (based on users[].assumable_roles)
locals {
  role_user_principals = {
    for rk, _ in var.roles : rk => [
      for uk, uv in var.users :
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${uk}"
      if contains(try(uv.assumable_roles, []), rk)
    ]
  }
}
# Trust policy per role
locals {
  role_trust = {
    for rk, rv in var.roles : rk => {
      services   = coalesce(rv.assume_services, [])
      account_id = coalesce(rv.assume_account_ids, [])
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  for_each = var.roles

  # Service principals
  dynamic "statement" {
  for_each = length(each.value.assume_services) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "Service"
  identifiers = each.value.assume_services
      }
    }
  }

  # AWS account principals (as root)
  dynamic "statement" {
  for_each = length(each.value.assume_account_ids) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "AWS"
        identifiers = [for id in each.value.assume_account_ids : "arn:aws:iam::${id}:root"]
      }
    }
  }

  # Specific IAM users from this account
  dynamic "statement" {
    for_each = length(lookup(local.role_user_principals, each.key, [])) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "AWS"
        identifiers = lookup(local.role_user_principals, each.key, [])
      }
    }
  }
}

resource "aws_iam_role" "this" {
  for_each            = var.roles
  name                = each.key
  description         = coalesce(each.value.description, "")
  assume_role_policy  = data.aws_iam_policy_document.assume_role[each.key].json
  max_session_duration = try(each.value.max_session_duration, 3600)
}

# Inline policies for roles
locals {
  role_inline = merge(
    {
      for rk, rv in var.roles : rk => (
        rv.inline_policies != null ? rv.inline_policies : {}
      )
    }
  )
}

data "aws_iam_policy_document" "role_inline" {
  for_each = length(local.role_inline) > 0 ? merge([
    for rk, policies in local.role_inline : {
      for pk, pv in policies : "${rk}:${pk}" => pv
    }
  ]...) : {}

  dynamic "statement" {
    for_each = each.value.statements
    content {
      effect    = try(statement.value.effect, "Allow")
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy" "this" {
  for_each = data.aws_iam_policy_document.role_inline
  name     = split(":", each.key)[1]
  role     = aws_iam_role.this[split(":", each.key)[0]].name
  policy   = each.value.json
}

############################
# Per-user inline policies granting sts:AssumeRole
############################
data "aws_iam_policy_document" "user_assume" {
  for_each = {
    for uk, uv in var.users : uk => uv if length(try(uv.assumable_roles, [])) > 0
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = compact([
      for r in try(each.value.assumable_roles, []) :
      startswith(r, "arn:") ? r : (
        contains(keys(aws_iam_role.this), r) ? aws_iam_role.this[r].arn : null
      )
    ])
  }
}

resource "aws_iam_user_policy" "assume" {
  for_each = data.aws_iam_policy_document.user_assume
  name     = "assume-${each.key}"
  user     = aws_iam_user.this[each.key].name
  policy   = each.value.json
}
