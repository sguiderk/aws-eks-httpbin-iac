output "instance_id" { value = aws_instance.bastion.id }
output "security_group_id" { value = aws_security_group.bastion_sg.id }
output "instance_profile_name" { value = aws_iam_instance_profile.ssm_profile.name }
output "role_arn" { value = aws_iam_role.ssm_role.arn }
