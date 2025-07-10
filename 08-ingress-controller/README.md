# Demo 08: NGINX Ingress Controller with Path-Based Routing

## Overview
This demo covers setting up the NGINX ingress controller on AKS and implementing path-based routing for multiple applications. You'll learn about ingress concepts, NGINX configuration, and advanced routing patterns.

## Learning Objectives
- Understand ingress controllers and their purpose
- Install and configure NGINX ingress controller on AKS
- Implement path-based routing for multiple services
- Configure ingress rules and annotations
- Set up external access to applications

## Prerequisites
- AKS cluster with application deployed (from Demo 07)
- kubectl configured to connect to AKS cluster
- Understanding of Kubernetes services and deployments

## Step 1: Understanding Ingress Controllers

### What is an Ingress Controller?
An ingress controller is a reverse proxy that manages external access to services in a Kubernetes cluster. It provides:
- **Load Balancing**: Distribute traffic across multiple pods
- **SSL Termination**: Handle HTTPS certificates
- **Path-Based Routing**: Route traffic based on URL paths
- **Host-Based Routing**: Route traffic based on domain names

### NGINX Ingress Controller
- **Open Source**: Community-driven development
- **High Performance**: Efficient proxy and load balancer
- **Rich Features**: Advanced routing, SSL, authentication
- **Wide Adoption**: Most popular ingress controller

## Step 2: Installing NGINX Ingress Controller

### Using Helm (Recommended)

```bash
# Add NGINX ingress Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux

# Check installation status
kubectl get pods -n ingress-nginx
kubectl get services -n ingress-nginx
```

### Alternative: Using kubectl

```bash
# Apply NGINX ingress controller manifests
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Check installation
kubectl get pods -n ingress-nginx
```

## Step 3: Understanding Ingress Resources

### Ingress Resource Components
- **Rules**: Define how traffic should be routed
- **Hosts**: Domain names for routing
- **Paths**: URL paths for routing
- **Backend**: Target service and port
- **Annotations**: Configuration options

### Ingress Class
```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
```

## Step 4: Creating Multiple Applications

### Create Second Application

```yaml
# second-app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app
  namespace: demo-apps
  labels:
    app: second-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: second-app
  template:
    metadata:
      labels:
        app: second-app
    spec:
      containers:
      - name: second-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: APP_NAME
          value: "Second Application"
---
apiVersion: v1
kind: Service
metadata:
  name: second-app-service
  namespace: demo-apps
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: second-app
```

```bash
# Apply second application
kubectl apply -f second-app-deployment.yaml

# Verify deployment
kubectl get pods -n demo-apps
kubectl get services -n demo-apps
```

## Step 5: Creating Path-Based Ingress

### Basic Path-Based Routing

```yaml
# path-based-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
  namespace: demo-apps
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: demo.example.com  # Replace with your domain or use IP
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: containerdemoapp-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: second-app-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: containerdemoapp-service
            port:
              number: 80
```

### Apply the Ingress

```bash
# Apply ingress configuration
kubectl apply -f path-based-ingress.yaml

# Check ingress status
kubectl get ingress -n demo-apps

# Get ingress details
kubectl describe ingress path-based-ingress -n demo-apps
```

## Step 6: Testing Path-Based Routing

### Get External IP

```bash
# Get the external IP of the ingress controller
kubectl get service nginx-ingress-ingress-nginx-controller -n ingress-nginx

# Or use this command to get the IP
EXTERNAL_IP=$(kubectl get service nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "External IP: $EXTERNAL_IP"
```

### Test Different Paths

```bash
# Test main application
curl -H "Host: demo.example.com" http://$EXTERNAL_IP/

# Test API endpoints
curl -H "Host: demo.example.com" http://$EXTERNAL_IP/api/health
curl -H "Host: demo.example.com" http://$EXTERNAL_IP/api/weatherforecast

# Test second application
curl -H "Host: demo.example.com" http://$EXTERNAL_IP/app2/
```

## Step 7: Advanced Ingress Configuration

### Multiple Hosts with Different Paths

```yaml
# multi-host-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
  namespace: demo-apps
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: api.demo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: containerdemoapp-service
            port:
              number: 80
  - host: app.demo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: second-app-service
            port:
              number: 80
```

### Ingress with Rate Limiting

