# Monitoring module: CloudWatch dashboard, alarms, Container Insights, optional SNS

variable "cluster_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alarm_sns_topic_arn" {
  type    = string
  default = ""
}

variable "create_sns_topic" {
  type    = bool
  default = false
}

variable "alarm_email" {
  type    = string
  default = ""
}

# Data sources to discover NLBs created by Kubernetes
# These rely on service tags set by AWSLB Controller/Service annotations
data "aws_lb" "public_nlb" {
  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
}

data "aws_lb" "private_nlb" {
  tags = {
    "kubernetes.io/service-name" = "ingress-nginx-internal/ingress-nginx-controller-internal"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "eks_ingress" {
  dashboard_name = "${var.cluster_name}-ingress-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/NetworkELB", "HealthyHostCount", { stat = "Average", label = "Public NLB Healthy Targets" }],
            [".", "UnHealthyHostCount", { stat = "Average", label = "Public NLB Unhealthy Targets" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Public NLB - Target Health"
          period  = 300
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/NetworkELB", "ProcessedBytes", { stat = "Sum", label = "Processed Bytes" }],
            [".", "ActiveFlowCount", { stat = "Average", label = "Active Connections" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Public NLB - Traffic & Connections"
          period  = 300
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/NetworkELB", "TCP_Target_Reset_Count", { stat = "Sum", label = "Target Resets" }],
            [".", "TCP_ELB_Reset_Count", { stat = "Sum", label = "ELB Resets" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Public NLB - Connection Errors"
          period  = 300
        }
      },
      {
        type = "log"
        properties = {
          query  = <<-EOT
            SOURCE '/aws/containerinsights/${var.cluster_name}/application'
            | fields @timestamp, kubernetes.namespace_name, kubernetes.pod_name, log
            | filter kubernetes.namespace_name = 'ingress-nginx'
            | filter log like /error|warn/i
            | sort @timestamp desc
            | limit 20
          EOT
          region = var.aws_region
          title  = "NGINX Ingress - Recent Errors/Warnings"
        }
      }
    ]
  })
}

# Alarms
resource "aws_cloudwatch_metric_alarm" "public_nlb_unhealthy_targets" {
  alarm_name          = "${var.cluster_name}-public-nlb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Public NLB has unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = split("/", data.aws_lb.public_nlb.arn)[1]
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
}

resource "aws_cloudwatch_metric_alarm" "private_nlb_unhealthy_targets" {
  alarm_name          = "${var.cluster_name}-private-nlb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Private NLB has unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = split("/", data.aws_lb.private_nlb.arn)[1]
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
}

# Container Insights log group (application)
resource "aws_cloudwatch_log_group" "container_insights" {
  name              = "/aws/containerinsights/${var.cluster_name}/application"
  retention_in_days = 7
}

# Optional SNS
resource "aws_sns_topic" "eks_alarms" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.cluster_name}-eks-alarms"
}

resource "aws_sns_topic_subscription" "eks_alarms_email" {
  count     = var.create_sns_topic && var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.eks_alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

output "dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.eks_ingress.dashboard_name}"
}

output "public_alarm_arn" { value = aws_cloudwatch_metric_alarm.public_nlb_unhealthy_targets.arn }
output "private_alarm_arn" { value = aws_cloudwatch_metric_alarm.private_nlb_unhealthy_targets.arn }
