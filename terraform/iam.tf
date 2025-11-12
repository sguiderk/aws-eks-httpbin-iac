resource "aws_iam_group" "eks_readonly" {
  name = "eks-readonly"
}

resource "aws_iam_group" "eks_developer" {
  name = "eks-developer"
}

resource "aws_iam_group" "eks_admin" {
  name = "eks-admin"
}

resource "aws_iam_group_policy" "eks_readonly_policy" {
  name  = "eks-readonly-policy"
  group = aws_iam_group.eks_readonly.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy" "eks_developer_policy" {
  name  = "eks-developer-policy"
  group = aws_iam_group.eks_developer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy" "eks_admin_policy" {
  name  = "eks-admin-policy"
  group = aws_iam_group.eks_admin.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      }
    ]
  })
}