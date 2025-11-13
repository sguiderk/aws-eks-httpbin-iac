# Httpbin Application

This directory contains the core httpbin application manifests.

## Files

- **httpbin-deployment.yaml** - Deployment with 1 replica of kennethreitz/httpbin
- **httpbin-service.yaml** - ClusterIP service exposing port 80

## Deploy

```bash
kubectl apply -f httpbin-deployment.yaml
kubectl apply -f httpbin-service.yaml
```

Or apply the entire directory:
```bash
kubectl apply -f .
```

## Verify

```bash
# Check pod status
kubectl get pods -l app=httpbin

# Check service
kubectl get svc httpbin

# Test from within cluster
kubectl run test-curl --rm -i --image=curlimages/curl -- \
  curl http://httpbin.default.svc.cluster.local/get
```

## Service Details

- **Name**: `httpbin`
- **Namespace**: `default`
- **Type**: `ClusterIP`
- **Port**: 80
- **Target Port**: 80
- **Selector**: `app: httpbin`

This service is not directly accessible from outside the cluster. Access is provided via ingress controllers.
