# Application Modernization with Azure Kubernetes Service (AKS)

A comprehensive hands-on learning path for modernizing applications using Azure Kubernetes Service. This repository contains 15 detailed demos that build upon each other, covering everything from container fundamentals to advanced AKS features.

## 🎯 Learning Objectives

By completing these demos, you will learn:

- **Container Fundamentals**: Docker basics and .NET 9 containerization
- **Container Orchestration**: Why Kubernetes is essential for production workloads
- **Kubernetes Basics**: Core concepts and local cluster management
- **AKS Architecture**: Azure-specific Kubernetes features and components
- **Advanced AKS Features**: Node pools, networking, security, scaling, and GitOps
- **Production-Ready Deployments**: Ingress controllers, TLS, monitoring, and storage

## 📋 Prerequisites

Before starting, ensure you have the following installed:

- **.NET 9 SDK**: [Download here](https://dotnet.microsoft.com/download/dotnet/9.0)
- **Docker Desktop**: [Download here](https://www.docker.com/products/docker-desktop)
- **Azure CLI**: [Download here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **kubectl**: [Download here](https://kubernetes.io/docs/tasks/tools/)
- **Visual Studio Code** (recommended): [Download here](https://code.visualstudio.com/)

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd LetsLearnAKS

# Run the automated setup script
./setup-demos.sh setup-all

# Run individual demos
./setup-demos.sh run-demo 1  # Container Fundamentals
./setup-demos.sh run-demo 2  # Why Container Orchestration
# ... continue with other demos
```

### Option 2: Manual Setup

```bash
# Check prerequisites
./setup-demos.sh check-prereqs

# Install missing tools
./setup-demos.sh install-tools

# Setup Azure environment
./setup-demos.sh setup-azure

# Setup Docker environment
./setup-demos.sh setup-docker

# Build application
./setup-demos.sh build-app

# Create AKS cluster
./setup-demos.sh create-cluster
```

## 📚 Demo Structure

### Phase 1: Container Fundamentals
1. **[01-container-fundamentals](01-container-fundamentals/README.md)** - Docker basics and .NET 9 containerization
2. **[02-why-orchestration](02-why-orchestration/README.md)** - Demonstrating the need for container orchestration
3. **[03-kubernetes-basics](03-kubernetes-basics/README.md)** - Kubernetes fundamentals with local cluster

### Phase 2: Azure Kubernetes Service (AKS)
4. **[04-aks-cluster-setup](04-aks-cluster-setup/README.md)** - Creating AKS cluster with Azure CNI Overlay
5. **[05-aks-node-exploration](05-aks-node-exploration/README.md)** - Exploring AKS nodes and components
6. **[06-custom-node-pools](06-custom-node-pools/README.md)** - Adding node pools with Azure Mariner

### Phase 3: Application Deployment & Networking
7. **[07-basic-deployment](07-basic-deployment/README.md)** - Deploying .NET 9 application to AKS
8. **[08-ingress-controller](08-ingress-controller/README.md)** - Setting up NGINX ingress with path-based routing
9. **[09-tls-certificates](09-tls-certificates/README.md)** - Implementing TLS with Let's Encrypt

### Phase 4: Security & Access Control
10. **[10-rbac-demo](10-rbac-demo/README.md)** - Kubernetes RBAC with custom roles
11. **[11-workload-identity](11-workload-identity/README.md)** - Azure Workload Identity integration

### Phase 5: Scaling & Performance
12. **[12-scaling-strategies](12-scaling-strategies/README.md)** - Manual, HPA, VPA, and node scaling
13. **[13-storage-solutions](13-storage-solutions/README.md)** - Azure Disk, File, and Blob storage

### Phase 6: Advanced Features
14. **[14-gateway-api](14-gateway-api/README.md)** - Gateway API and Application Gateway for Containers
15. **[15-gitops-flux](15-gitops-flux/README.md)** - GitOps with Flux v2

## 🏗️ Architecture Overview

### Demo Application
The demos use a .NET 9 Web API application that demonstrates:
- **Weather Forecast API**: Simple REST endpoints
- **Health Checks**: Kubernetes-ready health endpoints
- **Configuration Management**: Environment-based settings
- **Logging**: Structured logging with ILogger
- **Containerization**: Multi-stage Docker builds

### AKS Cluster Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Kubernetes Service                 │
├─────────────────────────────────────────────────────────────┤
│  Managed Control Plane (Azure Managed)                     │
│  ├── API Server                                            │
│  ├── etcd                                                  │
│  ├── Scheduler                                             │
│  └── Controller Manager                                    │
├─────────────────────────────────────────────────────────────┤
│  Node Pools                                                │
│  ├── System Node Pool (Ubuntu)                             │
│  ├── User Node Pool (Azure Mariner)                        │
│  └── Spot Instance Pool (Cost Optimization)                │
├─────────────────────────────────────────────────────────────┤
│  Azure Integration                                         │
│  ├── Azure CNI Overlay                                     │
│  ├── Azure Load Balancer                                   │
│  ├── Azure Disk/File Storage                               │
│  └── Azure Monitor                                         │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ Key Technologies Covered

### Container Technologies
- **Docker**: Container runtime and image management
- **.NET 9**: Modern .NET application development
- **Multi-stage Builds**: Optimized container images

### Kubernetes
- **Pods, Deployments, Services**: Core Kubernetes resources
- **ConfigMaps & Secrets**: Configuration management
- **Namespaces**: Resource isolation
- **RBAC**: Role-based access control

### Azure Services
- **AKS**: Managed Kubernetes service
- **Azure CNI Overlay**: Advanced networking
- **Azure Mariner**: Container-optimized OS
- **Azure Load Balancer**: Load balancing
- **Azure Monitor**: Monitoring and logging
- **Azure Key Vault**: Secret management
- **Azure Container Registry**: Container image storage

### Advanced Features
- **Ingress Controllers**: NGINX and Application Gateway
- **TLS/SSL**: Certificate management with Let's Encrypt
- **Horizontal Pod Autoscaler**: Automatic scaling
- **GitOps**: Flux v2 for declarative deployments
- **Gateway API**: Next-generation ingress

## 📖 Learning Path

### Beginner Level (Demos 1-3)
Start here if you're new to containers and Kubernetes:
- Learn container fundamentals with Docker
- Understand why orchestration is needed
- Get hands-on with local Kubernetes

### Intermediate Level (Demos 4-8)
Build on your foundation with AKS:
- Create and manage AKS clusters
- Explore Azure-specific features
- Deploy applications to production

### Advanced Level (Demos 9-15)
Master advanced AKS features:
- Implement security and compliance
- Optimize performance and scaling
- Deploy with GitOps practices

## 🔧 Setup Script Commands

The `setup-demos.sh` script provides several useful commands:

```bash
# Check if all prerequisites are installed
./setup-demos.sh check-prereqs

# Install missing tools automatically
./setup-demos.sh install-tools

# Setup Azure environment (login, extensions)
./setup-demos.sh setup-azure

# Setup Docker environment
./setup-demos.sh setup-docker

# Create environment variables
./setup-demos.sh setup-env

# Build the .NET 9 application
./setup-demos.sh build-app

# Create AKS cluster
./setup-demos.sh create-cluster

# Run a specific demo
./setup-demos.sh run-demo <number>

# Complete setup (recommended for first-time users)
./setup-demos.sh setup-all
```

## 💰 Cost Considerations

### Azure Resources Created
- **AKS Cluster**: ~$150-300/month (depending on node count and VM size)
- **Load Balancer**: ~$20/month
- **Container Registry**: ~$5-20/month (depending on usage)
- **Storage**: ~$10-50/month (depending on usage)

### Cost Optimization Tips
1. **Use Spot Instances**: For non-critical workloads (up to 90% savings)
2. **Enable Cluster Autoscaler**: Scale down during low usage
3. **Choose Appropriate VM Sizes**: Right-size your workloads
4. **Clean Up Resources**: Delete clusters when not in use
5. **Use Azure Dev/Test Subscriptions**: For learning and development

## 🔒 Security Best Practices

### Implemented in Demos
- **Azure RBAC**: Role-based access control
- **Network Policies**: Pod-to-pod communication control
- **Secrets Management**: Secure configuration storage
- **Workload Identity**: Azure service authentication
- **TLS Encryption**: Secure communication

### Additional Recommendations
- **Pod Security Policies**: Enforce security standards
- **Image Scanning**: Scan container images for vulnerabilities
- **Regular Updates**: Keep clusters and images updated
- **Audit Logging**: Monitor cluster activities

## 🚨 Troubleshooting

### Common Issues

#### Prerequisites
```bash
# Check .NET version
dotnet --version

# Check Docker status
docker info

# Check Azure CLI
az version

# Check kubectl
kubectl version --client
```

#### AKS Cluster Issues
```bash
# Get cluster status
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Get cluster credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Check node status
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

#### Application Issues
```bash
# Check pod status
kubectl get pods

# Check pod logs
kubectl logs <pod-name>

# Check pod events
kubectl describe pod <pod-name>

# Check service status
kubectl get services
```

### Getting Help
- **Azure Documentation**: [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- **Kubernetes Documentation**: [Kubernetes.io](https://kubernetes.io/docs/)
- **Docker Documentation**: [Docker.com](https://docs.docker.com/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Contributing Guidelines
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Update documentation
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Microsoft Azure**: For providing AKS and related services
- **Kubernetes Community**: For the amazing orchestration platform
- **Docker**: For containerization technology
- **.NET Team**: For the excellent .NET 9 framework

## 📞 Support

If you encounter any issues or have questions:

1. **Check the troubleshooting section** above
2. **Review the demo-specific README files** for detailed instructions
3. **Open an issue** on GitHub with detailed information
4. **Check Azure status** at [Azure Status](https://status.azure.com/)

---

**Happy Learning! 🚀**

Start with [Demo 01: Container Fundamentals](01-container-fundamentals/README.md) and work your way through the learning path. Each demo builds upon the previous one, so follow them in order for the best learning experience.











