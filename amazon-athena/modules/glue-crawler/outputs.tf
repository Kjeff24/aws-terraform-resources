output "crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.data_crawler.name
}

output "crawler_arn" {
  description = "ARN of the Glue crawler"
  value       = aws_glue_crawler.data_crawler.arn
}
