# Demo 03: Kubernetes Fundamentals

## Overview
This demo introduces Kubernetes fundamentals and sets up a local Kubernetes cluster using Docker Desktop. You'll learn the core concepts and create your first deployment.

## Learning Objectives
- Understand Kubernetes architecture and components
- Set up a local Kubernetes cluster
- Learn basic Kubernetes concepts (Pods, Deployments, Services)
- Deploy and manage applications on Kubernetes

## Prerequisites
- Docker Desktop with Kubernetes enabled
- kubectl CLI tool
- Basic understanding of containers (from Demo 01)

## Step 1: Understanding Kubernetes Architecture

### Kubernetes Components

#### Control Plane Components:
1. **API Server**: Central communication hub
2. **etcd**: Distributed key-value store for cluster data
3. **Scheduler**: Assigns Pods to nodes
4. **Controller Manager**: Runs controller processes

#### Node Components:
1. **kubelet**: Primary node agent
2. **kube-proxy**: Network proxy
3. **Container Runtime**: Docker, containerd, etc.

### Kubernetes Objects:
- **Pods**: Smallest deployable units
- **Deployments**: Manage Pod replicas
- **Services**: Expose Pods to network
- **ConfigMaps/Secrets**: Configuration management
- **Namespaces**: Virtual clusters

## Step 2: Setting Up Local Kubernetes

### Enable Kubernetes in Docker Desktop

1. Open Docker Desktop
2. Go to Settings → Kubernetes
3. Check "Enable Kubernetes"
4. Click "Apply & Restart"

### Verify Installation

```bash
# Check kubectl version
kubectl version --client

# Check cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes

# Get all namespaces
kubectl get namespaces
```

## Step 3: Understanding Kubernetes Namespaces

Namespaces provide a mechanism for isolating groups of resources within a single cluster.

```bash
# List all namespaces
kubectl get namespaces

# Create a new namespace for our demos
kubectl create namespace demo-apps

# Set the default namespace
kubectl config set-context --current --namespace=demo-apps

# Verify current namespace
kubectl config view --minify --output 'jsonpath={..namespace}'
```

## Step 4: Creating Your First Pod

### Understanding Pods
A Pod is the smallest deployable unit in Kubernetes. It can contain one or more containers.

Create a simple Pod manifest:

```yaml
# simple-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
```

```bash
# Apply the Pod manifest
kubectl apply -f simple-pod.yaml

# Check Pod status
kubectl get pods

# Get detailed information about the Pod
kubectl describe pod nginx-pod

# View Pod logs
kubectl logs nginx-pod
```

## Step 5: Understanding Deployments

Deployments provide declarative updates for Pods and ReplicaSets.

### Why Deployments?
- **Replica Management**: Maintain desired number of replicas
- **Rolling Updates**: Zero-downtime deployments
- **Rollback**: Easy rollback to previous versions
- **Self-healing**: Automatic restart of failed Pods

Create a Deployment manifest:

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

```bash
# Apply the Deployment
kubectl apply -f nginx-deployment.yaml

# Check Deployment status
kubectl get deployments

# Check Pods created by the Deployment
kubectl get pods -l app=nginx

# Get detailed information
kubectl describe deployment nginx-deployment
```

## Step 6: Understanding Services

Services provide stable network endpoints for Pods.

### Service Types:
- **ClusterIP**: Internal cluster access (default)
- **NodePort**: External access via node ports
- **LoadBalancer**: External access via cloud load balancer

Create a Service manifest:

```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: NodePort
```

```bash
# Apply the Service
kubectl apply -f nginx-service.yaml

# Check Service status
kubectl get services

# Get Service details
kubectl describe service nginx-service

# Access the service (get the NodePort)
kubectl get service nginx-service -o jsonpath='{.spec.ports[0].nodePort}'
```

## Step 7: Deploying Our .NET 9 Application

Let's deploy the application from Demo 01 to Kubernetes.

### Step 7.1: Build and Push the Image

```bash
# Navigate to the application directory
cd ../01-container-fundamentals/ContainerDemoApp

# Build the Docker image
docker build -t containerdemoapp:v1 .

# Tag for local registry (if using Docker Desktop)
docker tag containerdemoapp:v1 localhost:5000/containerdemoapp:v1

# Push to local registry (if available)
docker push localhost:5000/containerdemoapp:v1
```

