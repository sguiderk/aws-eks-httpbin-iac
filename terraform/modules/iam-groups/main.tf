# IAM groups and simple EKS policies

variable "prefix" {
  type    = string
  default = "eks"
}

resource "aws_iam_group" "readonly" { name = "${var.prefix}-readonly" }
resource "aws_iam_group" "developer" { name = "${var.prefix}-developer" }
resource "aws_iam_group" "admin" { name = "${var.prefix}-admin" }

resource "aws_iam_group_policy" "readonly_policy" {
  name  = "${var.prefix}-readonly-policy"
  group = aws_iam_group.readonly.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = ["eks:DescribeCluster", "eks:ListClusters"], Resource = "*" }]
  })
}

resource "aws_iam_group_policy" "developer_policy" {
  name  = "${var.prefix}-developer-policy"
  group = aws_iam_group.developer.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = ["eks:DescribeCluster", "eks:ListClusters", "eks:AccessKubernetesApi"], Resource = "*" }]
  })
}

resource "aws_iam_group_policy" "admin_policy" {
  name  = "${var.prefix}-admin-policy"
  group = aws_iam_group.admin.name
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["eks:*"], Resource = "*" }] })
}

output "group_names" {
  value = {
    readonly  = aws_iam_group.readonly.name
    developer = aws_iam_group.developer.name
    admin     = aws_iam_group.admin.name
  }
}
