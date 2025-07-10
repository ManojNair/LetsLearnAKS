# Demo 02: Why Container Orchestration?

## Overview
This demo demonstrates the challenges of running containers in production without orchestration and why Kubernetes (and AKS) is essential for modern application deployment.

## Learning Objectives
- Understand the limitations of running containers manually
- Learn about the challenges of container management at scale
- See why orchestration platforms are necessary
- Understand the benefits of Kubernetes

## Prerequisites
- Docker Desktop installed and running
- Basic understanding of containers (from Demo 01)
- Terminal/Command Prompt

## Step 1: The Problem with Manual Container Management

### Scenario: Running a Multi-Service Application
Imagine you have a modern application with multiple services:
- **Web API** (from Demo 01)
- **Database** (PostgreSQL)
- **Cache** (Redis)
- **Message Queue** (RabbitMQ)
- **Load Balancer** (Nginx)

### Manual Management Challenges

Let's simulate running these services manually:

```bash
# Create a directory for this demo
mkdir 02-why-orchestration
cd 02-why-orchestration

# Create a simple script to demonstrate manual container management
```

## Step 2: Creating a Multi-Service Application

The multi-service application has been created in the `multi-service-app` directory. It includes:

- **app.js**: Express.js application with Redis integration
- **package.json**: Node.js dependencies
- **Dockerfile**: Container configuration
- **docker-compose.yml**: Multi-container orchestration
- **.dockerignore**: Excludes unnecessary files from build

### Building and Running the Application

```bash
# Navigate to the multi-service app directory
cd multi-service-app

# Install dependencies (for local development)
npm install

# Build the Docker image
docker build -t node-app:latest .

# Run with Docker Compose (recommended for this demo)
docker compose up -d

# Or run manually with individual containers
docker run -d --name redis-server redis:7-alpine
docker run -d --name app-server \
  --link redis-server:redis \
  -p 3000:3000 \
  -e REDIS_HOST=redis \
  node-app:latest

# Test the application
curl http://localhost:3000/
curl http://localhost:3000/health

# Check container status
docker ps
docker logs app-server
```

## Step 3: Manual Container Deployment Challenges

### Challenge 1: Service Discovery and Networking

```bash
# Start Redis container
docker run -d --name redis-server redis:7-alpine

# Start the application container
docker run -d --name app-server \
  --link redis-server:redis \
  -p 3000:3000 \
  -e REDIS_HOST=redis \
  node-app:latest
```

**Problems:**
- Manual IP management
- No automatic service discovery
- Hard-coded dependencies
- Difficult to scale

### Challenge 2: Health Monitoring and Recovery

```bash
# Check if containers are running
docker ps

# What happens if Redis crashes?
docker stop redis-server

# The app will fail, but no automatic recovery
curl http://localhost:3000/health
```

**Problems:**
- No automatic health checks
- Manual intervention required for failures
- No self-healing capabilities
- Difficult to monitor

### Challenge 3: Scaling and Load Balancing

```bash
# To scale the application, you need to:
# 1. Manually start more containers
docker run -d --name app-server-2 \
  --link redis-server:redis \
  -p 3001:3000 \
  -e REDIS_HOST=redis \
  node-app:latest

docker run -d --name app-server-3 \
  --link redis-server:redis \
  -p 3002:3000 \
  -e REDIS_HOST=redis \
  node-app:latest

# 2. Manually configure load balancer
# 3. Update DNS or routing rules
```

**Problems:**
- Manual scaling process
- No automatic load balancing
- Port conflicts
- Complex networking setup

### Challenge 4: Configuration Management

```bash
# Different environments need different configurations
# Development
docker run -d --name app-dev \
  -e NODE_ENV=development \
  -e REDIS_HOST=localhost \
  -p 3000:3000 \
  node-app:latest

# Production
docker run -d --name app-prod \
  -e NODE_ENV=production \
  -e REDIS_HOST=redis-prod \
  -p 3000:3000 \
  node-app:latest
```

**Problems:**
- Environment-specific configurations
- Manual configuration management
- No centralized configuration
- Difficult to maintain consistency

### Challenge 5: Resource Management

```bash
# No resource limits by default
docker run -d --name app-unlimited \
  -p 3000:3000 \
  node-app:latest

# Manual resource limits
docker run -d --name app-limited \
  --memory=512m \
  --cpus=1.0 \
  -p 3000:3000 \
  node-app:latest
```

**Problems:**
- No resource isolation
- Resource contention
- Difficult to predict resource usage
- No automatic resource optimization

## Step 4: Demonstrating Failure Scenarios

### Scenario 1: Container Crash
```bash
# Simulate a container crash
docker kill app-server

# Manual recovery required
docker start app-server

# What if the container keeps crashing?
# Manual intervention needed every time
```

### Scenario 2: Network Issues
```bash
# Simulate network partition
docker network disconnect bridge app-server

# Application becomes unreachable
curl http://localhost:3000/health

# Manual network troubleshooting required
```

### Scenario 3: Resource Exhaustion
```bash
# Simulate memory pressure
docker run -d --name memory-hog \
  --memory=1g \
  alpine sh -c "while true; do dd if=/dev/zero of=/tmp/test bs=1M count=1000; done"

# Other containers may be affected
docker stats
```

## Step 5: The Orchestration Solution

### What Kubernetes Provides:

1. **Service Discovery**
   - Automatic service registration
   - DNS-based service discovery
   - Load balancing built-in

2. **Health Monitoring**
   - Liveness probes
   - Readiness probes
   - Automatic restart on failure

3. **Scaling**
   - Horizontal Pod Autoscaler (HPA)
   - Vertical Pod Autoscaler (VPA)
   - Manual scaling with kubectl

