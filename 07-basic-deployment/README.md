# Demo 07: Basic Deployment to AKS

## Overview
This demo covers deploying the .NET 9 application to AKS using various deployment strategies. You'll learn about different deployment types, rolling updates, and best practices for production deployments.

## Learning Objectives
- Deploy .NET 9 application to AKS
- Understand different deployment strategies
- Implement rolling updates and rollbacks
- Configure health checks and resource limits
- Monitor application deployment

## Prerequisites
- AKS cluster created (from Demo 04)
- .NET 9 application built and containerized (from Demo 01)
- kubectl configured to connect to AKS cluster

## Step 1: Preparing the Application for AKS

### Build and Push Application Image

```bash
# Navigate to the application directory
cd 01-container-fundamentals/ContainerDemoApp

# Build the application
dotnet build

# Build Docker image
docker build -t containerdemoapp:v1 .

# Tag for Azure Container Registry (if using ACR)
# Replace with your ACR login server
ACR_LOGIN_SERVER="yourregistry.azurecr.io"
docker tag containerdemoapp:v1 $ACR_LOGIN_SERVER/containerdemoapp:v1

# Login to ACR (if using ACR)
az acr login --name yourregistry

# Push to ACR
docker push $ACR_LOGIN_SERVER/containerdemoapp:v1

# Alternative: Use Docker Hub or other registry
docker tag containerdemoapp:v1 yourusername/containerdemoapp:v1
docker push yourusername/containerdemoapp:v1
```

### Create Application Namespace

```bash
# Create namespace for the application
kubectl create namespace demo-apps

# Set default namespace
kubectl config set-context --current --namespace=demo-apps

# Verify namespace
kubectl get namespaces
```

## Step 2: Understanding Deployment Strategies

### Deployment Strategy Types

1. **Rolling Update (Default)**: Gradually replaces old pods with new ones
2. **Recreate**: Deletes all old pods before creating new ones
3. **Blue-Green**: Maintains two identical environments
4. **Canary**: Gradually rolls out to a subset of users

### Rolling Update Strategy
- **maxSurge**: Maximum number of pods above desired replicas
- **maxUnavailable**: Maximum number of pods unavailable during update
- **minReadySeconds**: Minimum seconds before pod is considered ready
- **progressDeadlineSeconds**: Maximum seconds to wait for deployment progress

## Step 3: Creating Basic Deployment

### Create Deployment Manifest

```yaml
# basic-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: containerdemoapp
  namespace: demo-apps
  labels:
    app: containerdemoapp
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: containerdemoapp
  template:
    metadata:
      labels:
        app: containerdemoapp
        version: v1
    spec:
      containers:
      - name: containerdemoapp
        image: containerdemoapp:v1
        ports:
        - name: http
          containerPort: 8080
        - name: https
          containerPort: 8081
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ASPNETCORE_URLS
          value: "http://+:8080;https://+:8081"
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
```

### Apply the Deployment

```bash
# Apply the deployment
kubectl apply -f basic-deployment.yaml

# Check deployment status
kubectl get deployments -n demo-apps

# Check pods
kubectl get pods -n demo-apps

# Check deployment details
kubectl describe deployment containerdemoapp -n demo-apps
```

## Step 4: Creating Service

### Create Service Manifest

```yaml
# basic-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: containerdemoapp-service
  namespace: demo-apps
  labels:
    app: containerdemoapp
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: https
    port: 443
    targetPort: 8081
    protocol: TCP
  selector:
    app: containerdemoapp
```

### Apply the Service

```bash
# Apply the service
kubectl apply -f basic-service.yaml

# Check service status
kubectl get services -n demo-apps

# Get service details
kubectl describe service containerdemoapp-service -n demo-apps

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://containerdemoapp-service/health
```

## Step 5: Testing the Application

### Port Forward to Access Application

