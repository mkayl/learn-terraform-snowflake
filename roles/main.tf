terraform {
  required_providers {
    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.18"
    }
  }
}

resource snowflake_role ROLE {
  name    = var.name
  comment = var.comment
}

output "ROLE" {
  value = snowflake_role.ROLE
}

resource "snowflake_role_grants" "ROLE_GRANTS" {
  role_name = snowflake_role.ROLE.name

  roles = var.role_names

  users = var.user_names
}