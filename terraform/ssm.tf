resource "aws_iam_role" "ssm_role" {
  name = "ssm-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "bastion" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  tags = {
    Name = "BastionHost"
  }
}