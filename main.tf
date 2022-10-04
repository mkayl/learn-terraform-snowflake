terraform {
  required_providers {
    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.18"
    }
  }
}

provider "snowflake" {
  # Configuration options
  username = var.snowflake_username
  password = var.snowflake_password
  account  = var.snowflake_account
  role     = var.snowflake_role
}

resource snowflake_database TEST_TERRAFORM_DB {
  name = "TEST_TERRAFORM_DB"
  comment = "my first terraform database"
  data_retention_time_in_days = 1
}

resource snowflake_schema ADS {
  database = snowflake_database.TEST_TERRAFORM_DB.name
  name = "ADS"
  comment = "A schema for understanding ads thet were run"
  data_retention_days = 1
}

resource snowflake_schema SALES {
  database = snowflake_database.TEST_TERRAFORM_DB.name
  name = "SALES"
  comment = "A schema for understanding ads thet were run"
  data_retention_days = 1
}

resource "snowflake_table" "FACEBOOK_ADS" {
  database            = snowflake_database.TEST_TERRAFORM_DB.name
  schema              = snowflake_schema.ADS.name
  name                = "FACEBOOK_ADS"
  comment             = "Table to track ads success."
  data_retention_days = 1

  column {
    name     = "ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "AD_NAME"
    type     = "VARCHAR"
    nullable = false
  }

  column {
    name     = "AD_DATE"
    type     = "TIMESTAMP_NTZ(9)"
  }

  column {
    name = "EXTRA"
    type = "VARIANT"
    comment = "extra data"
  }
}

resource snowflake_view AGG_FACEBOOK_ADS {
  database = snowflake_database.TEST_TERRAFORM_DB.name
  schema   = snowflake_schema.ADS.name
  name     = "AGG_FACEBOOK_ADS"

  comment = "Aggregated facebook ads by date"

  statement  = <<-SQL
    select ad_date, count(1) AS total from ADS.FACEBOOK_ADS group by ad_date;
SQL
}

resource "snowflake_table" "TBL_EMPLOYEES" {
  database            = snowflake_database.TEST_TERRAFORM_DB.name
  schema              = snowflake_schema.SALES.name
  name                = "EMPLOYEES"
  comment             = "Table containing all employees."
  data_retention_days = 1

  column {
    name     = "ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "NAME"
    type     = "VARCHAR"
    nullable = false
  }

  column {
    name     = "CURRENT"
    type     = "BOOLEAN"
  }
}

resource snowflake_view CURRENT_EMPLOYEES {
  database = snowflake_database.TEST_TERRAFORM_DB.name
  schema   = snowflake_schema.SALES.name
  name     = "CURRENT_EMPLOYEES"

  comment = "Returns all current employees"

  statement  = <<-SQL
    select * from SALES.EMPLOYEES WHERE "CURRENT" = TRUE;
SQL
}

resource snowflake_database TEST_TERRAFORM_DB_2 {
  name = "TEST_TERRAFORM_DB_2"
  comment = "my first terraform database"
  data_retention_time_in_days = 1
}

resource snowflake_user TEST_TERRAFORM_USER_1 {
  name         = "TEST_TERRAFORM_USER_1"
  login_name   = "TEST_TERRAFORM_USER_1"
  password     = "secret"
  disabled     = false
  display_name = "Snowflake User"

  default_warehouse = snowflake_warehouse.WH_XSMALL_MARKETING.name
  default_role      = "public"
}

resource snowflake_role RL_MARKETING {
  name    = "RL_MARKETING"
  comment = "A role for some marketers"
}

resource snowflake_warehouse WH_XSMALL_MARKETING {
  name           = "WH_XSMALL_MARKETING"
  comment        = "A x-small warehouse for the marketing team."
  warehouse_size = "x-small"
  auto_suspend = 60
}

module WH_SMALL_MARKETING {
  source = "./warehouse"
  warehouse_name = "WH_SMALL_MARKETING"
  warehouse_comment = "Small warehouse for marketers."
  warehouse_size = "SMALL"
  role_grants = {
    "OWNERSHIP" = [snowflake_role.RL_MARKETING.name],
    "USAGE" = [snowflake_role.RL_MARKETING.name]
  }
  with_grant_option = false
}

resource snowflake_warehouse WH_MEDIUM_MARKETING {
  name           = "WH_MEDIUM_MARKETING"
  comment        = "A medium warehouse for the marketing team."
  warehouse_size = "medium"
  auto_suspend = 60
}

