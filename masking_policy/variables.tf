variable "name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "schema_name" {
  type = string
}

variable "data_type" {
  type = string
}

variable "masking_expression" {
  type = string
}

variable "masking_grants" {
  type = map(any)
}
