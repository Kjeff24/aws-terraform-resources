/*
Athena Workgroup Module

This module creates Athena workgroups with configuration:
- Workgroup settings (encryption, result location, etc.)
- Engine version configuration
- CloudWatch metrics publishing
*/

locals {
  # Default query results location if not specified
  default_result_location = "s3://${var.query_results_bucket}/"
}

resource "aws_athena_workgroup" "workgroups" {
  for_each = var.workgroups

  name        = "${var.project_name}-${each.key}"
  description = each.value.description
  state       = each.value.state

  configuration {
    enforce_workgroup_configuration    = each.value.enforce_workgroup_config
    publish_cloudwatch_metrics_enabled = each.value.publish_cloudwatch_metrics
    result_configuration {
      output_location = each.value.result_configuration.output_location != null ? each.value.result_configuration.output_location : "${local.default_result_location}${each.key}/"

      dynamic "encryption_configuration" {
        for_each = each.value.result_configuration.encryption_configuration != null ? [each.value.result_configuration.encryption_configuration] : []
        content {
          encryption_option = encryption_configuration.value.encryption_option
          kms_key_arn       = encryption_configuration.value.kms_key
        }
      }
    }

    dynamic "engine_version" {
      for_each = each.value.engine_version != null ? [each.value.engine_version] : []
      content {
        selected_engine_version = engine_version.value.selected_engine_version
      }
    }
  }

  tags = {
    Name = "${var.project_name}-athena-workgroup-${each.key}"
  }
}
