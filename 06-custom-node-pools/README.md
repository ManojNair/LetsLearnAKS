# Demo 06: Custom Node Pools with Azure Mariner and Node Affinity

## Overview
This demo covers adding custom node pools to AKS clusters, specifically using Azure Mariner images, and implementing node affinity for workload scheduling. You'll learn about different node pool configurations and advanced scheduling techniques.

## Learning Objectives
- Understand AKS node pool concepts and types
- Add node pools with Azure Mariner images
- Configure node labels and taints
- Implement node affinity for workload scheduling
- Understand workload isolation and resource optimization

## Prerequisites
- AKS cluster created (from Demo 04)
- kubectl configured to connect to AKS cluster
- Understanding of basic Kubernetes concepts

## Step 1: Understanding AKS Node Pools

### Node Pool Types

#### System Node Pool:
- Runs system pods (kube-system namespace)
- Minimum 1 node required
- Cannot be deleted while cluster exists
- Should not run user workloads

#### User Node Pools:
- Run application workloads
- Can have multiple node pools
- Can be added/removed as needed
- Can have different configurations

### Node Pool Configurations:
- **VM Size**: CPU, memory, and storage capacity
- **OS Image**: Ubuntu, Azure Mariner, Windows
- **Node Count**: Number of nodes in the pool
- **Scaling**: Manual or automatic scaling
- **Spot Instances**: Preemptible VMs for cost savings

## Step 2: Understanding Azure Mariner

### What is Azure Mariner?
Azure Mariner is a Linux distribution built by Microsoft specifically for cloud and edge services.

### Benefits of Azure Mariner:
1. **Security**: Minimal attack surface, regular security updates
2. **Performance**: Optimized for cloud workloads
3. **Compliance**: Built with compliance requirements in mind
4. **Microsoft Support**: Full Microsoft support and maintenance
5. **Container Optimized**: Designed for container workloads

### Azure Mariner vs Ubuntu:
- **Smaller footprint**: Reduced image size
- **Faster boot times**: Optimized for quick startup
- **Better security**: Minimal packages, regular updates
- **Microsoft ecosystem**: Better integration with Azure services

## Step 3: Adding a Node Pool with Azure Mariner

### Check Current Node Pools

```bash
# List existing node pools
az aks nodepool list \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --output table

# Get detailed information about node pools
az aks nodepool show \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name nodepool1
```

### Add Azure Mariner Node Pool

```bash
# Set variables for new node pool
NODEPOOL_NAME="marinerpool"
NODE_COUNT=2
VM_SIZE="Standard_DS2_v2"

# Add node pool with Azure Mariner
az aks nodepool add \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name $NODEPOOL_NAME \
  --node-count $NODE_COUNT \
  --node-vm-size $VM_SIZE \
  --os-type Linux \
  --os-sku AzureLinux \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --node-taints "workload=mariner:NoSchedule" \
  --labels "workload=mariner" "environment=production" "os=mariner"

# Verify node pool creation
az aks nodepool list \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME
```

### Verify Nodes

```bash
# Get cluster credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Check nodes
kubectl get nodes -o wide

# Check node labels
kubectl get nodes --show-labels

# Check node taints
kubectl get nodes -o custom-columns="NAME:.metadata.name,TAINTS:.spec.taints"
```

## Step 4: Understanding Node Labels and Taints

### Node Labels
Labels are key-value pairs attached to nodes for identification and selection.

```bash
# Check all node labels
kubectl get nodes --show-labels

# Get specific node labels
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels}{"\n"}{end}'
```

### Node Taints
Taints prevent pods from being scheduled on nodes unless they have matching tolerations.

```bash
# Check node taints
kubectl get nodes -o custom-columns="NAME:.metadata.name,TAINTS:.spec.taints"

# Describe node to see taints
kubectl describe node <node-name> | grep -A 5 Taints
```

