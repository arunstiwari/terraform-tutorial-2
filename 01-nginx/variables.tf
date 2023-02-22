variable "cidr_block" {
  type = string
  default = "10.0.0.0/16"
}
variable "instance_tenancy" {
  type = string
  default = "default"
}
variable "enable_dns_hostnames" {
  type =  bool
  default = true
}
variable "enable_dns_support" {
  type = bool
  default = true
}
variable "prefix" {
  type = string
  default = "nginx"
}

variable "subnet_cidr_block" {
  type = list(string)
  default = ["10.0.1.0/26","10.0.0.0/28"]
}

variable "lb_name" {
  type = string
  default = "nginx-lb"
}