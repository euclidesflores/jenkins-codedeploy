terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.60.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.5.0"
    }
  }
}
