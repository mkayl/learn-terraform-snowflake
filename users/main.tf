terraform {
  required_providers {
    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.18"
    }
  }
}

resource snowflake_user USERS {
  for_each = var.user_map

  login_name   = each.key
  name         = each.key
  display_name = "${each.value.first_name} ${each.value.last_name}"
  first_name = each.value.first_name
  last_name = each.value.last_name
  email = each.value.email

  default_warehouse = lookup(each.value, "default_warehouse", "COMPUTE_WH")
  default_role = lookup(each.value, "default_role", "PUBLIC")
}

output USERS {
  value = snowflake_user.USERS
}
