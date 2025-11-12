# RBAC for Public Ingress Controller

This directory contains all Role-Based Access Control (RBAC) resources for the public NGINX ingress controller.

## Files

- **ingress-nginx-rbac.yaml** - Complete RBAC configuration including:
  - ServiceAccount: `ingress-nginx`
  - ClusterRole: Cluster-wide permissions for ingress resources
  - ClusterRoleBinding: Binds ClusterRole to ServiceAccount
  - Role: Namespace-specific permissions
  - RoleBinding: Binds Role to ServiceAccount

## Deploy

```bash
kubectl apply -f ingress-nginx-rbac.yaml
```

## Permissions Summary

### ClusterRole Permissions
- Read access to: configmaps, endpoints, nodes, pods, secrets, namespaces, services
- Read/write access to: ingresses, ingress status, ingressclasses
- Create/patch access to: events
- Read access to: endpointslices (for discovery)

### Role Permissions (namespace: ingress-nginx)
- Get namespace information
- Read/watch: configmaps, pods, secrets, endpoints, services, ingresses
- Update ingress status
- Manage leases for leader election
- Create/patch events

## Security Notes

- The ServiceAccount `ingress-nginx` is used by the ingress controller pod
- ClusterRole grants cluster-wide read permissions for service discovery
- Role provides namespace-scoped permissions for managing ingress resources
- No write permissions to secrets or configmaps outside the ingress-nginx namespace
