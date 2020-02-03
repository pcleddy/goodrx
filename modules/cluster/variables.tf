variable "cluster_name" {
  type = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "server_port" {
  type    = number
  default = 8080
}

variable "min_size" {
  default     = 1
  description = "min number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  default     = 1
  description = "max number of EC2 Instances in the ASG"
  type        = number
}
