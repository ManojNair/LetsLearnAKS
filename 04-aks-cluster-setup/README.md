# Demo 04: AKS Cluster Setup with Azure CNI Overlay

## Overview
This demo guides you through creating an Azure Kubernetes Service (AKS) cluster with Azure CNI Overlay networking and VNET integration. You'll learn about AKS architecture and Azure-specific features.

## Learning Objectives
- Understand AKS architecture and components
- Create an AKS cluster with Azure CNI Overlay
- Configure VNET integration
- Connect to the AKS cluster
- Understand Azure-specific networking features

## Prerequisites
- Azure CLI installed and configured
- Azure subscription with appropriate permissions
- Basic understanding of Kubernetes (from Demo 03)

## Step 1: Understanding AKS Architecture

### AKS Components

#### Managed Control Plane:
- **API Server**: Managed by Azure
- **etcd**: Managed by Azure with high availability
- **Scheduler**: Managed by Azure
- **Controller Manager**: Managed by Azure

#### Node Pools:
- **System Node Pool**: Runs system pods (kube-system namespace)
- **User Node Pools**: Run application workloads
- **Virtual Machine Scale Sets**: Underlying infrastructure

#### Azure-Specific Components:
- **Azure CNI**: Container networking interface
- **Azure Load Balancer**: Load balancing service
- **Azure Disk**: Persistent storage
- **Azure Monitor**: Monitoring and logging

### Why AKS?
1. **Managed Control Plane**: No need to manage Kubernetes master nodes
2. **Azure Integration**: Seamless integration with Azure services
3. **Enterprise Features**: RBAC, Azure AD integration, Azure Policy
4. **Cost Optimization**: Spot instances, cluster autoscaler
5. **Security**: Azure Security Center, network policies

## Step 2: Azure CLI Setup and Configuration

### Install and Configure Azure CLI

```bash
# Check Azure CLI version
az version

# Login to Azure
az login

# Set subscription (if you have multiple)
az account list --output table
az account set --subscription "<subscription-id>"

# Verify current subscription
az account show
```

### Install AKS CLI Extensions

```bash
# Install aks-preview extension
az extension add --name aks-preview

# Update the extension
az extension update --name aks-preview

# Install kubectl if not already installed
az aks install-cli
```

## Step 3: Resource Group and VNET Setup

### Create Resource Group

```bash
# Set variables
RESOURCE_GROUP="aks-demo-rg"
LOCATION="australiaeast"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Verify resource group
az group show --name $RESOURCE_GROUP
```

### Create Virtual Network

```bash
# Set VNET variables
VNET_NAME="aks-vnet"
SUBNET_NAME="aks-subnet"
VNET_ADDRESS_PREFIX="10.0.0.0/16"
SUBNET_ADDRESS_PREFIX="10.0.1.0/24"

# Create VNET
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix $VNET_ADDRESS_PREFIX \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix $SUBNET_ADDRESS_PREFIX

# Get subnet ID
SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --query id -o tsv)

echo "Subnet ID: $SUBNET_ID"
```

## Step 4: Understanding Azure CNI Overlay

### Azure CNI Modes

#### Azure CNI (Traditional):
- Each pod gets an IP from the VNET subnet
- Direct pod-to-pod communication
- Limited by subnet size
- More complex IP management

#### Azure CNI Overlay (New):
- Pods get IPs from an overlay network
- VNET subnet used for node IPs only
- Larger pod IP space (16,777,216 pods per cluster)
- Simplified IP management
- Better for large clusters

### Benefits of Azure CNI Overlay:
1. **Larger Pod IP Space**: 16M pods vs 4K pods per subnet
2. **Simplified Networking**: No need for large subnets
3. **Better Scalability**: Support for more nodes and pods
4. **Easier Management**: Less complex IP planning

## Step 5: Create AKS Cluster with Azure CNI Overlay

### Create AKS Cluster

```bash
# Set AKS variables
CLUSTER_NAME="aks-demo-cluster"
NODE_COUNT=3
VM_SIZE="Standard_DS2_v2"

# Create AKS cluster with Azure CNI Overlay
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count $NODE_COUNT \
  --node-vm-size $VM_SIZE \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --vnet-subnet-id $SUBNET_ID \
  --enable-managed-identity \
  --generate-ssh-keys \
  --enable-addons monitoring \
  --enable-azure-rbac \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Get cluster credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Verify cluster connection
kubectl cluster-info
kubectl get nodes
```

### Cluster Configuration Details

The cluster is created with:
- **Azure CNI Overlay**: For pod networking
- **Managed Identity**: For Azure service authentication
- **Azure RBAC**: For role-based access control
- **Cluster Autoscaler**: For automatic node scaling
- **Azure Monitor**: For monitoring and logging

## Step 6: Explore AKS Cluster Components

### Check System Pods

```bash
# Check system pods
kubectl get pods -n kube-system

# Check Azure-specific components
kubectl get pods -n kube-system | grep azure

# Common Azure components:
# - azure-ip-masq-agent: IP masquerading
# - azure-cni: Container networking
# - cloud-node-manager: Node management
# - csi-azuredisk-node: Azure Disk CSI driver
# - csi-azurefile-node: Azure File CSI driver
```

