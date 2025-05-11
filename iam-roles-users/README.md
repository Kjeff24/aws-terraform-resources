# IAM: Users, Groups, Roles (Least Privilege)

This stack automates IAM users, groups (with inline policies), and roles (with precise trust + inline policies). It follows least-privilege by default and lets you explicitly declare who can assume which roles.

- Users join groups; groups carry inline permissions you define.
- Roles are created with controlled trust (services, accounts, and/or specific users from this account).
- Users can be allowed to assume specific roles via users["name"].assumable_roles.

## Prerequisites

- Terraform >= 1.4 (1.5+ recommended)
- AWS credentials configured (AWS_PROFILE or env vars)

Note: backend.tf currently points to a shared bucket/key. Consider using a dedicated key like `iam-roles-users/terraform.tfstate` before using remote state.

## Getting started

Quick local validation (no remote state):

```bash
cd iam-roles-users
terraform init -backend=false
terraform validate
terraform plan
```

Apply (local state):

```bash
terraform apply
```

## Variables

The stack exposes three primary inputs.

- `groups` (map)
  - Shape:
    - key: group name
    - value:
      - inline_policies (map) optional
        - key: policy name
        - value:
          - description (string) optional
          - statements (list)
            - effect (string) optional, default "Allow"
            - actions (list of strings)
            - resources (list of ARNs)
- `users` (map)
  - key: username
  - value:
    - groups (list of group names) optional
    - tags (map) optional
    - assumable_roles (list) optional — role names (from `roles` keys) or full role ARNs
- `roles` (map)
  - key: role name
  - value:
    - description (string) optional
    - assume_services (list) optional — e.g., ["ec2.amazonaws.com"]
    - assume_account_ids (list) optional — e.g., ["123456789012"] (roots)
    - max_session_duration (number) optional (seconds)
    - inline_policies (map) optional — same statements schema as groups

### Defaults provided

Out of the box (if you don’t set any variables), the module will create:

- Group `read-only` with an inline policy that grants S3 read-only access to `arn:aws:s3:::example-bucket` and `arn:aws:s3:::example-bucket/*`.
- User `demo` in the `read-only` group, tagged `Purpose=Demo`, with permission to assume the `ec2-reader` role.
- Role `ec2-reader` trusted by the EC2 service with an inline S3 read-only policy for the same bucket.

To change the default bucket, edit `variables.tf` defaults, or override by supplying your own `groups/users/roles` maps in tfvars.

To create nothing by default, explicitly set the variables to empty maps in your tfvars (see examples below).

## How role assumption is wired

- Put a role’s name (from `roles` keys) or a full role ARN into a user’s `assumable_roles` list.
- The module will:
  - Attach an inline policy to that user granting `sts:AssumeRole` to those target roles/ARNs.
  - If the role is created by this module (name matches), it will also amend that role’s trust policy to trust the specific user principal(s).
- For external roles (other accounts), ensure the external role’s trust policy allows this account/user/role to assume it.

## Examples

Minimal: use defaults as-is

```hcl
# terraform.tfvars
# (no content needed) — defaults will create a demo group/user/role
```

Create nothing by default

```hcl
# terraform.tfvars
groups = {}
users  = {}
roles  = {}
```

Custom setup with a user allowed to assume a role

```hcl
# terraform.tfvars

groups = {
  "read-only" = {
    inline_policies = {
      "s3-read-acme" = {
        description = "Read-only access to acme bucket"
        statements = [
          { actions = ["s3:ListBucket"], resources = ["arn:aws:s3:::acme-data"] },
          { actions = ["s3:GetObject"], resources = ["arn:aws:s3:::acme-data/*"] }
        ]
      }
    }
  }
}

users = {
  "alice" = {
    groups          = ["read-only"]
    tags            = { Team = "Analytics" }
    assumable_roles = ["analytics-reader"]
  }
}

roles = {
  "analytics-reader" = {
    description     = "Role for read-only analytics"
    assume_services = ["ec2.amazonaws.com"]
    inline_policies = {
      "s3-read-acme" = {
        statements = [
          { actions = ["s3:ListBucket"], resources = ["arn:aws:s3:::acme-data"] },
          { actions = ["s3:GetObject"], resources = ["arn:aws:s3:::acme-data/*"] }
        ]
      }
    }
  }
}
```

Cross-account role assumption

```hcl
users = {
  "bob" = {
    groups          = []
    assumable_roles = ["arn:aws:iam::222222222222:role/external-readonly"]
  }
}
```

- Ensure account `222222222222` trusts your account/user (e.g., principal `arn:aws:iam::<your-account-id>:user/bob`) in its role trust policy.

## Outputs

- `group_names`: list of created IAM groups
- `user_names`: list of created IAM users
- `role_names`: list of created IAM roles

## Tips

- Least privilege: keep statements as tight as possible (resources, actions).
- MFA/conditions: we can enforce MFA for AssumeRole or constrain sessions (DurationSeconds, SourceIp, aws:PrincipalTag). Ask and we’ll wire policy condition blocks.
- Managed policies: if you need AWS managed policy attachments, we can extend the module with an explicit allowlist.