```bash
# Port forward to access the application locally
kubectl port-forward service/containerdemoapp-service 8080:80 -n demo-apps

# In another terminal, test the application
curl http://localhost:8080/health
curl http://localhost:8080/weatherforecast
```

### Test from Within Cluster

```bash
# Create a test pod to access the service
kubectl run test-client --image=busybox --rm -it --restart=Never -- sh

# Inside the test pod
wget -qO- http://containerdemoapp-service/health
wget -qO- http://containerdemoapp-service/weatherforecast
exit
```

## Step 6: Rolling Update Deployment

### Update Application Image

```bash
# Build new version
docker build -t containerdemoapp:v2 .

# Tag and push new version
docker tag containerdemoapp:v2 $ACR_LOGIN_SERVER/containerdemoapp:v2
docker push $ACR_LOGIN_SERVER/containerdemoapp:v2

# Update deployment to new version
kubectl set image deployment/containerdemoapp containerdemoapp=containerdemoapp:v2 -n demo-apps

# Watch the rolling update
kubectl rollout status deployment/containerdemoapp -n demo-apps

# Check deployment history
kubectl rollout history deployment/containerdemoapp -n demo-apps
```

### Monitor Rolling Update

```bash
# Watch pods during update
kubectl get pods -n demo-apps -w

# Check deployment status
kubectl describe deployment containerdemoapp -n demo-apps

# Check events
kubectl get events -n demo-apps --sort-by='.lastTimestamp'
```

## Step 7: Rollback Deployment

### Rollback to Previous Version

```bash
# Rollback to previous version
kubectl rollout undo deployment/containerdemoapp -n demo-apps

# Watch rollback progress
kubectl rollout status deployment/containerdemoapp -n demo-apps

# Check rollback history
kubectl rollout history deployment/containerdemoapp -n demo-apps

# Rollback to specific revision
kubectl rollout undo deployment/containerdemoapp --to-revision=1 -n demo-apps
```

## Step 8: Advanced Deployment Strategies

### Blue-Green Deployment

```yaml
# blue-green-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: containerdemoapp-blue
  namespace: demo-apps
  labels:
    app: containerdemoapp
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: containerdemoapp
      version: blue
  template:
    metadata:
      labels:
        app: containerdemoapp
        version: blue
    spec:
      containers:
      - name: containerdemoapp
        image: containerdemoapp:v1
        ports:
        - containerPort: 8080
        env:
        - name: VERSION
          value: "blue"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: containerdemoapp-green
  namespace: demo-apps
  labels:
    app: containerdemoapp
    version: green
spec:
  replicas: 0  # Start with 0 replicas
  selector:
    matchLabels:
      app: containerdemoapp
      version: green
  template:
    metadata:
      labels:
        app: containerdemoapp
        version: green
    spec:
      containers:
      - name: containerdemoapp
        image: containerdemoapp:v2
        ports:
        - containerPort: 8080
        env:
        - name: VERSION
          value: "green"
---
apiVersion: v1
kind: Service
metadata:
  name: containerdemoapp-service
  namespace: demo-apps
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: containerdemoapp
    version: blue  # Initially points to blue
```

### Canary Deployment

```yaml
# canary-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: containerdemoapp-stable
  namespace: demo-apps
  labels:
    app: containerdemoapp
    track: stable
spec:
  replicas: 9  # 90% of traffic
  selector:
    matchLabels:
      app: containerdemoapp
      track: stable
  template:
    metadata:
      labels:
        app: containerdemoapp
        track: stable
    spec:
      containers:
      - name: containerdemoapp
        image: containerdemoapp:v1
        ports:
        - containerPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: containerdemoapp-canary
  namespace: demo-apps
  labels:
    app: containerdemoapp
    track: canary
spec:
  replicas: 1  # 10% of traffic
  selector:
    matchLabels:
      app: containerdemoapp
      track: canary
  template:
    metadata:
      labels:
        app: containerdemoapp
        track: canary
    spec:
      containers:
      - name: containerdemoapp
        image: containerdemoapp:v2
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: containerdemoapp-service
  namespace: demo-apps
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: containerdemoapp  # Routes to both stable and canary
```

