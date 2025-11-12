# NGINX Ingress Controller deployment
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.8.3"
  namespace        = "ingress-nginx"
  create_namespace = true

  # AWS-specific configuration for Network Load Balancer
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
    value = "true"
  }

  # Enable ingress class as default
  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  # Resource limits for production
  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "90Mi"
  }

  # Wait for deployment to be ready
  wait    = true
  timeout = 600

  depends_on = [
    module.eks
  ]
}

# Output the Load Balancer hostname
output "ingress_nginx_load_balancer_hostname" {
  description = "The hostname of the ingress-nginx load balancer"
  value       = try(
    data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname,
    "Load balancer hostname not yet available"
  )
}

# Data source to get the ingress-nginx service details
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [
    helm_release.ingress_nginx
  ]
}