```yaml
# rate-limited-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rate-limited-ingress
  namespace: demo-apps
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: containerdemoapp-service
            port:
              number: 80
```

## Step 8: NGINX Ingress Annotations

### Common Annotations

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: annotated-ingress
  namespace: demo-apps
  annotations:
    # SSL/TLS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    
    # Authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    
    # Custom headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Custom-Header "Custom Value";
    
    # Proxy settings
    nginx.ingress.kubernetes.io/proxy-body-size: "8m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
spec:
  ingressClassName: nginx
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: containerdemoapp-service
            port:
              number: 80
```

## Step 9: Monitoring and Troubleshooting

### Check Ingress Controller Status

```bash
# Check ingress controller pods
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/nginx-ingress-ingress-nginx-controller

# Check ingress controller configuration
kubectl describe pod -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Check Ingress Status

```bash
# Check ingress resources
kubectl get ingress --all-namespaces

# Check ingress events
kubectl describe ingress path-based-ingress -n demo-apps

# Check NGINX configuration
kubectl exec -n ingress-nginx deployment/nginx-ingress-ingress-nginx-controller -- nginx -T
```

### Test Connectivity

```bash
# Test from within cluster
kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh

# Inside the pod
wget -qO- http://containerdemoapp-service/health
wget -qO- http://second-app-service/
exit

# Test external access
curl -v -H "Host: demo.example.com" http://$EXTERNAL_IP/api/health
```

## Step 10: Advanced Routing Patterns

### Canary Deployment with Ingress

```yaml
# canary-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary-ingress
  namespace: demo-apps
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: containerdemoapp-canary-service
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: stable-ingress
  namespace: demo-apps
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: containerdemoapp-service
            port:
              number: 80
```

### Blue-Green Deployment with Ingress

```yaml
# blue-green-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: blue-green-ingress
  namespace: demo-apps
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: containerdemoapp-blue-service  # Switch between blue/green
            port:
              number: 80
```

## Step 11: Best Practices

### Ingress Best Practices

1. **Use IngressClass**: Specify the ingress controller explicitly
2. **Set Resource Limits**: Configure appropriate limits for ingress controller
3. **Use Annotations**: Leverage NGINX annotations for advanced features
4. **Monitor Performance**: Track ingress controller metrics
5. **Security**: Implement proper security policies

### Routing Best Practices

1. **Use Path Types**: Specify appropriate path types (Prefix, Exact, ImplementationSpecific)
2. **Host-Based Routing**: Use host-based routing for multi-tenant applications
3. **Health Checks**: Ensure backend services are healthy
4. **SSL/TLS**: Enable SSL termination for production
5. **Rate Limiting**: Implement rate limiting for API protection

## Step 12: Cleanup

```bash
# Delete ingress resources
kubectl delete ingress path-based-ingress -n demo-apps
kubectl delete ingress multi-host-ingress -n demo-apps
kubectl delete ingress rate-limited-ingress -n demo-apps

# Delete applications
kubectl delete deployment second-app -n demo-apps
kubectl delete service second-app-service -n demo-apps

# Uninstall NGINX ingress controller
helm uninstall nginx-ingress -n ingress-nginx

# Delete namespace
kubectl delete namespace ingress-nginx
```

## Key Takeaways

1. **Ingress controllers provide** external access to cluster services
2. **NGINX ingress controller** is the most popular choice
3. **Path-based routing** enables multiple services on single domain
4. **Annotations provide** advanced configuration options
5. **Ingress resources** define routing rules declaratively
6. **Monitoring and troubleshooting** are essential for production

## Next Steps
In the next demo, we'll implement TLS/SSL certificates using Let's Encrypt for secure HTTPS access.

## Troubleshooting

### Common Issues:
1. **Ingress not accessible**: Check external IP and firewall rules
2. **Path routing not working**: Verify path types and rewrite rules
3. **SSL issues**: Check certificate configuration
4. **Backend not found**: Verify service names and ports

### Useful Commands:
```bash
# Check ingress controller status
kubectl get pods -n ingress-nginx

# Check ingress configuration
kubectl describe ingress <ingress-name> -n <namespace>

# Check NGINX logs
kubectl logs -n ingress-nginx deployment/nginx-ingress-ingress-nginx-controller

# Test connectivity
curl -v -H "Host: <host>" http://<external-ip>/<path>
``` 