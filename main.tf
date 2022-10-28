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

resource "snowflake_table" "FACEBOOK_ADS" {
  database            = module.TEST_TERRAFORM_DB.DATABASE.name
  schema              = module.TEST_TERRAFORM_DB.SCHEMA["ADS"].name
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
  database            = module.TEST_TERRAFORM_DB.DATABASE.name
  schema              = module.TEST_TERRAFORM_DB.SCHEMA["ADS"].name
  name     = "AGG_FACEBOOK_ADS"

  comment = "Aggregated facebook ads by date"

  statement  = <<-SQL
    select ad_date, count(1) AS total from ADS.FACEBOOK_ADS group by ad_date;
SQL
}

resource "snowflake_table" "TBL_EMPLOYEES" {
  database            = module.TEST_TERRAFORM_DB.DATABASE.name
  schema              = module.TEST_TERRAFORM_DB.SCHEMA["SALES"].name
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
  database = module.TEST_TERRAFORM_DB.DATABASE.name
  schema  = module.TEST_TERRAFORM_DB.SCHEMA["SALES"].name
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
    "OWNERSHIP" = [module.RL_MARKETING.ROLE.name],
    "USAGE" = [module.RL_MARKETING.ROLE.name]
  }
  with_grant_option = false
}

module COMPUTE_WH {
  source = "./warehouse"
  warehouse_name = "COMPUTE_WH"
  warehouse_comment = "Default warehouse."
  warehouse_size = "XSMALL"
  role_grants = {
    "OWNERSHIP" = ["SYSADMIN"],
    "USAGE" = [module.RL_MARKETING.ROLE.name]
  }
}

resource snowflake_warehouse WH_MEDIUM_MARKETING {
  name           = "WH_MEDIUM_MARKETING"
  comment        = "A medium warehouse for the marketing team."
  warehouse_size = "medium"
  auto_suspend = 60
}

resource "snowflake_warehouse" WH_XSMALL_SALES {
  name           = "WH_XSMALL_SALES"
  comment        = "A x-small warehouse for the sales team."
  warehouse_size = "x-small"
  auto_suspend = 60
}

resource snowflake_warehouse_grant "WH_XSMALL_MARKETING_USAGE_GRANT" {
  warehouse_name = snowflake_warehouse.WH_XSMALL_MARKETING.name
  privilege      = "USAGE"

  roles = [
    module.RL_MARKETING.ROLE.name,
  ]

  with_grant_option = false
}

resource snowflake_warehouse_grant "WH_MEDIUM_MARKETING_USAGE_GRANT" {
  warehouse_name = snowflake_warehouse.WH_MEDIUM_MARKETING.name
  privilege      = "USAGE"

  roles = [
    module.RL_MARKETING.ROLE.name,
  ]

  with_grant_option = false
}

resource snowflake_table_grant FACEBOOK_ADS_SELECT_GRANT {
  database_name = module.TEST_TERRAFORM_DB.DATABASE.name
  schema_name = module.TEST_TERRAFORM_DB.SCHEMA["ADS"].name
  table_name    = snowflake_table.FACEBOOK_ADS.name

  privilege = "SELECT"
  roles     = [module.RL_MARKETING.ROLE.name]

  with_grant_option = false
}

resource snowflake_view_grant AGG_FACEBOOK_ADS_SELECT_GRANT {
  database_name = module.TEST_TERRAFORM_DB.DATABASE.name
  schema_name = module.TEST_TERRAFORM_DB.SCHEMA["ADS"].name
  view_name     = snowflake_view.AGG_FACEBOOK_ADS.name

  privilege = "SELECT"
  roles = [
    module.RL_MARKETING.ROLE.name
  ]

  with_grant_option = false
}

resource snowflake_warehouse_grant "WH_XSMALL_SALES_USAGE_GRANT" {
  warehouse_name = snowflake_warehouse.WH_XSMALL_SALES.name
  privilege      = "USAGE"

  roles = [
    module.RL_SALES.ROLE.name,
  ]

  with_grant_option = false
}

resource snowflake_table_grant TBL_EMPLOYEES_SELECT_GRANT {
  database_name = module.TEST_TERRAFORM_DB.DATABASE.name
  schema_name = module.TEST_TERRAFORM_DB.SCHEMA["SALES"].name
  table_name    = snowflake_table.TBL_EMPLOYEES.name

  privilege = "SELECT"
  roles     = [module.RL_SALES.ROLE.name]

  with_grant_option = false
}

resource snowflake_view_grant V_CURRENT_EMPLOYEES_SELECT_GRANT {
  database_name = module.TEST_TERRAFORM_DB.DATABASE.name
  schema_name = module.TEST_TERRAFORM_DB.SCHEMA["SALES"].name
  view_name     = snowflake_view.CURRENT_EMPLOYEES.name

  privilege = "SELECT"
  roles = [
    module.RL_SALES.ROLE.name
  ]

  with_grant_option = false
}

