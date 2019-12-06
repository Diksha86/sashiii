variable "region" {}
variable "gcp_project" {}
variable "credentials" {}
variable "zone" {}
variable "health-check" {}
variable "target-pool" {}
variable "instance_name" {}
variable "vpc_public" {
         default = "10.0.0.0/24"
}
