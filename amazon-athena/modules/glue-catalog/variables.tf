variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "database_name" {
  description = "Name of the Glue database"
  type        = string
}

variable "database_description" {
  description = "Description of the Glue database"
  type        = string
  default     = ""
}

variable "tables" {
  description = "Map of Glue tables to create"
  type = map(object({
    description   = optional(string, "")
    location      = string
    input_format  = optional(string, "org.apache.hadoop.mapred.TextInputFormat")
    output_format = optional(string, "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat")
    serde_library = optional(string, "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe")
    columns = list(object({
      name = string
      type = string
    }))
    partition_keys = optional(list(object({
      name = string
      type = string
    })), [])
  }))
  default = {}
}
