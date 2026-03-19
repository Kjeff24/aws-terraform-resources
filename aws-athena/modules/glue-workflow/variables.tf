variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "raw_crawler_name" {
  description = "Name of the Glue crawler for raw data"
  type        = string
}

variable "job_name" {
  description = "Name of the Glue ETL job"
  type        = string
}

variable "processed_crawler_name" {
  description = "Name of the Glue crawler for processed data"
  type        = string
}
