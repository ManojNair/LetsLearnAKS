# Demo 05: AKS Node Exploration and System Components

## Overview
This demo explores AKS nodes in detail, including connecting to nodes using kubectl node-shell, checking system components, and understanding the purpose of various Azure-specific components.

## Learning Objectives
- Connect to AKS nodes using kubectl node-shell
- Understand AKS node architecture and components
- Check the status of kubelet and containerd
- Learn about Azure-specific components and their purposes
- Explore system pods and their functions

## Prerequisites
- AKS cluster created (from Demo 04)
- kubectl configured to connect to AKS cluster
- Basic understanding of Kubernetes components

## Step 1: Understanding AKS Node Architecture

### AKS Node Components

#### Core Components:
1. **kubelet**: Primary node agent that manages containers
2. **kube-proxy**: Network proxy for service networking
3. **containerd**: Container runtime for running containers
4. **Azure CNI**: Container networking interface

#### Azure-Specific Components:
1. **azure-ip-masq-agent**: IP masquerading for outbound traffic
2. **coredns**: DNS server for cluster services
3. **coredns-autoscaler**: Scales CoreDNS based on cluster size
4. **konnectivity**: Secure tunnel for control plane communication

### Node Types in AKS:
- **System Node Pool**: Runs system pods (kube-system namespace)
- **User Node Pools**: Run application workloads
- **Spot Instances**: Preemptible VMs for cost optimization

## Step 2: Installing kubectl node-shell

### Install node-shell Extension

```bash
# Install kubectl node-shell extension
kubectl krew install node-shell

# Verify installation
kubectl krew list

# Alternative: Install directly
curl -LO https://github.com/kvaps/kubectl-node-shell/raw/master/kubectl-node_shell
chmod +x kubectl-node_shell
sudo mv kubectl-node_shell /usr/local/bin/kubectl-node_shell
```

### Verify Cluster Connection

```bash
# Check cluster info
kubectl cluster-info

# List nodes
kubectl get nodes -o wide

# Check node labels
kubectl get nodes --show-labels
```

## Step 3: Connecting to AKS Nodes

### Connect to a Node

```bash
# Get node names
NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

# Connect to the first node
FIRST_NODE=$(echo $NODES | cut -d' ' -f1)
echo "Connecting to node: $FIRST_NODE"

# Connect using node-shell
kubectl node-shell $FIRST_NODE

# Alternative using kubectl-node_shell
kubectl-node_shell $FIRST_NODE
```

### Explore Node File System

Once connected to the node, explore the system:

```bash
# Check system information
uname -a
cat /etc/os-release

# Check disk usage
df -h

# Check memory usage
free -h

# Check CPU information
lscpu

# Check network interfaces
ip addr show

# Check running processes
ps aux | head -20
```

## Step 4: Understanding kubelet

### Check kubelet Status

```bash
# Check kubelet service status
systemctl status kubelet

# Check kubelet configuration
cat /var/lib/kubelet/config.yaml

# Check kubelet logs
journalctl -u kubelet -f

# Check kubelet process
ps aux | grep kubelet

# Check kubelet API
curl -k https://localhost:10250/healthz
```

### Kubelet Configuration

```bash
# Check kubelet configuration file
cat /var/lib/kubelet/config.yaml | grep -E "(address|port|cgroupDriver)"

# Check kubelet command line arguments
ps aux | grep kubelet | grep -o -- '--[^ ]*'

# Common kubelet arguments:
# --container-runtime-endpoint: containerd socket
# --node-ip: Node IP address
# --pod-infra-container-image: Pause container image
# --cgroup-driver: cgroup driver (systemd)
```

## Step 5: Understanding containerd

### Check containerd Status

```bash
# Check containerd service status
systemctl status containerd

# Check containerd configuration
cat /etc/containerd/config.toml

# Check containerd socket
ls -la /run/containerd/containerd.sock

# Check containerd processes
ps aux | grep containerd

# Check containerd logs
journalctl -u containerd -f
```

### Explore Containers

