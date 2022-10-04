terraform {
  required_providers {
    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.18"
    }
  }
}

resource snowflake_warehouse WAREHOUSE {
  name           = var.warehouse_name
  comment        = var.warehouse_comment
  warehouse_size = var.warehouse_size
  auto_suspend = var.auto_suspend
}

resource "snowflake_warehouse_grant" "WAREHOUSE_GRANT" {
  warehouse_name = snowflake_warehouse.WAREHOUSE.name
  privilege      = "USAGE"

  roles = var.roles

  with_grant_option = var.with_grant_option
}
