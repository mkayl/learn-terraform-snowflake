variable "warehouse_name" {
  type = string
}

variable "warehouse_comment" {
  type = string
}

variable "warehouse_size" {
  type = string
  default = "XSMALL"
}

variable "auto_suspend" {
  type = number
  default = 60
}

variable "role_grants" {
  type = map(any)
}

variable "with_grant_option" {
  type = bool
  default = false
}