```bash
# List all containers
crictl ps -a

# List all images
crictl images

# Get container information
crictl inspect <container-id>

# Check container logs
crictl logs <container-id>

# Execute command in container
crictl exec <container-id> /bin/sh
```

## Step 6: Understanding Azure-Specific Components

### azure-ip-masq-agent

The azure-ip-masq-agent provides IP masquerading for outbound traffic from pods.

```bash
# Check azure-ip-masq-agent pod
kubectl get pods -n kube-system | grep azure-ip-masq-agent

# Check azure-ip-masq-agent logs
kubectl logs -n kube-system deployment/azure-ip-masq-agent

# Check azure-ip-masq-agent configuration
kubectl get configmap -n kube-system azure-ip-masq-agent-config -o yaml

# Check iptables rules (from node)
iptables -t nat -L AZURE-IP-MASQ-AGENT
```

### Purpose of azure-ip-masq-agent:
1. **Outbound Traffic**: Masquerades pod IPs to node IP for outbound traffic
2. **Azure Service Connectivity**: Enables pods to connect to Azure services
3. **Internet Access**: Provides internet access for pods
4. **Load Balancer Health Probes**: Handles health probe traffic

### coredns

CoreDNS provides DNS resolution for cluster services.

```bash
# Check coredns pods
kubectl get pods -n kube-system | grep coredns

# Check coredns logs
kubectl logs -n kube-system deployment/coredns

# Check coredns configuration
kubectl get configmap -n kube-system coredns -o yaml

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
```

### Purpose of coredns:
1. **Service Discovery**: Resolves service names to IP addresses
2. **Pod DNS**: Provides DNS resolution for pods
3. **External DNS**: Can resolve external domain names
4. **Custom DNS**: Supports custom DNS records

### coredns-autoscaler

The coredns-autoscaler scales CoreDNS based on cluster size.

```bash
# Check coredns-autoscaler pod
kubectl get pods -n kube-system | grep coredns-autoscaler

# Check coredns-autoscaler logs
kubectl logs -n kube-system deployment/coredns-autoscaler

# Check autoscaler configuration
kubectl get configmap -n kube-system coredns-autoscaler -o yaml
```

### Purpose of coredns-autoscaler:
1. **Automatic Scaling**: Scales CoreDNS based on cluster size
2. **Performance**: Ensures adequate DNS performance
3. **Resource Optimization**: Prevents over-provisioning
4. **High Availability**: Maintains DNS availability

### konnectivity

Konnectivity provides secure tunnels for control plane communication.

```bash
# Check konnectivity pods
kubectl get pods -n kube-system | grep konnectivity

# Check konnectivity logs
kubectl logs -n kube-system deployment/konnectivity-agent

# Check konnectivity configuration
kubectl get configmap -n kube-system konnectivity-agent -o yaml
```

### Purpose of konnectivity:
1. **Secure Communication**: Provides secure tunnels between nodes and control plane
2. **Network Policies**: Enables network policy enforcement
3. **Control Plane Access**: Allows nodes to communicate with API server
4. **TLS Termination**: Handles TLS termination for control plane traffic

## Step 7: Exploring System Pods

### Check All System Pods

```bash
# List all pods in kube-system namespace
kubectl get pods -n kube-system -o wide

# Get detailed information about system pods
kubectl describe pods -n kube-system

# Check system pod logs
kubectl logs -n kube-system deployment/cloud-node-manager
kubectl logs -n kube-system deployment/azure-cni
kubectl logs -n kube-system deployment/csi-azuredisk-node
```

### System Pod Categories

#### Networking:
- **azure-cni**: Container networking interface
- **azure-ip-masq-agent**: IP masquerading
- **kube-proxy**: Service networking

#### Storage:
- **csi-azuredisk-node**: Azure Disk CSI driver
- **csi-azurefile-node**: Azure File CSI driver

#### Monitoring:
- **omsagent**: Azure Monitor agent
- **metrics-server**: Kubernetes metrics

#### Security:
- **konnectivity-agent**: Secure tunnels
- **azure-policy**: Azure Policy enforcement

## Step 8: Node Resource Management

### Check Node Resources

