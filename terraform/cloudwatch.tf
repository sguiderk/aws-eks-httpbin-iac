module "monitoring" {
  source              = "./modules/monitoring"
  cluster_name        = var.cluster_name
  aws_region          = var.aws_region
  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  create_sns_topic    = var.create_sns_topic
  alarm_email         = var.alarm_email

  # Ensure NLBs exist before looking them up
  depends_on = [
    helm_release.ingress_nginx
  ]
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch Dashboard"
  value       = module.monitoring.dashboard_url
}

output "public_nlb_alarm_arn" {
  description = "ARN of public NLB unhealthy targets alarm"
  value       = module.monitoring.public_alarm_arn
}

output "private_nlb_alarm_arn" {
  description = "ARN of private NLB unhealthy targets alarm"
  value       = module.monitoring.private_alarm_arn
}
