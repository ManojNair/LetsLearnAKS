#!/bin/bash

# Application Modernization with Azure Kubernetes Service - Demo Setup Script
# This script helps you set up your environment and run the demos

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check .NET 9 SDK
    if ! command_exists dotnet; then
        missing_tools+=("dotnet")
    else
        DOTNET_VERSION=$(dotnet --version)
        if [[ ! "$DOTNET_VERSION" =~ ^9\. ]]; then
            print_warning ".NET 9 SDK not found. Current version: $DOTNET_VERSION"
            missing_tools+=("dotnet9")
        else
            print_success ".NET 9 SDK found: $DOTNET_VERSION"
        fi
    fi
    
    # Check Docker
    if ! command_exists docker; then
        missing_tools+=("docker")
    else
        print_success "Docker found: $(docker --version)"
    fi
    
    # Check Azure CLI
    if ! command_exists az; then
        missing_tools+=("azure-cli")
    else
        print_success "Azure CLI found: $(az version --query '"azure-cli"' -o tsv)"
    fi
    
    # Check kubectl
    if ! command_exists kubectl; then
        missing_tools+=("kubectl")
    else
        print_success "kubectl found: $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
    fi
    
    # Check jq (for JSON parsing)
    if ! command_exists jq; then
        missing_tools+=("jq")
    else
        print_success "jq found"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing tools: ${missing_tools[*]}"
        print_status "Please install the missing tools before proceeding."
        return 1
    fi
    
    print_success "All prerequisites are satisfied!"
    return 0
}

# Function to install missing tools
install_tools() {
    print_status "Installing missing tools..."
    
    local os=$(uname -s)
    
    case $os in
        Darwin*) # macOS
            if command_exists brew; then
                print_status "Using Homebrew to install tools..."
                brew install azure-cli kubectl jq
            else
                print_error "Homebrew not found. Please install Homebrew first: https://brew.sh/"
                return 1
            fi
            ;;
        Linux*)
            if command_exists apt-get; then
                print_status "Using apt-get to install tools..."
                sudo apt-get update
                sudo apt-get install -y azure-cli kubectl jq
            elif command_exists yum; then
                print_status "Using yum to install tools..."
                sudo yum install -y azure-cli kubectl jq
            else
                print_error "Unsupported package manager. Please install tools manually."
                return 1
            fi
            ;;
        *)
            print_error "Unsupported operating system: $os"
            return 1
            ;;
    esac
}

# Function to setup Azure environment
setup_azure() {
    print_status "Setting up Azure environment..."
    
    # Check if already logged in
    if az account show >/dev/null 2>&1; then
        print_success "Already logged into Azure"
        CURRENT_SUBSCRIPTION=$(az account show --query name -o tsv)
        print_status "Current subscription: $CURRENT_SUBSCRIPTION"
    else
        print_status "Logging into Azure..."
        az login
    fi
    
    # List subscriptions
    print_status "Available subscriptions:"
    az account list --output table
    
    # Ask user to select subscription
    read -p "Enter subscription ID (or press Enter to use current): " SUBSCRIPTION_ID
    
    if [ -n "$SUBSCRIPTION_ID" ]; then
        az account set --subscription "$SUBSCRIPTION_ID"
        print_success "Switched to subscription: $SUBSCRIPTION_ID"
    fi
    
    # Install AKS CLI extensions
    print_status "Installing AKS CLI extensions..."
    az extension add --name aks-preview --yes
    az extension update --name aks-preview
    
    # Install kubectl if not already installed
    if ! command_exists kubectl; then
        print_status "Installing kubectl..."
        az aks install-cli
    fi
}

# Function to setup Docker environment
setup_docker() {
    print_status "Setting up Docker environment..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop or Docker daemon."
        return 1
    fi
    
    # Enable Kubernetes in Docker Desktop (macOS/Windows)
    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        print_status "Checking Docker Desktop Kubernetes..."
        if ! kubectl cluster-info >/dev/null 2>&1; then
            print_warning "Kubernetes not enabled in Docker Desktop. Please enable it manually:"
            print_status "1. Open Docker Desktop"
            print_status "2. Go to Settings → Kubernetes"
            print_status "3. Check 'Enable Kubernetes'"
            print_status "4. Click 'Apply & Restart'"
        else
            print_success "Docker Desktop Kubernetes is enabled"
        fi
    fi
}

# Function to create demo environment variables
setup_environment() {
    print_status "Setting up environment variables..."
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        cat > .env << EOF
# Azure Configuration
RESOURCE_GROUP="aks-demo-rg"
LOCATION="eastus"
CLUSTER_NAME="aks-demo-cluster"

# Node Pool Configuration
NODE_COUNT=3
VM_SIZE="Standard_DS2_v2"

# Application Configuration
APP_NAME="containerdemoapp"
APP_VERSION="v1"
NAMESPACE="demo-apps"

# Registry Configuration (optional)
REGISTRY_NAME=""
REGISTRY_LOGIN_SERVER=""
EOF
        print_success "Created .env file with default values"
    else
        print_status ".env file already exists"
    fi
    
    # Source the environment file
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
        print_success "Environment variables loaded"
    fi
}

