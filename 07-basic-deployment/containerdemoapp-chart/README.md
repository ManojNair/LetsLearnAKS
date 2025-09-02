# Container Demo App Helm Chart

This Helm chart deploys the Container Demo App (.NET 9 Web API) to Kubernetes, providing an alternative to the raw YAML manifests in Demo 07.

## Overview

This chart creates:
- Deployment with configurable replicas and rolling update strategy
- Service with HTTP and HTTPS ports
- HorizontalPodAutoscaler for automatic scaling
- ServiceAccount with configurable permissions

## Prerequisites

- Kubernetes cluster (AKS recommended)
- Helm 3.x installed
- Container image available (containerdemoapp:v1)

## Installation

### Basic Installation

```bash
# Navigate to the demo directory
cd 07-basic-deployment

# Install the chart
helm install my-app containerdemoapp-chart

# Install in a specific namespace
helm install my-app containerdemoapp-chart --namespace demo-apps --create-namespace
```

### Custom Values Installation

```bash
# Install with custom replica count
helm install my-app containerdemoapp-chart --set replicaCount=5

# Install with custom image
helm install my-app containerdemoapp-chart \
  --set image.repository=your-registry/containerdemoapp \
  --set image.tag=v2

# Install with autoscaling disabled
helm install my-app containerdemoapp-chart --set autoscaling.enabled=false
```

### Using Values File

Create a custom values file:

```yaml
# custom-values.yaml
replicaCount: 5
image:
  repository: your-registry/containerdemoapp
  tag: v2
autoscaling:
  enabled: false
resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
  limits:
    memory: "512Mi"
    cpu: "1000m"
```

Install with custom values:

```bash
helm install my-app containerdemoapp-chart -f custom-values.yaml
```

## Configuration

The following table lists the configurable parameters and their default values:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `3` |
| `image.repository` | Image repository | `containerdemoapp` |
| `image.tag` | Image tag | `v1` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Service type | `ClusterIP` |
| `service.ports` | Service ports configuration | See values.yaml |
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `resources.requests.memory` | Memory request | `128Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.limits.memory` | Memory limit | `256Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |

## Usage Examples

### Port Forwarding

```bash
# Forward local port to service
kubectl port-forward service/my-app-containerdemoapp-chart 8080:80

# Test the application
curl http://localhost:8080/health
curl http://localhost:8080/weatherforecast
```

### Scaling

```bash
# Manual scaling (when autoscaling is disabled)
helm upgrade my-app containerdemoapp-chart --set replicaCount=10

# Check HPA status (when autoscaling is enabled)
kubectl get hpa my-app-containerdemoapp-chart
```

### Monitoring

```bash
# Check deployment status
kubectl get deployment my-app-containerdemoapp-chart

# View pods
kubectl get pods -l app.kubernetes.io/name=containerdemoapp-chart

# Check logs
kubectl logs -l app.kubernetes.io/name=containerdemoapp-chart
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall my-app

# Uninstall from specific namespace
helm uninstall my-app --namespace demo-apps
```

## Comparison with Raw YAML

### Advantages of Helm Chart

1. **Templating**: Reusable with different configurations
2. **Values**: Easy to customize without modifying templates
3. **Packaging**: Single unit for complex applications
4. **Versioning**: Track changes and rollback easily
5. **Dependencies**: Manage chart dependencies
6. **Hooks**: Lifecycle management (pre/post install, upgrade)

### When to Use Helm vs YAML

**Use Helm when:**
- Deploying to multiple environments
- Need parameterization and customization
- Managing complex applications with dependencies
- Want package management and versioning

**Use raw YAML when:**
- Simple, static deployments
- Learning Kubernetes concepts
- Fine-grained control over resources
- CI/CD pipelines with templating tools

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # Check if image exists and is accessible
   docker pull containerdemoapp:v1
   
   # Set correct image in values
   helm upgrade my-app containerdemoapp-chart --set image.repository=your-repo/containerdemoapp
   ```

2. **Resource Limits**
   ```bash
   # Increase resource limits if pods are evicted
   helm upgrade my-app containerdemoapp-chart \
     --set resources.requests.memory=256Mi \
     --set resources.limits.memory=512Mi
   ```

3. **Service Not Accessible**
   ```bash
   # Check service endpoints
   kubectl get endpoints my-app-containerdemoapp-chart
   
   # Verify service configuration
   kubectl describe service my-app-containerdemoapp-chart
   ```

### Debugging

```bash
# Template rendering
helm template my-app containerdemoapp-chart --debug

# Dry run
helm install my-app containerdemoapp-chart --dry-run --debug

# Check values
helm get values my-app
```

## Development

### Testing the Chart

```bash
# Lint the chart
helm lint containerdemoapp-chart

# Run chart tests
helm test my-app

# Template with different values
helm template my-app containerdemoapp-chart -f test-values.yaml
```

### Customizing the Chart

1. Modify templates in `templates/` directory
2. Update default values in `values.yaml`
3. Test changes with `helm template`
4. Package the chart: `helm package containerdemoapp-chart`

## Related Resources

- [Demo 07 README](../README.md) - Raw YAML approach
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Container Demo App Source](../../01-container-fundamentals/ContainerDemoApp/)