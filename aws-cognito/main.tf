# 🔐 AWS Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name                     = "${var.project_name}-user-pool"
  auto_verified_attributes = var.user_pool_settings.auto_verified_attributes
  username_attributes      = var.user_pool_settings.username_attributes

  password_policy {
    minimum_length                   = var.user_pool_settings.password_policy.min_length
    require_uppercase                = var.user_pool_settings.password_policy.require_uppercase
    require_lowercase                = var.user_pool_settings.password_policy.require_lowercase
    require_numbers                  = var.user_pool_settings.password_policy.require_numbers
    require_symbols                  = var.user_pool_settings.password_policy.require_symbols
    temporary_password_validity_days = var.user_pool_settings.password_policy.temp_validity_days
  }

  dynamic "schema" {
    for_each = var.user_pool_settings.user_pool_schema
    content {
      name                = schema.value.name
      attribute_data_type = schema.value.attribute_data_type
      mutable             = schema.value.mutable
      required            = schema.value.required
    }
  }

  lifecycle {
    ignore_changes = [schema]
  }
}