### Taint Effects:
- **NoSchedule**: Pods will not be scheduled on the node
- **PreferNoSchedule**: Pods will try to avoid the node
- **NoExecute**: Pods will be evicted if they don't tolerate the taint

## Step 5: Creating Workloads with Node Affinity

### Node Affinity Concepts

Node affinity allows you to specify rules for pod scheduling based on node labels.

### Types of Node Affinity:
1. **RequiredDuringSchedulingIgnoredDuringExecution**: Hard requirement
2. **PreferredDuringSchedulingIgnoredDuringExecution**: Soft preference

### Create a Deployment with Node Affinity

```yaml
# mariner-app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariner-app
  labels:
    app: mariner-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mariner-app
  template:
    metadata:
      labels:
        app: mariner-app
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: workload
                operator: In
                values:
                - mariner
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: environment
                operator: In
                values:
                - production
      tolerations:
      - key: "workload"
        operator: "Equal"
        value: "mariner"
        effect: "NoSchedule"
      containers:
      - name: mariner-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
```

```bash
# Apply the deployment
kubectl apply -f mariner-app-deployment.yaml

# Check deployment status
kubectl get deployments
kubectl get pods -o wide
```

## Step 6: Creating Different Node Pools for Different Workloads

### Add a Development Node Pool

```bash
# Add development node pool
az aks nodepool add \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name devpool \
  --node-count 1 \
  --node-vm-size Standard_DS1_v2 \
  --os-type Linux \
  --os-sku Ubuntu \
  --node-taints "workload=dev:NoSchedule" \
  --labels "workload=dev" "environment=development" "os=ubuntu"

# Verify node pools
az aks nodepool list \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME
```

### Add a Spot Instance Node Pool

```bash
# Add spot instance node pool for cost optimization
az aks nodepool add \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name spotpool \
  --node-count 1 \
  --node-vm-size Standard_DS2_v2 \
  --os-type Linux \
  --os-sku Ubuntu \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --node-taints "workload=spot:NoSchedule" \
  --labels "workload=spot" "environment=spot" "os=ubuntu"

# Verify spot node pool
az aks nodepool show \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name spotpool
```

## Step 7: Creating Workloads for Different Node Pools

### Development Workload

```yaml
# dev-app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-app
  labels:
    app: dev-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dev-app
  template:
    metadata:
      labels:
        app: dev-app
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: workload
                operator: In
                values:
                - dev
      tolerations:
      - key: "workload"
        operator: "Equal"
        value: "dev"
        effect: "NoSchedule"
      containers:
      - name: dev-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: ENVIRONMENT
          value: "development"
```

### Spot Instance Workload

```yaml
# spot-app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spot-app
  labels:
    app: spot-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: spot-app
  template:
    metadata:
      labels:
        app: spot-app
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: workload
                operator: In
                values:
                - spot
      tolerations:
      - key: "workload"
        operator: "Equal"
        value: "spot"
        effect: "NoSchedule"
      containers:
      - name: spot-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: ENVIRONMENT
          value: "spot"
```

```bash
# Apply all deployments
kubectl apply -f dev-app-deployment.yaml
kubectl apply -f spot-app-deployment.yaml

# Check all pods and their node placement
kubectl get pods -o wide --all-namespaces
```

## Step 8: Advanced Node Affinity Scenarios

### Multi-Node Pool Affinity

```yaml
# multi-pool-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-pool-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: multi-pool-app
  template:
    metadata:
      labels:
        app: multi-pool-app
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: workload
                operator: In
                values:
                - mariner
                - dev
          - weight: 50
            preference:
              matchExpressions:
              - key: environment
                operator: In
                values:
                - production
      tolerations:
      - key: "workload"
        operator: "Equal"
        value: "mariner"
        effect: "NoSchedule"
      - key: "workload"
        operator: "Equal"
        value: "dev"
        effect: "NoSchedule"
      containers:
      - name: multi-pool-app
        image: nginx:alpine
        ports:
        - containerPort: 80
```

