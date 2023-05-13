variable "aws_region" {
  default = "us-east-2"
}

variable "repository" {
  default = "https://github.com/euclidesflores/fibonacci-app.git"
}

variable "vpc_id" {
  default = "vpc-fff8ae97"
}

variable "subnets" {
  default = [
    "subnet-c91751a1",
    "subnet-4e368a34"
  ]
}

variable "security_groups_ids" {
  default = [
    "sg-3450ee5e"
  ]
}
