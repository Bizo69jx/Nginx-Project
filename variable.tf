variable "cidr_vpc" {
    type = string
}
variable "tags_vpc" {
    type = map(string)
}
variable "tags_igw" {
  type = map(string)
}
variable "cidr_subnets" {
    type = list(string)
}
variable "az" {
  type = list(string)
}
variable "tags_sub1" {
  type = map(string)
}
variable "cidr_rt" {
  type = string
}
variable "tags_rt" {
  type = map(string)
}
variable "tags_sub2" {
  type = map(string)
}
variable "cidr_sg" {
  type = list(string)
}
variable "ami_instance" {
  type = string
}
variable "ami_instance_type" {
  type = string
}
variable "tags_instance" {
  type = map(string)
}
