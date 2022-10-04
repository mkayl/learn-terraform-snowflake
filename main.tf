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
  username = "michael"
  password = "F_DN9be9sK!jqKV4Xb"
  account  = "jo55170.us-east-2.aws"
  role     = "accountadmin"
}

resource snowflake_database TEST_TERRAFORM_DB {
  name = "TEST_TERRAFORM_DB"
  comment = "my first terraform database"
  data_retention_time_in_days = 1
}

resource snowflake_schema ADS {
  database = "TEST_TERRAFORM_DB"
  name = "ADS"
  comment = "A schema for understanding ads thet were run"
  data_retention_days = 1
}

resource snowflake_schema SALES {
  database = "TEST_TERRAFORM_DB"
  name = "SALES"
  comment = "A schema for understanding ads thet were run"
  data_retention_days = 1
}

resource "snowflake_table" "FACEBOOK_ADS" {
  database            = "TEST_TERRAFORM_DB"
  schema              = "ADS"
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
  database = "TEST_TERRAFORM_DB"
  schema   = "ADS"
  name     = "AGG_FACEBOOK_ADS"

  comment = "Aggregated facebook ads by date"

  statement  = <<-SQL
    select ad_date, count(1) AS total from ADS.FACEBOOK_ADS group by ad_date;
SQL
}

resource "snowflake_table" "tbl_employees" {
  database            = "TEST_TERRAFORM_DB"
  schema              = "SALES"
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
  database = "TEST_TERRAFORM_DB"
  schema   = "SALES"
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

  default_warehouse = "wh_xsmall_marketing"
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

resource "snowflake_role_grants" "MARKETING_GRANTS" {
  role_name = "RL_MARKETING"

  roles = [
    "ACCOUNTADMIN"
  ]

  users = [
    "TEST_TERRAFORM_USER_1"
  ]
}

resource snowflake_warehouse_grant "WH_XSMALL_MARKETING_USAGE_GRANT" {
  warehouse_name = "WH_XSMALL_MARKETING"
  privilege      = "USAGE"

  roles = [
    "RL_MARKETING",
  ]

  with_grant_option = false
}

resource snowflake_warehouse_grant "WH_MEDIUM_MARKETING_USAGE_GRANT" {
  warehouse_name = "WH_MEDIUM_MARKETING"
  privilege      = "USAGE"

  roles = [
    "RL_MARKETING",
  ]

  with_grant_option = false
}

resource snowflake_database_grant "TEST_TERRAFORM_DB_GRANT" {
  database_name = "TEST_TERRAFORM_DB"

  privilege = "USAGE"
  roles     = ["RL_MARKETING", "RL_SALES"]

  with_grant_option = false
}

resource snowflake_schema_grant "ADS_USAGE_GRANT" {
  database_name = "TEST_TERRAFORM_DB"
  schema_name   = "ADS"

  privilege = "USAGE"
  roles     = ["RL_MARKETING"]

  with_grant_option = false
}

resource snowflake_table_grant FACEBOOK_ADS_SELECT_GRANT {
  database_name = "TEST_TERRAFORM_DB"
  schema_name   = "ADS"
  table_name    = "FACEBOOK_ADS"

  privilege = "SELECT"
  roles     = ["RL_MARKETING"]

  with_grant_option = false
}

resource snowflake_view_grant AGG_FACEBOOK_ADS_SELECT_GRANT {
  database_name = "TEST_TERRAFORM_DB"
  schema_name   = "ADS"
  view_name     = "AGG_FACEBOOK_ADS"

  privilege = "SELECT"
  roles = [
    "RL_MARKETING"
  ]

  with_grant_option = false
}