4. **Configuration Management**
   - ConfigMaps
   - Secrets
   - Environment-specific configurations

5. **Resource Management**
   - Resource requests and limits
   - Namespace isolation
   - Resource quotas

6. **Rolling Updates**
   - Zero-downtime deployments
   - Rollback capabilities
   - Canary deployments

### Deploying to Kubernetes

Now let's see how the same application is deployed using Kubernetes:

```bash
# Create a namespace for our demo
kubectl create namespace orchestration-demo

# Deploy Redis first
kubectl apply -f k8s-redis.yaml -n orchestration-demo

# Deploy the application
kubectl apply -f k8s-deployment.yaml -n orchestration-demo

# Deploy the Horizontal Pod Autoscaler
kubectl apply -f k8s-hpa.yaml -n orchestration-demo

# Check the deployment status
kubectl get pods -n orchestration-demo
kubectl get services -n orchestration-demo
kubectl get hpa -n orchestration-demo

# Test the application
kubectl port-forward svc/multi-service-app-service 8080:80 -n orchestration-demo
curl http://localhost:8080/
```

## Step 6: Kubernetes vs Manual Management

### Manual Management:
```bash
# Starting services manually
docker run -d --name redis redis:alpine
docker run -d --name app --link redis:redis app:latest

# Monitoring manually
docker ps
docker logs app

# Scaling manually
docker run -d --name app2 --link redis:redis app:latest
docker run -d --name app3 --link redis:redis app:latest

# Load balancing manually
# Need to configure nginx or haproxy manually
```

### Kubernetes Management:
```bash
# Deploy with a single command
kubectl apply -f k8s-deployment.yaml -n orchestration-demo

# Automatic service discovery
kubectl get services -n orchestration-demo

# Automatic scaling
kubectl scale deployment multi-service-app --replicas=5 -n orchestration-demo

# Automatic health monitoring
kubectl get pods -n orchestration-demo
kubectl describe pod <pod-name> -n orchestration-demo

# Automatic load balancing
kubectl get endpoints -n orchestration-demo

# Check logs
kubectl logs -l app=multi-service-app -n orchestration-demo
```

## Step 7: Real-World Production Challenges

### Challenge 1: High Availability
- **Manual**: Multiple servers, manual failover, complex setup
- **Kubernetes**: Built-in HA, automatic failover, multi-zone deployment

### Challenge 2: Security
- **Manual**: Manual security configuration, difficult to audit
- **Kubernetes**: RBAC, network policies, pod security policies

### Challenge 3: Monitoring and Logging
- **Manual**: Manual setup of monitoring tools
- **Kubernetes**: Integrated monitoring, centralized logging

### Challenge 4: Updates and Rollbacks
- **Manual**: Manual update process, difficult rollbacks
- **Kubernetes**: Rolling updates, easy rollbacks, blue-green deployments

## Step 8: Why AKS Specifically?

### Azure Kubernetes Service Benefits:

1. **Managed Control Plane**
   - No need to manage Kubernetes master nodes
   - Automatic updates and patches
   - High availability built-in

2. **Azure Integration**
   - Azure Active Directory integration
   - Azure Monitor integration
   - Azure Container Registry integration

3. **Enterprise Features**
   - Azure Policy for Kubernetes
   - Azure Key Vault integration
   - Azure DevOps integration

4. **Cost Optimization**
   - Spot instances for workloads
   - Cluster autoscaler
   - Resource optimization

## Step 9: Cleanup

### Clean up Docker resources:
```bash
# Stop and remove all containers
docker stop $(docker ps -q)
docker rm $(docker ps -aq)

# Remove images
docker rmi node-app:latest

# Clean up networks
docker network prune -f
```

### Clean up Kubernetes resources:
```bash
# Delete the namespace (this will remove all resources)
kubectl delete namespace orchestration-demo

# Or delete individual resources
kubectl delete -f k8s-deployment.yaml -n orchestration-demo
kubectl delete -f k8s-redis.yaml -n orchestration-demo
kubectl delete -f k8s-hpa.yaml -n orchestration-demo
```

## Key Takeaways

1. **Manual container management doesn't scale** for production environments
2. **Orchestration platforms solve** service discovery, scaling, and reliability issues
3. **Kubernetes provides** a comprehensive solution for container orchestration
4. **AKS offers** managed Kubernetes with Azure integration
5. **Production readiness requires** automation, monitoring, and reliability features

## Next Steps
In the next demo, we'll explore Kubernetes fundamentals and set up a local Kubernetes cluster to understand the basic concepts.

## Troubleshooting

### Common Issues:
1. **Port conflicts**: Use different ports for each container
2. **Network issues**: Check Docker network configuration
3. **Resource exhaustion**: Monitor system resources
4. **Service discovery**: Use Docker networks or external DNS

### Useful Commands:
```bash
# Check container status
docker ps -a

# View container logs
docker logs <container-name>

# Check resource usage
docker stats

# Inspect container details
docker inspect <container-name>

# Check Redis connection
docker exec -it redis-server redis-cli ping

# Test application connectivity
curl http://localhost:3000/health
```

### Troubleshooting Redis Connection Issues:

If you get `{"error":"The client is closed"}` error:

1. **Check if Redis is running:**
   ```bash
   docker ps | grep redis
   ```

2. **Check Redis logs:**
   ```bash
   docker logs redis-server
   ```

3. **Test Redis connectivity:**
   ```bash
   docker exec -it redis-server redis-cli ping
   ```

4. **Restart the application container:**
   ```bash
   docker restart app-server
   ```

5. **Use Docker Compose (recommended):**
   ```bash
   docker compose down
   docker compose up -d
   ``` 