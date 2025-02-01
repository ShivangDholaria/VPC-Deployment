variable "cidr-block" {
    default             = "10.0.0.0/16"
    description         = "CIDR block for VPC"
}

variable "ami-id" {
  default = "ami-04b4f1a9cf54c11d0"
  description = "Amazon Linux AMI ID"
}