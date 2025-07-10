# Application Modernization with Azure Kubernetes Service - Demo Structure

## Overview
This repository contains a comprehensive set of demos for Application Modernization with Azure Kubernetes Service (AKS). Each demo builds upon the previous one, providing a complete learning path from container fundamentals to advanced AKS features.

## Demo Structure

### Phase 1: Container Fundamentals
1. **01-container-fundamentals** - Docker basics and .NET 9 containerization
2. **02-why-orchestration** - Demonstrating the need for container orchestration
3. **03-kubernetes-basics** - Kubernetes fundamentals with local cluster

### Phase 2: Azure Kubernetes Service (AKS)
4. **04-aks-cluster-setup** - Creating AKS cluster with Azure CNI Overlay
5. **05-aks-node-exploration** - Exploring AKS nodes and components
6. **06-custom-node-pools** - Adding node pools with Azure Mariner

### Phase 3: Application Deployment & Networking
7. **07-basic-deployment** - Deploying .NET 9 application to AKS
8. **08-ingress-controller** - Setting up NGINX ingress with path-based routing
9. **09-tls-certificates** - Implementing TLS with Let's Encrypt

### Phase 4: Security & Access Control
10. **10-rbac-demo** - Kubernetes RBAC with custom roles
11. **11-workload-identity** - Azure Workload Identity integration

### Phase 5: Scaling & Performance
12. **12-scaling-strategies** - Manual, HPA, VPA, and node scaling
13. **13-storage-solutions** - Azure Disk, File, and Blob storage

### Phase 6: Advanced Features
14. **14-gateway-api** - Gateway API and Application Gateway for Containers
15. **15-gitops-flux** - GitOps with Flux v2

## Prerequisites
- Azure CLI
- Docker Desktop
- kubectl
- .NET 9 SDK
- Visual Studio Code or similar IDE

## Getting Started
Each demo folder contains:
- README.md with detailed instructions
- Source code (where applicable)
- YAML manifests
- Scripts for automation

## Learning Path
Follow the demos in numerical order as each builds upon the concepts introduced in previous demos. 