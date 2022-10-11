variable "db_name" {
  type = string
}

variable "db_comment" {
  type = string
}

variable "db_data_retention_time_in_days" {
  type = number
  default = 1
}

variable "db_role_grants" {
  type = map(any)
}

variable "schemas" {
  type = list(string)
}

variable "schema_grants" {
  type = map(any)
}