## Step 9: Monitoring and Observability

### Check Application Logs

```bash
# Get logs from all pods
kubectl logs -l app=containerdemoapp -n demo-apps

# Follow logs from specific pod
kubectl logs -f <pod-name> -n demo-apps

# Get logs from previous container (if restarted)
kubectl logs <pod-name> --previous -n demo-apps
```

### Monitor Resource Usage

```bash
# Check pod resource usage
kubectl top pods -n demo-apps

# Check node resource usage
kubectl top nodes

# Get detailed pod information
kubectl describe pods -l app=containerdemoapp -n demo-apps
```

### Check Application Health

```bash
# Test health endpoint
kubectl run health-check --image=busybox --rm -it --restart=Never -- wget -qO- http://containerdemoapp-service/health

# Check pod readiness
kubectl get pods -n demo-apps -o wide

# Check service endpoints
kubectl get endpoints containerdemoapp-service -n demo-apps
```

## Step 10: Scaling the Application

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment containerdemoapp --replicas=5 -n demo-apps

# Check scaling status
kubectl get pods -n demo-apps

# Scale down
kubectl scale deployment containerdemoapp --replicas=2 -n demo-apps
```

### Auto Scaling (HPA)

```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: containerdemoapp-hpa
  namespace: demo-apps
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: containerdemoapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

```bash
# Apply HPA
kubectl apply -f hpa.yaml

# Check HPA status
kubectl get hpa -n demo-apps

# Check HPA details
kubectl describe hpa containerdemoapp-hpa -n demo-apps
```

## Step 11: Best Practices

### Deployment Best Practices

1. **Use Rolling Updates**: Ensure zero-downtime deployments
2. **Set Resource Limits**: Prevent resource exhaustion
3. **Configure Health Checks**: Ensure application health
4. **Use Labels**: Organize and select resources
5. **Monitor Deployments**: Track deployment progress

### Application Best Practices

1. **Graceful Shutdown**: Handle SIGTERM signals
2. **Health Endpoints**: Provide /health and /ready endpoints
3. **Logging**: Use structured logging
4. **Configuration**: Use environment variables and ConfigMaps
5. **Security**: Run as non-root user

## Step 12: Cleanup

```bash
# Delete deployments
kubectl delete deployment containerdemoapp -n demo-apps
kubectl delete deployment containerdemoapp-blue -n demo-apps
kubectl delete deployment containerdemoapp-green -n demo-apps
kubectl delete deployment containerdemoapp-stable -n demo-apps
kubectl delete deployment containerdemoapp-canary -n demo-apps

# Delete services
kubectl delete service containerdemoapp-service -n demo-apps

# Delete HPA
kubectl delete hpa containerdemoapp-hpa -n demo-apps

# Delete namespace
kubectl delete namespace demo-apps
```

## Key Takeaways

1. **Deployments provide** declarative updates for applications
2. **Rolling updates ensure** zero-downtime deployments
3. **Health checks are essential** for application reliability
4. **Resource limits prevent** resource exhaustion
5. **Different deployment strategies** serve different use cases
6. **Monitoring and observability** are crucial for production

## Next Steps
In the next demo, we'll set up an NGINX ingress controller for external access and path-based routing.

## Troubleshooting

### Common Issues:
1. **Image pull errors**: Check image name and registry access
2. **Pod not starting**: Check resource requests and node capacity
3. **Health check failures**: Verify health endpoint implementation
4. **Service not accessible**: Check service configuration and selectors

### Useful Commands:
```bash
# Check deployment status
kubectl get deployments -n demo-apps

# Check pod events
kubectl get events -n demo-apps --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs <pod-name> -n demo-apps

# Check service endpoints
kubectl get endpoints -n demo-apps
``` 