module "ALL_USERS" {
  source = "./users"
  user_map = {
    "TEST_TERRAFORM_USER_1": {"name" = "TEST_TERRAFORM_USER_1", "first_name" = "test_firstname 1", "last_name" = "test_lastname 1", "email" = "user1@snowflake.example", "display_name" = "Snowflake User 1", "default_warehouse": module.WH_SMALL_MARKETING.WAREHOUSE.name, "default_role" = "public"},
    "TEST_TERRAFORM_USER_3": {"name" = "TEST_TERRAFORM_USER_3", "first_name" = "test_firstname 3", "last_name" = "test_lastname 3", "email" = "user3@snowflake.example", "display_name" = "Snowflake User 3", "default_warehouse":  module.WH_SMALL_MARKETING.WAREHOUSE.name, "default_role": "public"},
    "TEST_TERRAFORM_USER_4": {"name" = "TEST_TERRAFORM_USER_4", "first_name" = "test_firstname 4", "last_name" = "test_lastname 4", "email" = "user4@snowflake.example", "display_name" = "Snowflake User 4"},
    "MICHAEL": {"name" = "MICHAEL", "first_name" = "Michael", "last_name" = "Wyss", "email" = "mc.wyss@gmail.com", "display_name" = "Michael Wyss", "default_warehouse":  module.WH_SMALL_MARKETING.WAREHOUSE.name, "default_role": "ACCOUNTADMIN"},
  }
}

module "DB_MARKETING" {
  source = "./database"
  db_name = "DB_MARKETING"
  db_comment = "A database for the marketing team"
  db_data_retention_time_in_days = 1
  db_role_grants = {
    "OWNERSHIP" = [module.RL_MARKETING.ROLE.name],
    "USAGE" = [module.RL_SALES.ROLE.name]
  }
  schemas = ["FACEBOOK", "TWITTER"]

  schema_grants = {
    "FACEBOOK OWNERSHIP": {"schema" = "FACEBOOK", "privilege" = "OWNERSHIP", "roles" = [module.RL_MARKETING.ROLE.name]},
    "FACEBOOK USAGE": {"schema" = "FACEBOOK", "privilege" = "USAGE", "roles" = [module.RL_SALES.ROLE.name]},
    "TWITTER OWNERSHIP": {"schema" = "TWITTER", "privilege" = "OWNERSHIP", "roles" = [module.RL_MARKETING.ROLE.name]},
    "TWITTER USAGE": {"schema" = "TWITTER", "privilege" = "USAGE", "roles" = [module.RL_SALES.ROLE.name]},
    "TWITTER CREATE FUNCTION": {"schema" = "TWITTER", "privilege" = "CREATE FUNCTION", "roles" = [module.RL_SALES.ROLE.name]}
  }
}

module "TEST_TERRAFORM_DB" {
  source = "./database"
  db_name = "TEST_TERRAFORM_DB"
  db_comment = "my first terraform database"
  db_data_retention_time_in_days = 1
  db_role_grants = {
    "USAGE" = [module.RL_MARKETING.ROLE.name, module.RL_SALES.ROLE.name]
  }
  schemas = ["ADS", "SALES"]

  schema_grants = {
    "ADS USAGE": {"schema" = "ADS", "privilege" = "USAGE", "roles" = [module.RL_MARKETING.ROLE.name]},
    "SALES USAGE": {"schema" = "SALES", "privilege" = "USAGE", "roles" = [module.RL_SALES.ROLE.name]},
  }
}

module "RL_MARKETING" {
  source = "./roles"
  name = "RL_MARKETING"
  comment = "a read only role for marketers"
  role_names = ["ACCOUNTADMIN"]
  user_names = [module.ALL_USERS.USERS.TEST_TERRAFORM_USER_1.name]
}

module "RL_SALES" {
  source = "./roles"
  name = "RL_SALES"
  comment = "A role for all sales"
  role_names = ["ACCOUNTADMIN"]
  user_names = [module.ALL_USERS.USERS.TEST_TERRAFORM_USER_1.name]
}

# module "TEST_DB_ADS_AD_NAME_MASK" {
#   source = "./masking_policy"
#   name = "AD_NAME_MASK"
#   database_name = module.TEST_TERRAFORM_DB.DATABASE.name
#   schema_name = module.TEST_TERRAFORM_DB.SCHEMA.ADS.name
#   data_type = "string"
#   masking_expression = "case when is_role_in_session('RL_MARKETING') then val else sha2(val) end"
#   masking_grants = {
#     "OWNERSHIP" = ["ACCOUNTADMIN"],
#     "APPLY" = [module.RL_MARKETING.ROLE.name]
#   }
# }

