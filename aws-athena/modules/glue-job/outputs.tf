output "job_name" {
  description = "Name of the Glue ETL job"
  value       = aws_glue_job.etl_job.name
}

output "job_arn" {
  description = "ARN of the Glue ETL job"
  value       = aws_glue_job.etl_job.arn
}
