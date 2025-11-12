# RBAC for Private Ingress Controller

This directory contains all Role-Based Access Control (RBAC) resources for the private/internal NGINX ingress controller.

## Files

- **internal-ingress-rbac.yaml** - Main RBAC configuration including:
  - ClusterRole: `ingress-nginx-internal`
  - ClusterRoleBinding: Binds ClusterRole to ServiceAccount
  - Role: `ingress-nginx-internal` (namespace-specific)
  - RoleBinding: Binds Role to ServiceAccount

- **role-bindings.yaml** - Additional role bindings (if needed)
- **roles.yaml** - Additional custom roles (if needed)

## Deploy

```bash
kubectl apply -f .
```

Or individually:
```bash
kubectl apply -f internal-ingress-rbac.yaml
kubectl apply -f role-bindings.yaml
kubectl apply -f roles.yaml
```

## Permissions Summary

### ClusterRole Permissions
- Read access to: configmaps, endpoints, nodes, pods, secrets, namespaces
- Read/write access to: services, ingresses, ingress status, ingressclasses
- Create/patch access to: events
- Read access to: endpointslices, leases

### Role Permissions (namespace: ingress-nginx-internal)
- Get namespace information
- Read/watch: configmaps, pods, secrets, endpoints, services, ingresses
- Update ingress status
- Manage leases for leader election (`ingress-nginx-leader-internal`)
- Create/patch events
- Pod get/list/watch for health checks

## Security Notes

- The ServiceAccount `ingress-nginx-internal` is created in the controller manifest
- Separate from public ingress RBAC to maintain isolation
- ClusterRole name is unique (`ingress-nginx-internal`) to avoid conflicts
- Leases are namespaced to prevent leader election conflicts
