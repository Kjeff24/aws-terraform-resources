variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "workgroups" {
  description = "Map of Athena workgroups to create"
  type = map(object({
    description                = optional(string, "")
    enforce_workgroup_config   = optional(bool, false)
    publish_cloudwatch_metrics = optional(bool, true)
    result_configuration = object({
      output_location = optional(string, null)
      encryption_configuration = optional(object({
        encryption_option = string
        kms_key           = optional(string, null)
      }), null)
    })
    engine_version = optional(object({
      selected_engine_version = optional(string, "Athena engine version 3")
    }), null)
    state = optional(string, "ENABLED")
  }))
}

variable "query_results_bucket" {
  description = "Name of the S3 bucket for query results"
  type        = string
}
