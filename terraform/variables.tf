variable "aws_region" {
  default = "eu-central-1"
}

variable "cluster_name" {
  default = "httpbin-eks"
}

# CloudWatch monitoring variables
variable "create_sns_topic" {
  description = "Create SNS topic for CloudWatch alarms"
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "alarm_sns_topic_arn" {
  description = "Existing SNS topic ARN for CloudWatch alarms (if create_sns_topic is false)"
  type        = string
  default     = ""
}

# Toggle deploying ingress-nginx via Helm (set to true to let Terraform install it)
variable "deploy_ingress_nginx" {
  description = "Whether to deploy ingress-nginx via Helm"
  type        = bool
  default     = false
}