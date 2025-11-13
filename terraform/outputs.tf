output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.eks.cluster_version
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "bastion_instance_id" {
  description = "SSM bastion instance ID"
  value       = module.ssm_bastion.instance_id
}

output "iam_groups" {
  description = "IAM groups created for EKS access"
  value       = module.iam_groups.group_names
}