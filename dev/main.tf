terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  region  = "us-east-2"
  version = "~> 2.0"
  #profile = "goodrx"
}

module "goodrx_cluster" {
  source = "../modules/cluster"

  cluster_name = var.cluster_name

  instance_type = "t2.micro"
  min_size      = 1
  max_size      = 1
}
