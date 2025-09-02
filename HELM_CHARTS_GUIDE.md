# Helm Charts for LetsLearnAKS

This document provides an overview of the Helm charts added to the LetsLearnAKS repository as alternative deployment methods.

## Overview

In addition to the raw Kubernetes YAML manifests, this repository now includes Helm charts for key demos. These charts provide the same functionality with added benefits of parameterization, versioning, and easier management.

## Available Helm Charts

### 1. Simple App Chart (Demo 03: Kubernetes Basics)

**Location**: `03-kubernetes-basics/simple-app-chart/`

**Purpose**: Demonstrates basic Helm concepts alongside Kubernetes fundamentals.

**Features**:
- Simple .NET 9 Web API deployment
- NodePort service for easy access
- Basic health probes and resource limits
- Minimal configuration for learning purposes

**Usage**:
```bash
cd 03-kubernetes-basics
helm install my-simple-app simple-app-chart
```

### 2. Container Demo App Chart (Demo 07: Basic Deployment)

**Location**: `07-basic-deployment/containerdemoapp-chart/`

**Purpose**: Production-ready deployment with comprehensive features.

**Features**:
- Configurable replica count and deployment strategy
- Horizontal Pod Autoscaler (HPA) with CPU and memory metrics
- Comprehensive health probes (liveness, readiness, startup)
- Resource requests and limits
- Multi-port service configuration
- Environment-specific customization

**Usage**:
```bash
cd 07-basic-deployment
helm install my-app containerdemoapp-chart --namespace demo-apps --create-namespace
```

### 3. Second App Chart (Demo 08: Ingress Controller)

**Location**: `08-ingress-controller/second-app-chart/`

**Purpose**: Simple NGINX application for ingress demonstrations.

**Features**:
- Lightweight NGINX deployment
- ClusterIP service
- Environment variable configuration
- Minimal resource requirements

**Usage**:
```bash
cd 08-ingress-controller
helm install second-app second-app-chart --namespace demo-apps --create-namespace
```

## Chart Comparison

| Feature | Simple App Chart | Container Demo App Chart | Second App Chart |
|---------|------------------|--------------------------|-------------------|
| **Complexity** | Basic | Advanced | Basic |
| **Target Use** | Learning | Production | Demo Support |
| **Autoscaling** | No | Yes (HPA) | No |
| **Health Probes** | Basic | Comprehensive | Basic |
| **Resource Management** | Minimal | Full | Minimal |
| **Customization** | Limited | Extensive | Limited |

## Installation Prerequisites

```bash
# Install Helm 3.x
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

## Common Usage Patterns

### Development Environment

```bash
# Quick deployment for testing
helm install test-app simple-app-chart

# Port forward to access
kubectl port-forward service/test-app-simple-app-chart 8080:80
curl http://localhost:8080/health
```

### Production Environment

```bash
# Production deployment with custom values
helm install prod-app containerdemoapp-chart \
  --namespace production \
  --create-namespace \
  --set replicaCount=5 \
  --set image.tag=v2.0.0 \
  --set resources.requests.memory=256Mi \
  --set autoscaling.maxReplicas=20
```

### Multi-Environment Deployment

```yaml
# production-values.yaml
replicaCount: 5
image:
  tag: v2.0.0
resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
autoscaling:
  maxReplicas: 20
```

```bash
# Deploy with environment-specific values
helm install prod-app containerdemoapp-chart -f production-values.yaml -n production
helm install staging-app containerdemoapp-chart -f staging-values.yaml -n staging
```

## Chart Management

### Upgrading Charts

```bash
# Upgrade with new values
helm upgrade my-app containerdemoapp-chart --set replicaCount=10

# Upgrade with new image version
helm upgrade my-app containerdemoapp-chart --set image.tag=v2.1.0
```

### Rollback

```bash
# Check release history
helm history my-app

# Rollback to previous version
helm rollback my-app 1
```

### Cleanup

```bash
# Uninstall release
helm uninstall my-app

# List all releases
helm list --all-namespaces
```

## Testing Charts

### Template Rendering

```bash
# Generate YAML without installing
helm template my-app containerdemoapp-chart

# Debug template rendering
helm template my-app containerdemoapp-chart --debug
```

### Dry Run

```bash
# Simulate installation
helm install my-app containerdemoapp-chart --dry-run --debug
```

### Chart Testing

```bash
# Run chart tests
helm test my-app
```

## Best Practices

### Development Workflow

1. **Start with Raw YAML**: Understand Kubernetes concepts first
2. **Learn Helm Basics**: Use simple-app-chart to understand templating
3. **Production Deployment**: Use containerdemoapp-chart for real applications
4. **Customize Gradually**: Start with default values, customize as needed

### Production Considerations

1. **Use Values Files**: Don't rely on command-line --set for production
2. **Version Everything**: Pin image tags and chart versions
3. **Environment Separation**: Use different namespaces/clusters
4. **Test First**: Always test in staging before production
5. **Monitor Deployments**: Check rollout status and metrics

## Integration with Original Demos

### Demo 03: Kubernetes Basics

The original demo uses raw YAML to teach Kubernetes concepts. The Helm chart provides an alternative approach after understanding the basics:

```bash
# Original approach (recommended for learning)
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml

# Helm approach (after understanding basics)
helm install my-app simple-app-chart
```

### Demo 07: Basic Deployment

The original demo covers various deployment strategies with raw YAML. The Helm chart provides a production-ready package:

```bash
# Original approach (great for understanding)
kubectl apply -f basic-deployment.yaml
kubectl apply -f basic-service.yaml
kubectl apply -f hpa.yaml

# Helm approach (great for production)
helm install my-app containerdemoapp-chart
```

### Demo 08: Ingress Controller

The original demo shows manual deployment of multiple apps. Helm charts can simplify the process:

```bash
# Original approach
kubectl apply -f second-app-deployment.yaml
kubectl apply -f path-based-ingress.yaml

# Helm approach
helm install main-app containerdemoapp-chart -n demo-apps --create-namespace
helm install second-app second-app-chart -n demo-apps
kubectl apply -f path-based-ingress.yaml  # Ingress still manual for learning
```

## Learning Resources

- **Helm Documentation**: [https://helm.sh/docs/](https://helm.sh/docs/)
- **Chart Development Guide**: [https://helm.sh/docs/chart_template_guide/](https://helm.sh/docs/chart_template_guide/)
- **Best Practices**: [https://helm.sh/docs/chart_best_practices/](https://helm.sh/docs/chart_best_practices/)

## Troubleshooting

### Common Issues

1. **Chart Not Found**: Make sure you're in the correct directory
2. **Template Errors**: Use `helm template` to debug before installing
3. **Resource Conflicts**: Check if resources already exist
4. **Image Pull Errors**: Verify image names and registry access

### Debugging Commands

```bash
# Check chart syntax
helm lint my-chart

# Debug template rendering
helm template my-release my-chart --debug

# Check release status
helm status my-release

# Get release values
helm get values my-release
```

This Helm integration provides users with both learning (raw YAML) and production (Helm charts) deployment approaches, making the repository suitable for various use cases and skill levels.