# Example Configurations

This directory contains example Kubernetes manifests for reference.

## Files

### ingress-public-with-post.yaml.example

Shows how to expose the `/post` endpoint publicly (if needed).

**⚠️ Warning**: This configuration makes the `/post` endpoint accessible from the internet. Use only if this is your intended behavior.

**Usage**:
```bash
# Copy and customize
cp ingress-public-with-post.yaml.example ingress-public-with-post.yaml

# Edit as needed
vim ingress-public-with-post.yaml

# Apply
kubectl apply -f ingress-public-with-post.yaml
```

**What it does**:
- Replaces the `httpbin-public` ingress
- Exposes both `/get` and `/post` via the public (external) load balancer
- Routes traffic through the `nginx` IngressClass

**Use cases**:
- Development/testing environments where security is not a concern
- Public APIs that need to accept POST requests
- Webhooks or callback endpoints

## Security Considerations

Before exposing endpoints publicly:

1. **Authentication**: Add authentication to your application
2. **Rate Limiting**: Configure rate limiting in the ingress controller
3. **WAF**: Consider using AWS WAF with your load balancer
4. **HTTPS**: Enable TLS/SSL certificates
5. **Network Policies**: Add Kubernetes network policies for defense in depth

## Converting Private Endpoints to Public

To make any private endpoint public:

1. Copy the path configuration from `03-ingress-private/ingress-private.yaml`
2. Add it to `02-ingress-public/ingress-public.yaml`
3. Apply the changes
4. Remove from private ingress if no longer needed there

Example:
```yaml
# In 02-ingress-public/ingress-public.yaml
spec:
  ingressClassName: nginx  # Use public ingress class
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
      - path: /post  # Now public
        pathType: Prefix
        backend:
          service:
            name: httpbin
            port:
              number: 80
```
