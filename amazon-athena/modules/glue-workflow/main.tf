/*
Glue Workflow Module - ETL Pipeline Orchestration

This module creates AWS Glue Workflow to orchestrate the ETL pipeline:
- Glue Workflow: Orchestrates the ETL pipeline execution
- Workflow Triggers:
  - ON_DEMAND trigger to start the raw data crawler
  - CONDITIONAL trigger to start ETL job after raw crawler succeeds
  - CONDITIONAL trigger to start processed data crawler after ETL job succeeds
*/

# Glue Workflow
resource "aws_glue_workflow" "etl_workflow" {
  name        = "${var.project_name}-workflow"
  description = "Automated ETL workflow: Crawl raw data → Transform → Crawl processed data → Ready for Athena"

  tags = {
    Name = "${var.project_name}-workflow"
  }
}

# Workflow Trigger for Raw Data Crawler
resource "aws_glue_trigger" "raw_crawler_trigger" {
  name          = "${var.project_name}-start-raw-crawler"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.etl_workflow.name

  actions {
    crawler_name = var.raw_crawler_name
  }
}

# Workflow Trigger for ETL Job (runs after raw crawler succeeds)
resource "aws_glue_trigger" "job_trigger" {
  name          = "${var.project_name}-start-job"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.etl_workflow.name

  predicate {
    conditions {
      crawler_name = var.raw_crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = var.job_name
  }

  depends_on = [aws_glue_trigger.raw_crawler_trigger]
}

# Workflow Trigger for Processed Data Crawler (runs after ETL job succeeds)
resource "aws_glue_trigger" "processed_crawler_trigger" {
  name          = "${var.project_name}-start-processed-crawler"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.etl_workflow.name

  predicate {
    conditions {
      job_name = var.job_name
      state    = "SUCCEEDED"
    }
  }

  actions {
    crawler_name = var.processed_crawler_name
  }

  depends_on = [aws_glue_trigger.job_trigger]
}
