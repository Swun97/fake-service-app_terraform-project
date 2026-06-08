
variable "customer_vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "account_vpc_cidr" {
  default = "192.168.0.0/16"
}

variable "statement_vpc_cidr" {
  default = "172.16.0.0/16"
}

variable "instance_type" {
  default = "t3.micro"
}