```bash
# Check node capacity and allocatable resources
kubectl describe node $FIRST_NODE | grep -A 10 "Capacity\|Allocatable"

# Check node metrics
kubectl top node $FIRST_NODE

# Check node conditions
kubectl describe node $FIRST_NODE | grep -A 5 "Conditions"

# Check node events
kubectl get events --field-selector involvedObject.name=$FIRST_NODE
```

### Resource Allocation

```bash
# Check pod resource requests and limits
kubectl get pods --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEMORY_REQUEST:.spec.containers[*].resources.requests.memory,MEMORY_LIMIT:.spec.containers[*].resources.limits.memory"

# Check node resource usage
kubectl describe node $FIRST_NODE | grep -A 10 "Allocated resources"
```

## Step 9: Network Configuration

### Check Network Interfaces

```bash
# Check network interfaces on node
ip addr show

# Check routing table
ip route show

# Check iptables rules
iptables -L -n -v

# Check network namespaces
ip netns list
```

### Azure CNI Configuration

```bash
# Check Azure CNI configuration
cat /etc/cni/net.d/10-azure.conflist

# Check Azure CNI logs
journalctl -u azure-cni -f

# Check CNI binaries
ls -la /opt/cni/bin/

# Check CNI network configuration
ls -la /etc/cni/net.d/
```

## Step 10: Troubleshooting Common Issues

### Node Not Ready

```bash
# Check node conditions
kubectl describe node $FIRST_NODE | grep -A 10 "Conditions"

# Check kubelet status
systemctl status kubelet

# Check kubelet logs
journalctl -u kubelet -f

# Check node events
kubectl get events --field-selector involvedObject.name=$FIRST_NODE
```

### Pod Scheduling Issues

```bash
# Check pod events
kubectl get events --field-selector involvedObject.kind=Pod

# Check node capacity
kubectl describe node $FIRST_NODE | grep -A 5 "Capacity"

# Check taints and tolerations
kubectl get nodes --show-labels | grep taint
```

### Network Issues

```bash
# Check Azure CNI status
kubectl get pods -n kube-system | grep azure-cni

# Check network policies
kubectl get networkpolicies --all-namespaces

# Check service endpoints
kubectl get endpoints --all-namespaces
```

## Step 11: Performance Monitoring

### System Metrics

```bash
# Check CPU usage
top -n 1

# Check memory usage
free -h

# Check disk I/O
iostat -x 1 3

# Check network I/O
sar -n DEV 1 3
```

### Container Metrics

```bash
# Check container resource usage
crictl stats

# Check pod resource usage
kubectl top pods --all-namespaces

# Check node resource usage
kubectl top nodes
```

## Step 12: Cleanup and Best Practices

### Exit Node Shell

```bash
# Exit the node shell
exit
```

### Best Practices for Node Management

1. **Monitoring**: Regularly monitor node health and resource usage
2. **Logging**: Enable and monitor system logs
3. **Security**: Keep nodes updated and secure
4. **Backup**: Backup important node configurations
5. **Documentation**: Document node configurations and changes

## Key Takeaways

1. **AKS nodes run** kubelet, containerd, and Azure-specific components
2. **azure-ip-masq-agent** provides IP masquerading for outbound traffic
3. **coredns** provides DNS resolution for cluster services
4. **coredns-autoscaler** automatically scales DNS based on cluster size
5. **konnectivity** provides secure tunnels for control plane communication
6. **Node exploration** helps understand cluster architecture and troubleshoot issues

## Next Steps
In the next demo, we'll add custom node pools with Azure Mariner images and use node affinity for workload scheduling.

## Troubleshooting

### Common Issues:
1. **Node-shell connection fails**: Check RBAC permissions and node status
2. **Component not running**: Check system pod status and logs
3. **Resource exhaustion**: Monitor node resource usage
4. **Network issues**: Check Azure CNI configuration and logs

### Useful Commands:
```bash
# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check node events
kubectl get events --field-selector involvedObject.kind=Node

# Check component logs
kubectl logs -n kube-system deployment/<component-name>
``` 