### Check Node Information

```bash
# Get detailed node information
kubectl get nodes -o wide

# Describe a node
kubectl describe node <node-name>

# Check node labels
kubectl get nodes --show-labels
```

### Check Network Configuration

```bash
# Check network policies
kubectl get networkpolicies --all-namespaces

# Check services
kubectl get services --all-namespaces

# Check endpoints
kubectl get endpoints --all-namespaces
```

## Step 7: Understanding Azure CNI Overlay Networking

### Pod IP Assignment

```bash
# Create a test namespace
kubectl create namespace test-overlay

# Create a test pod
kubectl run test-pod --image=nginx:alpine -n test-overlay

# Check pod IP
kubectl get pod test-pod -n test-overlay -o wide

# The pod IP will be from the overlay network (not the VNET subnet)
```

### Network Connectivity

```bash
# Test pod-to-pod communication
kubectl run test-pod-2 --image=nginx:alpine -n test-overlay

# Get pod IPs
POD1_IP=$(kubectl get pod test-pod -n test-overlay -o jsonpath='{.status.podIP}')
POD2_IP=$(kubectl get pod test-pod-2 -n test-overlay -o jsonpath='{.status.podIP}')

echo "Pod 1 IP: $POD1_IP"
echo "Pod 2 IP: $POD2_IP"

# Test connectivity (from within a pod)
kubectl exec -it test-pod -n test-overlay -- ping -c 3 $POD2_IP
```

## Step 8: Azure-Specific Features

### Azure Load Balancer

```bash
# Create a service with LoadBalancer type
kubectl create deployment nginx --image=nginx:alpine -n test-overlay

kubectl expose deployment nginx \
  --type=LoadBalancer \
  --port=80 \
  --target-port=80 \
  -n test-overlay

# Check the service
kubectl get service nginx -n test-overlay

# The external IP will be an Azure Load Balancer IP
```

### Azure Disk Storage

```bash
# Create a PVC (Persistent Volume Claim)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
  namespace: test-overlay
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: managed-csi
EOF

# Check PVC status
kubectl get pvc -n test-overlay
```

## Step 9: Monitoring and Logging

### Azure Monitor Integration

```bash
# Check if Azure Monitor is enabled
kubectl get pods -n kube-system | grep omsagent

# Check Azure Monitor configuration
kubectl get configmap -n kube-system | grep omsagent
```

### View Cluster Metrics

```bash
# Get node metrics
kubectl top nodes

# Get pod metrics
kubectl top pods --all-namespaces

# Note: Azure Monitor provides more detailed metrics in Azure Portal
```

## Step 10: Security Features

### Azure RBAC

```bash
# Check cluster roles
kubectl get clusterroles

# Check cluster role bindings
kubectl get clusterrolebindings

# Check if Azure RBAC is enabled
kubectl get configmap -n kube-system azure-rbac-config
```

### Network Policies

```bash
# Check if network policies are enabled
kubectl get networkpolicies --all-namespaces

# Create a simple network policy
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: test-overlay
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

## Step 11: Scaling and Management

### Cluster Autoscaler

```bash
# Check autoscaler configuration
kubectl get configmap -n kube-system cluster-autoscaler-status

# Check autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler

# Scale deployment to trigger autoscaler
kubectl scale deployment nginx --replicas=10 -n test-overlay
```

### Node Pool Management

```bash
# List node pools
az aks nodepool list --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME

# Add a new node pool
az aks nodepool add \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name userpool \
  --node-count 2 \
  --node-vm-size Standard_DS2_v2 \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3
```

## Step 12: Cleanup

```bash
# Delete test resources
kubectl delete namespace test-overlay

# Delete AKS cluster
az aks delete \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --yes

# Delete VNET
az network vnet delete \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME

# Delete resource group
az group delete --name $RESOURCE_GROUP --yes
```

## Key Takeaways

1. **AKS provides managed Kubernetes** with Azure integration
2. **Azure CNI Overlay** offers larger pod IP space and simplified networking
3. **VNET integration** enables seamless Azure service connectivity
4. **Azure-specific features** include Load Balancer, Disk, and Monitor integration
5. **Security features** include Azure RBAC and network policies
6. **Scaling capabilities** include cluster autoscaler and node pool management

## Next Steps
In the next demo, we'll explore AKS nodes and components in detail, including connecting to nodes and understanding system components.

## Troubleshooting

### Common Issues:
1. **Insufficient permissions**: Ensure you have Contributor role on subscription
2. **VNET subnet issues**: Ensure subnet has enough IP space
3. **Node pool creation failures**: Check VM size availability in region
4. **Network connectivity issues**: Verify Azure CNI configuration

### Useful Commands:
```bash
# Check cluster status
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Get cluster credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Check node pool status
az aks nodepool list --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME

# View cluster logs
az aks diagnostics run --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
``` 