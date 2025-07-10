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

Let's create a more complex application that demonstrates orchestration needs:

```bash
# Create a simple web application that depends on a database
mkdir multi-service-app
cd multi-service-app
```

Create a simple Node.js application that demonstrates service dependencies:

```javascript
// app.js
const express = require('express');
const redis = require('redis');
const app = express();
const port = 3000;

// Redis client
const client = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379
});

client.on('error', (err) => console.log('Redis Client Error', err));

app.get('/', async (req, res) => {
    try {
        // Increment visit counter
        const visits = await client.incr('visits');
        res.json({
            message: 'Hello from Multi-Service App!',
            visits: visits,
            timestamp: new Date().toISOString(),
            hostname: require('os').hostname()
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
    console.log(`App listening at http://localhost:${port}`);
});
```

## Step 3: Manual Container Deployment Challenges

### Challenge 1: Service Discovery and Networking

```bash
# Start Redis container
docker run -d --name redis-server redis:alpine

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
kubectl apply -f deployment.yaml

# Automatic service discovery
kubectl get services

# Automatic scaling
kubectl scale deployment app --replicas=5

# Automatic health monitoring
kubectl get pods
kubectl describe pod <pod-name>
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

```bash
# Stop and remove all containers
docker stop $(docker ps -q)
docker rm $(docker ps -aq)

# Remove images
docker rmi node-app:latest

# Clean up networks
docker network prune -f
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
``` 