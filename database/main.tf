terraform {
  required_providers {
    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.18"
    }
  }
}

resource snowflake_database DATABASE {
  name = var.db_name
  comment = var.db_comment
  data_retention_time_in_days = var.db_data_retention_time_in_days
}

output "DATABASE" {
    value = snowflake_database.DATABASE
}

resource "snowflake_database_grant" "DATABASE_GRANT" {
  for_each = var.db_role_grants
  
  database_name = snowflake_database.DATABASE.name

  privilege = each.key
  roles = each.value
}

resource "snowflake_schema" "SCHEMA" {
    for_each = toset(var.schemas)

    database = snowflake_database.DATABASE.name
    name = each.key
}

output "SCHEMA" {
    value = snowflake_schema.SCHEMA
}

resource "snowflake_schema_grant" "SCHEMA_GRANT" {
  for_each = var.schema_grants
  
  database_name = snowflake_database.DATABASE.name
  schema_name = each.value.schema
  privilege = each.value.privilege
  roles = each.value.roles

  depends_on = [snowflake_schema.SCHEMA]
}
