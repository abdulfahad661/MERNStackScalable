variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "AZs for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "backend_image" {
  description = "Docker image for ECS backend"
  type        = string
}

# variable "frontend_ami" {
#   description = "AMI ID for frontend EC2 instances"
#   type        = string
# }

variable "db_name" {
  description = "RDS database name"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}