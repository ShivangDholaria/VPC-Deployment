terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.11.0"
        }
    }   
}   


provider "aws" {
    region  = "us-east-1"
    alias   = "east-1"
}

# provider "aws" {
#     region  = "us-east-2"
#     alias   = "east-2"
# }