### Step 7.2: Create Kubernetes Manifests

```yaml
# app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: containerdemoapp
  labels:
    app: containerdemoapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: containerdemoapp
  template:
    metadata:
      labels:
        app: containerdemoapp
    spec:
      containers:
      - name: containerdemoapp
        image: containerdemoapp:v1
        ports:
        - containerPort: 8080
        - containerPort: 8081
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
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
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

```yaml
# app-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: containerdemoapp-service
spec:
  selector:
    app: containerdemoapp
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
  - name: https
    protocol: TCP
    port: 443
    targetPort: 8081
  type: NodePort
```

```bash
# Apply the manifests
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
```

## Step 8: Scaling and Updates

### Manual Scaling

```bash
# Scale the deployment to 5 replicas
kubectl scale deployment containerdemoapp --replicas=5

# Check the scaling
kubectl get pods -l app=containerdemoapp

# Scale back down
kubectl scale deployment containerdemoapp --replicas=2
```

### Rolling Update

```bash
# Update the image to a new version
kubectl set image deployment/containerdemoapp containerdemoapp=containerdemoapp:v2

# Watch the rolling update
kubectl rollout status deployment/containerdemoapp

# Check rollout history
kubectl rollout history deployment/containerdemoapp

# Rollback if needed
kubectl rollout undo deployment/containerdemoapp
```

## Step 9: Configuration Management

### ConfigMaps

Create a ConfigMap for application configuration:

```yaml
# app-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  appsettings.json: |
    {
      "Logging": {
        "LogLevel": {
          "Default": "Information",
          "Microsoft.AspNetCore": "Warning"
        }
      },
      "AllowedHosts": "*",
      "ApplicationName": "Container Demo App"
    }
```

### Secrets

Create a Secret for sensitive data:

```yaml
# app-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  # Base64 encoded values
  api-key: YXBpLWtleS1kZW1v # api-key-demo
  connection-string: c2VjcmV0LWNvbm5lY3Rpb24= # secret-connection
```

### Using ConfigMaps and Secrets in Deployments

Update the deployment to use configuration:

```yaml
# app-deployment-with-config.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: containerdemoapp
spec:
  # ... other specs ...
  template:
    spec:
      containers:
      - name: containerdemoapp
        image: containerdemoapp:v1
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: api-key
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
      volumes:
      - name: config-volume
        configMap:
          name: app-config
```

## Step 10: Monitoring and Debugging

### Basic Monitoring Commands

```bash
# Get all resources
kubectl get all

# Get events
kubectl get events --sort-by='.lastTimestamp'

# Describe resources for troubleshooting
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
kubectl describe service <service-name>

# View logs
kubectl logs <pod-name>
kubectl logs -f <pod-name> # Follow logs
kubectl logs <pod-name> --previous # Previous container logs

# Execute commands in containers
kubectl exec -it <pod-name> -- /bin/sh
```

### Resource Monitoring

```bash
# Get resource usage
kubectl top pods
kubectl top nodes

# Get detailed resource information
kubectl describe nodes
```

## Step 11: Cleanup

```bash
# Delete all resources
kubectl delete deployment containerdemoapp
kubectl delete service containerdemoapp-service
kubectl delete deployment nginx-deployment
kubectl delete service nginx-service
kubectl delete pod nginx-pod
kubectl delete configmap app-config
kubectl delete secret app-secret

# Delete namespace
kubectl delete namespace demo-apps

# Or delete everything in the namespace
kubectl delete all --all -n demo-apps
```

## Key Takeaways

1. **Kubernetes provides** a complete container orchestration platform
2. **Pods are the smallest** deployable units in Kubernetes
3. **Deployments manage** Pod replicas and provide rolling updates
4. **Services provide** stable network endpoints for Pods
5. **ConfigMaps and Secrets** manage configuration and sensitive data
6. **Namespaces provide** resource isolation within a cluster

## Next Steps
In the next demo, we'll create an AKS cluster and explore Azure-specific Kubernetes features.

## Troubleshooting

### Common Issues:
1. **Docker Desktop Kubernetes not starting**: Restart Docker Desktop
2. **Image pull errors**: Check image name and registry
3. **Pod stuck in Pending**: Check resource requests and node capacity
4. **Service not accessible**: Check service type and port configuration

### Useful Commands:
```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check events
kubectl get events --sort-by='.lastTimestamp'
``` 