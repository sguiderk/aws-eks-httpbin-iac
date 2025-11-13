# Kubernetes Manifests

This directory contains all Kubernetes manifests for the httpbin deployment with dual ingress controllers (public and private).

## Directory Structure

```
k8s/
├── 01-application/          # Httpbin application deployment
│   ├── httpbin-deployment.yaml
│   └── httpbin-service.yaml
│
├── 02-ingress-public/       # Public ingress (internet-facing)
│   ├── ingress-controller.yaml
│   ├── ingress-public.yaml
│   └── rbac/
│       └── ingress-nginx-rbac.yaml
│
├── 03-ingress-private/      # Private ingress (VPC-only)
│   ├── ingress-controller-internal.yaml
│   ├── ingress-private.yaml
│   └── rbac/
│       ├── internal-ingress-rbac.yaml
│       ├── role-bindings.yaml
│       └── roles.yaml
│
└── examples/                # Example configurations
    └── ingress-public-with-post.yaml.example
```

## Deployment Order

Deploy in the following order:

### 1. Application (Required)
```bash
kubectl apply -f 01-application/
```
Deploys the httpbin application and service.

### 2. Public Ingress Controller (Required for /get endpoint)
```bash
kubectl apply -f 02-ingress-public/
```
Creates:
- External Network Load Balancer (internet-facing)
- NGINX Ingress Controller with `nginx` IngressClass
- Ingress rule routing `/get` to httpbin

### 3. Private Ingress Controller (Required for /post endpoint)
```bash
kubectl apply -f 03-ingress-private/
```
Creates:
- Internal Network Load Balancer (VPC-only)
- NGINX Ingress Controller with `nginx-internal` IngressClass
- RBAC permissions for the internal controller
- Ingress rule routing `/post` to httpbin

## Architecture

### Public Access Pattern
```
Internet → Public NLB → Public Ingress Controller → /get → httpbin
```

### Private Access Pattern
```
VPC/Cluster → Internal NLB → Private Ingress Controller → /post → httpbin
```

## Endpoints

| Endpoint | Access Level | Load Balancer Type | IngressClass |
|----------|--------------|-------------------|--------------|
| `/get`   | Public (Internet) | External NLB | `nginx` |
| `/post`  | Private (VPC only) | Internal NLB | `nginx-internal` |

## Testing

After deployment, get the load balancer DNS names:

```bash
# Public load balancer
kubectl get svc ingress-nginx-controller -n ingress-nginx

# Private load balancer
kubectl get svc ingress-nginx-controller-internal -n ingress-nginx-internal
```

Test public endpoint:
```bash
curl http://<PUBLIC-LB-DNS>/get
```

Test private endpoint (from within cluster):
```bash
kubectl run test-curl --rm -i --image=curlimages/curl -- \
  curl http://<PRIVATE-LB-DNS>/post -X POST -d "test=data"
```

## Customization

### Expose Additional Public Endpoints
Edit `02-ingress-public/ingress-public.yaml` and add paths:
```yaml
paths:
- path: /get
  pathType: Prefix
  backend:
    service:
      name: httpbin
      port:
        number: 80
- path: /status/.*  # Add new path
  pathType: Prefix
  backend:
    service:
      name: httpbin
      port:
        number: 80
```

### Expose Additional Private Endpoints
Edit `03-ingress-private/ingress-private.yaml` similarly.

## Clean Up

To remove all resources:
```bash
kubectl delete -f 03-ingress-private/
kubectl delete -f 02-ingress-public/
kubectl delete -f 01-application/
```

## Notes

- The public ingress controller is deployed in the `ingress-nginx` namespace
- The private ingress controller is deployed in the `ingress-nginx-internal` namespace
- Both controllers can coexist and route to the same backend service
- Security is enforced at the load balancer level (external vs internal)
