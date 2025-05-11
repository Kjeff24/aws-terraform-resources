variable "groups" {
  description = "IAM groups and their inline least-privilege policies"
  type = map(object({
    inline_policies = optional(map(object({
      description = optional(string, "Inline policy")
      statements = list(object({
        effect    = optional(string, "Allow")
        actions   = list(string)
        resources = list(string)
      }))
    })), {})
  }))
  default = {}
}

variable "users" {
  description = "IAM users and their group memberships, tags, and assumable roles"
  type = map(object({
    groups          = optional(list(string), [])
    tags            = optional(map(string), {})
    assumable_roles = optional(list(string), []) # role names (from var.roles keys) or full role ARNs
  }))
  default = {}
}

variable "roles" {
  description = "IAM roles with trust relationships and inline least-privilege policies"
  type = map(object({
    description          = optional(string, "")
    assume_services      = optional(list(string), [])
    assume_account_ids   = optional(list(string), [])
    max_session_duration = optional(number, 3600)
    inline_policies = optional(map(object({
      description = optional(string, "Inline policy")
      statements = list(object({
        effect    = optional(string, "Allow")
        actions   = list(string)
        resources = list(string)
      }))
    })), {})
  }))
  default = {}
}
