############################
# 🌍 General Configuration
############################
variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

############################
# 🌐 Networking
############################
variable "private_subnet_ids" {
  description = "IDs of the private subnets for the Aurora subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the Aurora security group"
  type        = string
}

############################
# 🗄️ Aurora Configuration
############################
variable "aurora_config" {
  description = "Aurora cluster configuration. Set serverless_v2_scaling to enable Serverless v2; leave null for provisioned instances."
  type = object({
    engine          = string
    engine_version  = string
    instance_class  = string
    instance_count  = number
    database_name   = string
    master_username = string
    serverless_v2_scaling = optional(object({
      min_capacity = number
      max_capacity = number
    }))
  })
}