# Function to build .NET 9 application
build_application() {
    print_status "Building .NET 9 application..."
    
    if [ ! -d "01-container-fundamentals/ContainerDemoApp" ]; then
        print_error "Application directory not found. Please run the demos in order."
        return 1
    fi
    
    cd 01-container-fundamentals/ContainerDemoApp
    
    # Build the application
    print_status "Building application..."
    dotnet build
    
    # Build Docker image
    print_status "Building Docker image..."
    docker build -t $APP_NAME:$APP_VERSION .
    
    # Tag for Azure Container Registry if configured
    if [ -n "$REGISTRY_LOGIN_SERVER" ]; then
        docker tag $APP_NAME:$APP_VERSION $REGISTRY_LOGIN_SERVER/$APP_NAME:$APP_VERSION
        print_status "Image tagged for registry: $REGISTRY_LOGIN_SERVER/$APP_NAME:$APP_VERSION"
    fi
    
    cd ../..
    print_success "Application built successfully"
}

# Function to create AKS cluster
create_aks_cluster() {
    print_status "Creating AKS cluster..."
    
    # Check if cluster already exists
    if az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME >/dev/null 2>&1; then
        print_warning "AKS cluster already exists: $CLUSTER_NAME"
        read -p "Do you want to use existing cluster? (y/n): " USE_EXISTING
        if [[ $USE_EXISTING =~ ^[Yy]$ ]]; then
            print_status "Using existing cluster"
            return 0
        else
            print_status "Deleting existing cluster..."
            az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --yes
        fi
    fi
    
    # Create resource group
    print_status "Creating resource group: $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
    
    # Create VNET
    print_status "Creating virtual network..."
    VNET_NAME="aks-vnet"
    SUBNET_NAME="aks-subnet"
    VNET_ADDRESS_PREFIX="10.0.0.0/16"
    SUBNET_ADDRESS_PREFIX="10.0.1.0/24"
    
    az network vnet create \
        --resource-group $RESOURCE_GROUP \
        --name $VNET_NAME \
        --address-prefix $VNET_ADDRESS_PREFIX \
        --subnet-name $SUBNET_NAME \
        --subnet-prefix $SUBNET_ADDRESS_PREFIX
    
    SUBNET_ID=$(az network vnet subnet show \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME \
        --name $SUBNET_NAME \
        --query id -o tsv)
    
    # Create AKS cluster
    print_status "Creating AKS cluster: $CLUSTER_NAME"
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
    print_status "Getting cluster credentials..."
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
    
    print_success "AKS cluster created successfully"
}

# Function to run specific demo
run_demo() {
    local demo_number=$1
    
    case $demo_number in
        1)
            print_status "Running Demo 01: Container Fundamentals"
            cd 01-container-fundamentals
            print_status "Please follow the README.md instructions"
            ;;
        2)
            print_status "Running Demo 02: Why Container Orchestration"
            cd 02-why-orchestration
            print_status "Please follow the README.md instructions"
            ;;
        3)
            print_status "Running Demo 03: Kubernetes Fundamentals"
            cd 03-kubernetes-basics
            print_status "Please follow the README.md instructions"
            ;;
        4)
            print_status "Running Demo 04: AKS Cluster Setup"
            cd 04-aks-cluster-setup
            print_status "Please follow the README.md instructions"
            ;;
        5)
            print_status "Running Demo 05: AKS Node Exploration"
            cd 05-aks-node-exploration
            print_status "Please follow the README.md instructions"
            ;;
        6)
            print_status "Running Demo 06: Custom Node Pools"
            cd 06-custom-node-pools
            print_status "Please follow the README.md instructions"
            ;;
        *)
            print_error "Invalid demo number: $demo_number"
            return 1
            ;;
    esac
}

# Function to show help
show_help() {
    echo "Application Modernization with Azure Kubernetes Service - Demo Setup"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  check-prereqs    Check if all prerequisites are installed"
    echo "  install-tools    Install missing tools"
    echo "  setup-azure      Setup Azure environment"
    echo "  setup-docker     Setup Docker environment"
    echo "  setup-env        Setup environment variables"
    echo "  build-app        Build .NET 9 application"
    echo "  create-cluster   Create AKS cluster"
    echo "  run-demo <num>   Run specific demo (1-6)"
    echo "  setup-all        Run complete setup"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 check-prereqs"
    echo "  $0 setup-all"
    echo "  $0 run-demo 1"
}

# Main script logic
main() {
    case "${1:-help}" in
        check-prereqs)
            check_prerequisites
            ;;
        install-tools)
            install_tools
            ;;
        setup-azure)
            setup_azure
            ;;
        setup-docker)
            setup_docker
            ;;
        setup-env)
            setup_environment
            ;;
        build-app)
            setup_environment
            build_application
            ;;
        create-cluster)
            setup_environment
            create_aks_cluster
            ;;
        run-demo)
            if [ -z "$2" ]; then
                print_error "Demo number required"
                show_help
                exit 1
            fi
            run_demo $2
            ;;
        setup-all)
            print_status "Running complete setup..."
            check_prerequisites || install_tools
            setup_azure
            setup_docker
            setup_environment
            build_application
            create_aks_cluster
            print_success "Setup completed successfully!"
            print_status "You can now run individual demos using: $0 run-demo <number>"
            ;;
        help|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@" 