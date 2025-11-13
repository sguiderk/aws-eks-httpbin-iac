# EKS Httpbin Deployment with Terraform

## Overview
This project provisions an AWS EKS cluster using Terraform and deploys the `kennethreitz/httpbin` container with two endpoints:
- `/get`: Publicly accessible via Ingress.
- `/post`: Privately accessible within the cluster.

## Architecture
- **VPC**: Custom VPC with public and private subnets.
- **EKS**: Cluster deployed in private subnets.
- **Ingress**: NGINX Ingress controller used to expose endpoints.
- **SSM Bastion Host**: EC2 instance with SSM access for secure shell.

## Setup Instructions

### Prerequisites
- AWS CLI configured
- Terraform installed
- kubectl installed

### Steps
1. Clone the repo
2. Run `terraform init` and `terraform apply` in the `terraform/` directory
3. Update kubeconfig using Terraform output or AWS CLI
4. Apply Kubernetes manifests:
   ```bash
   kubectl apply -f k8s/
   ```
5. Deploy NGINX Ingress Controller (if not already installed)
6. Access `/get` via public Load Balancer DNS
7. Access `/post` from within the VPC or via bastion host
8. Use AWS SSM to connect to bastion:
   ```bash
   aws ssm start-session --target <instance-id>
   ```

## Notes
- Designed to work within AWS Free Tier limits
- Uses Terraform modules for VPC and EKS
- Ingress controller must be deployed separately

## License
MIT