resource snowflake_role RL_SALES {
  name    = "RL_SALES"
  comment = "A role for all sales"
}

resource "snowflake_warehouse" WH_XSMALL_SALES {
  name           = "WH_XSMALL_SALES"
  comment        = "A x-small warehouse for the sales team."
  warehouse_size = "x-small"
  auto_suspend = 60
}

resource "snowflake_role_grants" "MARKETING_GRANTS" {
  role_name = snowflake_role.RL_MARKETING.name

  roles = [
    "ACCOUNTADMIN"
  ]

  users = [
    snowflake_user.TEST_TERRAFORM_USER_1.name
  ]
}

resource snowflake_warehouse_grant "WH_XSMALL_MARKETING_USAGE_GRANT" {
  warehouse_name = snowflake_warehouse.WH_XSMALL_MARKETING.name
  privilege      = "USAGE"

  roles = [
    snowflake_role.RL_MARKETING.name,
  ]

  with_grant_option = false
}

resource snowflake_warehouse_grant "WH_MEDIUM_MARKETING_USAGE_GRANT" {
  warehouse_name = snowflake_warehouse.WH_MEDIUM_MARKETING.name
  privilege      = "USAGE"

  roles = [
    snowflake_role.RL_MARKETING.name,
  ]

  with_grant_option = false
}

resource snowflake_database_grant "TEST_TERRAFORM_DB_GRANT" {
  database_name = snowflake_database.TEST_TERRAFORM_DB.name

  privilege = "USAGE"
  roles     = [snowflake_role.RL_MARKETING.name, snowflake_role.RL_SALES.name]

  with_grant_option = false
}

resource snowflake_schema_grant "ADS_USAGE_GRANT" {
  database_name = snowflake_database.TEST_TERRAFORM_DB.name
  schema_name   = snowflake_schema.ADS.name

  privilege = "USAGE"
  roles     = [snowflake_role.RL_MARKETING.name]

  with_grant_option = false
}

resource snowflake_table_grant FACEBOOK_ADS_SELECT_GRANT {
  database_name = snowflake_database.TEST_TERRAFORM_DB.name
  schema_name   = snowflake_schema.ADS.name
  table_name    = snowflake_table.FACEBOOK_ADS.name

  privilege = "SELECT"
  roles     = [snowflake_role.RL_MARKETING.name]

  with_grant_option = false
}

resource snowflake_view_grant AGG_FACEBOOK_ADS_SELECT_GRANT {
  database_name = snowflake_database.TEST_TERRAFORM_DB.name
  schema_name   = snowflake_schema.ADS.name
  view_name     = snowflake_view.AGG_FACEBOOK_ADS.name

  privilege = "SELECT"
  roles = [
    snowflake_role.RL_MARKETING.name
  ]

  with_grant_option = false
}



resource "snowflake_role_grants" "SALES_GRANTS" {
  role_name = snowflake_role.RL_SALES.name

  roles = [
    "ACCOUNTADMIN"
  ]

  users = [
    snowflake_user.TEST_TERRAFORM_USER_1.name
  ]
}

resource snowflake_warehouse_grant "WH_XSMALL_SALES_USAGE_GRANT" {
  warehouse_name = snowflake_warehouse.WH_XSMALL_SALES.name
  privilege      = "USAGE"

  roles = [
    snowflake_role.RL_SALES.name,
  ]

  with_grant_option = false
}

resource snowflake_schema_grant "SCHEMA_SALES_USAGE_GRANT" {
  database_name = snowflake_database.TEST_TERRAFORM_DB.name
  schema_name   = snowflake_schema.SALES.name

  privilege = "USAGE"
  roles     = [snowflake_role.RL_SALES.name]

  with_grant_option = false
}

resource snowflake_table_grant TBL_EMPLOYEES_SELECT_GRANT {
  database_name = snowflake_database.TEST_TERRAFORM_DB.name
  schema_name   = snowflake_schema.SALES.name
  table_name    = snowflake_table.TBL_EMPLOYEES.name

  privilege = "SELECT"
  roles     = [snowflake_role.RL_SALES.name]

  with_grant_option = false
}

resource snowflake_view_grant V_CURRENT_EMPLOYEES_SELECT_GRANT {
  database_name = snowflake_database.TEST_TERRAFORM_DB.name
  schema_name   = snowflake_schema.SALES.name
  view_name     = snowflake_view.CURRENT_EMPLOYEES.name

  privilege = "SELECT"
  roles = [
    snowflake_role.RL_SALES.name
  ]

  with_grant_option = false
}
