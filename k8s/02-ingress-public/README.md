# Public Ingress Controller

This directory contains the public-facing NGINX Ingress Controller configuration.

## Files

- **ingress-controller.yaml** - NGINX Ingress Controller deployment with external NLB
- **ingress-public.yaml** - Ingress rule exposing `/get` endpoint
- **rbac/** - RBAC permissions (ServiceAccount, ClusterRole, Role, Bindings)

## Architecture

```
Internet → External NLB → NGINX Ingress → /get → httpbin service
```

## Deploy

```bash
# Apply RBAC first
kubectl apply -f rbac/

# Then deploy controller and ingress
kubectl apply -f ingress-controller.yaml
kubectl apply -f ingress-public.yaml
```

Or apply the entire directory:
```bash
kubectl apply -f .
```

## Components

### Ingress Controller
- **Namespace**: `ingress-nginx` (created automatically)
- **Controller Image**: `registry.k8s.io/ingress-nginx/controller:v1.11.2`
- **Service Type**: `LoadBalancer` with AWS Network Load Balancer
- **IngressClass**: `nginx`
- **Load Balancer**: External (internet-facing)

### Ingress Rules
- **Name**: `httpbin-public`
- **IngressClass**: `nginx`
- **Path**: `/get` (Prefix match)
- **Backend**: `httpbin` service on port 80

## Verify Deployment

```bash
# Check controller pod
kubectl get pods -n ingress-nginx

# Check load balancer service
kubectl get svc ingress-nginx-controller -n ingress-nginx

# Check ingress
kubectl get ingress httpbin-public -n default
```

## Get Load Balancer URL

```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Test

```bash
# Replace <LB-DNS> with the actual load balancer DNS name
curl http://<LB-DNS>/get
```

Expected response:
```json
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Host": "<LB-DNS>",
    "User-Agent": "curl/..."
  },
  "origin": "x.x.x.x",
  "url": "http://<LB-DNS>/get"
}
```

## Customization

### Add More Public Endpoints

Edit `ingress-public.yaml`:

```yaml
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /get
        pathType: Prefix
        backend:
          service:
            name: httpbin
            port:
              number: 80
      - path: /status/.*    # Add new path
        pathType: Prefix
        backend:
          service:
            name: httpbin
            port:
              number: 80
```

Apply changes:
```bash
kubectl apply -f ingress-public.yaml
```

## Security Notes

- This ingress is **publicly accessible** from the internet
- Only expose endpoints that are meant for public consumption
- Consider adding authentication, rate limiting, or WAF for production use
- The `/post` endpoint is intentionally **NOT** exposed here (it's in the private ingress)
