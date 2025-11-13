# Private Ingress Controller

This directory contains the private (internal-only) NGINX Ingress Controller configuration.

## Files

- **ingress-controller-internal.yaml** - NGINX Ingress Controller with internal NLB
- **ingress-private.yaml** - Ingress rule exposing `/post` endpoint
- **rbac/** - RBAC permissions for the internal controller

## Architecture

```
VPC/Cluster → Internal NLB → NGINX Ingress (Internal) → /post → httpbin service
```

**Important**: The internal load balancer is **NOT accessible from the internet**. It's only reachable from within the VPC or cluster.

## Deploy

```bash
# Apply RBAC first
kubectl apply -f rbac/

# Then deploy controller and ingress
kubectl apply -f ingress-controller-internal.yaml
kubectl apply -f ingress-private.yaml
```

Or apply the entire directory:
```bash
kubectl apply -f .
```

## Components

### Ingress Controller
- **Namespace**: `ingress-nginx-internal` (created automatically)
- **Controller Image**: `registry.k8s.io/ingress-nginx/controller:v1.11.2`
- **Service Type**: `LoadBalancer` with **internal** AWS Network Load Balancer
- **IngressClass**: `nginx-internal`
- **Load Balancer**: **Internal** (VPC-only, annotation: `service.beta.kubernetes.io/aws-load-balancer-internal: "true"`)

### Ingress Rules
- **Name**: `httpbin-private`
- **IngressClass**: `nginx-internal`
- **Path**: `/post` (Prefix match)
- **Backend**: `httpbin` service on port 80

### RBAC
- **ClusterRole**: `ingress-nginx-internal` - Cluster-wide permissions for ingress resources
- **Role**: `ingress-nginx-internal` - Namespace-specific permissions
- **ServiceAccount**: `ingress-nginx-internal`

## Verify Deployment

```bash
# Check controller pod
kubectl get pods -n ingress-nginx-internal

# Check internal load balancer service
kubectl get svc ingress-nginx-controller-internal -n ingress-nginx-internal

# Check ingress
kubectl get ingress httpbin-private -n default

# Verify LB is internal (Scheme should be "internal")
LB_ARN=$(kubectl get svc ingress-nginx-controller-internal -n ingress-nginx-internal \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | cut -d'-' -f1)
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(DNSName, '$LB_ARN')].Scheme"
```

## Get Internal Load Balancer URL

```bash
kubectl get svc ingress-nginx-controller-internal -n ingress-nginx-internal \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Test

### From Internet (Should FAIL)
```bash
# This should timeout or fail - load balancer is internal only
curl http://<INTERNAL-LB-DNS>/post -X POST -d "test=data" --max-time 10
```

Expected: Connection timeout or DNS resolution failure

### From Within Cluster (Should SUCCEED)
```bash
# Run a test pod inside the cluster
kubectl run test-private --rm -i --image=curlimages/curl -- \
  curl http://<INTERNAL-LB-DNS>/post -X POST -d "field=value"
```

Expected response:
```json
{
  "args": {},
  "data": "",
  "files": {},
  "form": {
    "field": "value"
  },
  "headers": {
    "Content-Type": "application/x-www-form-urlencoded",
    "Host": "<INTERNAL-LB-DNS>",
    ...
  },
  "json": null,
  "origin": "10.0.x.x",
  "url": "http://<INTERNAL-LB-DNS>/post"
}
```

### From EC2 in Same VPC (Should SUCCEED)
If you have an EC2 instance or bastion in the same VPC:
```bash
curl http://<INTERNAL-LB-DNS>/post -X POST -d "test=data"
```

## Customization

### Add More Private Endpoints

Edit `ingress-private.yaml`:

```yaml
spec:
  ingressClassName: nginx-internal
  rules:
  - http:
      paths:
      - path: /post
        pathType: Prefix
        backend:
          service:
            name: httpbin
            port:
              number: 80
      - path: /put    # Add new private endpoint
        pathType: Prefix
        backend:
          service:
            name: httpbin
            port:
              number: 80
```

Apply changes:
```bash
kubectl apply -f ingress-private.yaml
```

## Security Notes

- This ingress is **NOT accessible from the internet**
- Internal load balancer is only reachable from within the VPC
- Use this for sensitive endpoints that should only be accessible internally
- The `/post` endpoint is intentionally kept private to demonstrate secure architecture
- For production, consider additional network policies or service mesh for fine-grained access control

## RBAC Directory

The `rbac/` subdirectory contains:
- `internal-ingress-rbac.yaml` - Permissions specific to the internal ingress controller
- `role-bindings.yaml` - Additional role bindings (if any)
- `roles.yaml` - Additional roles (if any)

These ensure the internal ingress controller has the necessary permissions to watch and update ingress resources.
