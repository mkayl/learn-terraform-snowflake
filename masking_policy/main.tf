terraform {
  required_providers {
    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.18"
    }
  }
}

resource "snowflake_masking_policy" "MASKING_POLICY" {
  name               = var.name
  database           = var.database_name
  schema             = var.schema_name
  value_data_type    = var.data_type
  masking_expression = var.masking_expression
  return_data_type   = var.data_type
}

resource "snowflake_masking_policy_grant" "MASKING_POLICY_GRANT" {
  for_each = var.masking_grants

  database_name = var.database_name
  schema_name = var.schema_name
  masking_policy_name = snowflake_masking_policy.MASKING_POLICY.name
  privilege = each.key
  roles = each.value
}