### Anti-Affinity for High Availability

```yaml
# ha-app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ha-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ha-app
  template:
    metadata:
      labels:
        app: ha-app
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - ha-app
            topologyKey: "kubernetes.io/hostname"
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: workload
                operator: In
                values:
                - mariner
      tolerations:
      - key: "workload"
        operator: "Equal"
        value: "mariner"
        effect: "NoSchedule"
      containers:
      - name: ha-app
        image: nginx:alpine
        ports:
        - containerPort: 80
```

## Step 9: Monitoring Node Pool Usage

### Check Node Pool Status

```bash
# Check node pool status
az aks nodepool list \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --output table

# Check node pool scaling
az aks nodepool show \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name marinerpool \
  --query "{name:name,count:count,minCount:minCount,maxCount:maxCount,enableAutoScaling:enableAutoScaling}"
```

### Monitor Pod Distribution

```bash
# Check pod distribution across nodes
kubectl get pods -o wide --all-namespaces | grep -v kube-system

# Check node resource usage
kubectl top nodes

# Check pod resource usage
kubectl top pods --all-namespaces
```

### Check Node Pool Events

```bash
# Check events related to node pools
kubectl get events --field-selector involvedObject.kind=Node

# Check scaling events
kubectl get events --field-selector reason=ScalingReplicaSet
```

## Step 10: Node Pool Management

### Scale Node Pools

```bash
# Scale node pool manually
az aks nodepool scale \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name marinerpool \
  --node-count 3

# Check scaling status
az aks nodepool show \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name marinerpool
```

### Update Node Pool

```bash
# Update node pool (e.g., change VM size)
az aks nodepool upgrade \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name marinerpool

# Check upgrade status
az aks nodepool show \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name marinerpool
```

## Step 11: Best Practices

### Node Pool Design

1. **Separate System and User Workloads**: Use dedicated node pools
2. **Workload Isolation**: Use taints and tolerations
3. **Resource Optimization**: Use appropriate VM sizes
4. **Cost Management**: Use spot instances for non-critical workloads
5. **High Availability**: Distribute workloads across multiple nodes

### Node Affinity Best Practices

1. **Use Required Affinity Sparingly**: Can cause scheduling issues
2. **Prefer Soft Affinity**: More flexible scheduling
3. **Combine with Anti-Affinity**: For high availability
4. **Monitor Scheduling**: Ensure pods can be scheduled
5. **Test Affinity Rules**: Verify they work as expected

## Step 12: Cleanup

```bash
# Delete test deployments
kubectl delete deployment mariner-app
kubectl delete deployment dev-app
kubectl delete deployment spot-app
kubectl delete deployment multi-pool-app
kubectl delete deployment ha-app

# Delete node pools (optional)
az aks nodepool delete \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name marinerpool

az aks nodepool delete \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name devpool

az aks nodepool delete \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name spotpool
```

## Key Takeaways

1. **Node pools provide** workload isolation and resource optimization
2. **Azure Mariner offers** security and performance benefits
3. **Node affinity enables** intelligent workload placement
4. **Taints and tolerations** prevent unwanted pod scheduling
5. **Multiple node pools** support different workload requirements
6. **Spot instances** provide cost optimization for non-critical workloads

## Next Steps
In the next demo, we'll deploy our .NET 9 application to AKS and explore basic deployment strategies.

## Troubleshooting

### Common Issues:
1. **Node pool creation fails**: Check VM size availability and quotas
2. **Pods not scheduling**: Verify node affinity and taint configurations
3. **Spot instance evictions**: Monitor spot instance availability
4. **Resource constraints**: Check node capacity and pod resource requests

### Useful Commands:
```bash
# Check node pool status
az aks nodepool list --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME

# Check node labels and taints
kubectl get nodes --show-labels
kubectl get nodes -o custom-columns="NAME:.metadata.name,TAINTS:.spec.taints"

# Check pod scheduling
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>
``` 