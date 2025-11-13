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

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        Internet                         │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ (public traffic)
                        ▼
            ┌───────────────────────┐
            │  External NLB         │
            │  (Public)             │
            └───────────┬───────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │  Public Ingress       │
            │  Controller (nginx)   │
            └───────────┬───────────┘
                        │
                        │ /get only
                        ▼
┌──────────────────────────────────────────────────────────┐
│                      VPC / Cluster                       │
│                                                          │
│   ┌──────────────┐           ┌────────────────────┐    │
│   │ Internal NLB │           │  httpbin Service   │    │
│   │ (Private)    │           │  (ClusterIP)       │    │
│   └──────┬───────┘           └─────────▲──────────┘    │
│          │                              │               │
│          │                              │               │
│          ▼                              │               │
│   ┌──────────────────┐                 │               │
│   │ Private Ingress  │─────────────────┘               │
│   │ Controller       │  /post only                     │
│   │ (nginx-internal) │                                 │
│   └──────────────────┘                                 │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Directory Structure

```
k8s/
├── 01-application/          # Core httpbin app
│   ├── httpbin-deployment.yaml      # App deployment with probes and resource limits
│   ├── httpbin-service.yaml
│   ├── httpbin-hpa.yaml            # Horizontal Pod Autoscaler (1-5 replicas)
│   ├── httpbin-networkpolicy.yaml  # Network security policies
│   ├── httpbin-pdb.yaml            # Pod Disruption Budget
│   └── README.md
│
├── 02-ingress-public/       # Public ingress (internet)
│   ├── ingress-controller.yaml      # Public NGINX with resource limits
│   ├── ingress-public.yaml          # Rate limiting, security headers, TLS ready
│   ├── README.md
│   └── rbac/                        # Separated RBAC resources
│       ├── service-account.yaml
│       ├── cluster-role.yaml
│       ├── cluster-role-binding.yaml
│       ├── role.yaml
│       └── role-binding.yaml
│
├── 03-ingress-private/      # Private ingress (VPC only)
│   ├── ingress-controller-internal.yaml  # Internal NGINX with resource limits
│   ├── ingress-private.yaml
│   ├── README.md
│   └── rbac/                        # Separated RBAC resources
│       ├── service-account.yaml
│       ├── cluster-role.yaml
│       ├── cluster-role-binding.yaml
│       ├── role.yaml
│       ├── role-binding.yaml
│       ├── roles.yaml               # Additional custom roles
│       └── role-bindings.yaml       # Additional bindings
│
├── examples/                # Example configurations
│   ├── ingress-public-with-post.yaml.example
│   └── README.md
│
├── nginx-metrics.yaml       # NGINX metrics exposure (port 10254)
├── setup-basic-auth.ps1     # Optional basic authentication setup
└── generate-tls-certs.ps1   # TLS certificate generation helper

terraform/
├── vpc.tf                   # VPC with public/private subnets
├── eks.tf                   # EKS cluster with managed node groups
├── ssm.tf                   # SSM bastion module integration
├── cloudwatch.tf            # CloudWatch monitoring module integration
├── iam.tf                   # IAM groups module integration
├── ingress-nginx.tf         # Optional Helm-based ingress deployment
├── outputs.tf               # Cluster and resource outputs
├── variables.tf             # Configuration variables
├── provider.tf              # AWS, Kubernetes, Helm providers
└── modules/
    ├── ssm-bastion/         # Bastion host with SSM access
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── monitoring/          # CloudWatch dashboards and alarms
    │   └── main.tf
    └── iam-groups/          # IAM user groups and policies
        └── main.tf

tests/
├── test-simple.ps1          # Quick validation script
```

## Best Practices Implemented

### Security
- **Network Segmentation**: Separate public and private ingress controllers with distinct network load balancers
- **NetworkPolicy**: Restricts traffic to httpbin pods only from ingress controller namespaces
- **RBAC Separation**: Dedicated service accounts, roles, and bindings for each ingress controller
- **Rate Limiting**: Configured on public ingress to prevent abuse (10 req/sec per IP)
- **Security Headers**: Added via ingress annotations (X-Frame-Options, X-Content-Type-Options, etc.)
- **SSM-Only Bastion**: No SSH keys or public SSH access; uses AWS Systems Manager Session Manager
- **IAM Groups**: Separate groups for admin, developer, and readonly access with least-privilege policies
- **TLS Ready**: Ingress configured with TLS termination support (certificates can be added)

### Performance & Reliability
- **Horizontal Pod Autoscaling (HPA)**: Automatically scales httpbin from 1-5 replicas based on CPU (60% target)
- **Pod Disruption Budget (PDB)**: Ensures minimum 1 replica available during voluntary disruptions
- **Resource Limits**: Defined requests and limits for both application and ingress controllers
  - Httpbin: 100m CPU / 128Mi memory requests, 200m CPU / 256Mi limits
  - Ingress controllers: 100m CPU / 90Mi memory requests, 200m CPU / 180Mi limits
- **Health Probes**: Readiness and liveness probes configured for httpbin deployment
- **Multi-AZ Deployment**: EKS nodes span 2 availability zones for high availability
- **Container Insights**: Enabled for cluster-level monitoring and logging

### Observability
- **CloudWatch Dashboard**: Pre-configured dashboard tracking NLB health, traffic, and connection errors
- **CloudWatch Alarms**: Alerts for unhealthy targets on both public and private NLBs
- **NGINX Metrics**: Exposed on port 10254 for scraping by monitoring tools
- **Application Logs**: Centralized in CloudWatch Logs with 7-day retention
- **Terraform Outputs**: Clear outputs for bastion ID, LB hostnames, dashboard URLs, and kubeconfig commands

### Infrastructure as Code
- **Modular Terraform**: Separated concerns into reusable local modules (ssm-bastion, monitoring, iam-groups)
- **Variable-Driven**: Configurable via `variables.tf` for region, alarm settings, and feature toggles
- **State Management**: Terraform state tracked with proper dependency management
- **Version Pinning**: Provider versions explicitly specified for reproducibility
- **Automated Testing**: Comprehensive PowerShell test suite validates all deployment scenarios

### Cost Optimization
- **Single NAT Gateway**: Shared across availability zones to minimize NAT costs
- **Right-Sized Instances**: t3.micro bastion and t3.medium EKS nodes (Free Tier eligible)
- **Spot Instances Ready**: EKS module supports spot instances for cost savings
- **Log Retention**: CloudWatch logs retained for only 7 days to reduce storage costs
- **Optional Features**: Helm ingress deployment can be toggled off to use YAML manifests

## Testing

The project includes a comprehensive test suite in the `tests/` directory:

```bash
# Quick validation
powershell -ExecutionPolicy Bypass -File .\tests\test-simple.ps1


## Monitoring & Alerts

Access the CloudWatch dashboard:
```bash
terraform output cloudwatch_dashboard_url
```

The dashboard includes:
- NLB healthy/unhealthy target counts
- Network traffic and active connections
- TCP connection errors and resets
- Recent NGINX ingress errors/warnings from logs

Alarms are configured to trigger when unhealthy targets are detected on either NLB.

## License
MIT