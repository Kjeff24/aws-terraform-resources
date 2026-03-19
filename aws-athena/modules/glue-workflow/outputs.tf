output "workflow_name" {
  description = "Name of the Glue workflow"
  value       = aws_glue_workflow.etl_workflow.name
}

output "workflow_arn" {
  description = "ARN of the Glue workflow"
  value       = aws_glue_workflow.etl_workflow.arn
}
