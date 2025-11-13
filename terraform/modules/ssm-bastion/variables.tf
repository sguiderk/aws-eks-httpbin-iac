variable "vpc_id" {
	type = string
}

variable "public_subnet_id" {
	type = string
}

variable "instance_type" {
	type    = string
	default = "t3.micro"
}

variable "instance_name" {
	type    = string
	default = "BastionHost"
}

variable "role_name" {
	type    = string
	default = "ssm-instance-role"
}

variable "instance_profile_name" {
	type    = string
	default = "ssm-instance-profile"
}

variable "sg_name" {
	type    = string
	default = "bastion-sg"
}

variable "tags" {
	type    = map(string)
	default = {}
}
