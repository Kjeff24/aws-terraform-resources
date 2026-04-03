variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "description" {
  description = "Description of the Glue database"
  type        = string
  default     = "Glue Catalog database for raw data"
}
