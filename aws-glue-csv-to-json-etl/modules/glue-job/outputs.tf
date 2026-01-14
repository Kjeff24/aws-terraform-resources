output "job_name" {
  description = "Name of the Glue ETL job"
  value       = aws_glue_job.csv_to_json.name
}

output "job_arn" {
  description = "ARN of the Glue ETL job"
  value       = aws_glue_job.csv_to_json.arn
}

output "workflow_name" {
  description = "Name of the Glue workflow"
  value       = aws_glue_workflow.csv_to_json_workflow.name
}

output "workflow_arn" {
  description = "ARN of the Glue workflow"
  value       = aws_glue_workflow.csv_to_json_workflow.arn
}

output "crawler_trigger_name" {
  description = "Name of the crawler start trigger"
  value       = aws_glue_trigger.crawler_trigger.name
}

output "job_trigger_name" {
  description = "Name of the job start trigger"
  value       = aws_glue_trigger.job_trigger.name
}
