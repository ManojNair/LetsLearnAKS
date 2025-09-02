# Simple App Helm Chart

This is a simple Helm chart for the Container Demo App (.NET 9 Web API) used in the Kubernetes Basics demo. It provides a straightforward alternative to the raw YAML manifests.

## Overview

This chart creates:
- Deployment with 2 replicas
- NodePort Service for external access
- Basic resource limits and health probes

## Prerequisites

- Kubernetes cluster (local or cloud)
- Helm 3.x installed
- Container image available (containerdemoapp:v1)

## Quick Start

### Installation

```bash
# Navigate to the demo directory
cd 03-kubernetes-basics

# Install the chart
helm install my-simple-app simple-app-chart

# Install with custom namespace
helm install my-simple-app simple-app-chart --namespace demo-apps --create-namespace
```

### Access the Application

The chart deploys with NodePort service, so you can access it via any node IP:

```bash
# Get node port
kubectl get service my-simple-app-simple-app-chart

# If using local cluster (Docker Desktop, minikube)
curl http://localhost:30000/health  # Replace 30000 with actual node port
curl http://localhost:30000/weatherforecast

# If using cloud cluster
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
export NODE_PORT=$(kubectl get service my-simple-app-simple-app-chart -o jsonpath='{.spec.ports[0].nodePort}')
curl http://$NODE_IP:$NODE_PORT/health
```

## Configuration

Simple configuration options available:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | `containerdemoapp` |
| `image.tag` | Image tag | `v1` |
| `service.type` | Service type | `NodePort` |

### Customization Examples

```bash
# Change replica count
helm install my-simple-app simple-app-chart --set replicaCount=3

# Use different image
helm install my-simple-app simple-app-chart \
  --set image.repository=your-registry/containerdemoapp \
  --set image.tag=v2

# Use ClusterIP service instead of NodePort
helm install my-simple-app simple-app-chart --set service.type=ClusterIP
```

### Using Values File

Create a custom values file:

```yaml
# my-values.yaml
replicaCount: 3
image:
  repository: your-registry/containerdemoapp
  tag: v2
service:
  type: LoadBalancer
resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
```

Install with custom values:

```bash
helm install my-simple-app simple-app-chart -f my-values.yaml
```

## Testing

```bash
# Check deployment
kubectl get pods -l app.kubernetes.io/name=simple-app-chart

# Test the application
helm test my-simple-app

# Check logs
kubectl logs -l app.kubernetes.io/name=simple-app-chart
```

## Uninstalling

```bash
helm uninstall my-simple-app
```

## Comparison: Helm Chart vs Raw YAML

### Raw YAML Approach (app-deployment.yaml + app-service.yaml)

**Pros:**
- Direct control over resources
- Easy to understand for beginners
- No additional tools required
- Good for learning Kubernetes concepts

**Cons:**
- No parameterization
- Hard to reuse across environments
- Manual management of multiple files

### Helm Chart Approach

**Pros:**
- Parameterized and reusable
- Single command deployment
- Built-in rollback capabilities
- Package management

**Cons:**
- Additional complexity
- Requires learning Helm concepts
- Template syntax can be confusing

## When to Use Each

**Use Raw YAML when:**
- Learning Kubernetes fundamentals
- Simple, one-time deployments
- Full control over exact resource definitions
- Working in environments without Helm

**Use Helm Charts when:**
- Deploying to multiple environments (dev, staging, prod)
- Need parameterization and customization
- Managing complex applications
- Want packaging and versioning capabilities

## Related Resources

- [Demo 03 README](../README.md) - Raw YAML approach
- [Kubernetes Deployment Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Service Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Helm Documentation](https://helm.sh/docs/)

## Example Commands for Learning

```bash
# Compare raw YAML vs Helm template output
kubectl apply -f app-deployment.yaml --dry-run=client -o yaml
helm template simple-app-chart

# See what Helm would create
helm install my-simple-app simple-app-chart --dry-run --debug

# Install both and compare
kubectl apply -f app-deployment.yaml -f app-service.yaml
helm install my-simple-app simple-app-chart

# Check what was created
kubectl get all -l app=containerdemoapp           # Raw YAML resources
kubectl get all -l app.kubernetes.io/name=simple-app-chart  # Helm resources
```

This simple chart demonstrates the basic concepts of Helm while maintaining the straightforward nature of the Kubernetes Basics demo.