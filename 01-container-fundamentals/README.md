# Demo 01: Container Fundamentals with .NET 9

## Overview
This demo introduces the fundamental concepts of containers and Docker, using a .NET 9 application as an example. You'll learn why containers are essential for application modernization and how to containerize a .NET application.

## Learning Objectives
- Understand what containers are and why they're important
- Learn Docker fundamentals (images, containers, Dockerfile)
- Containerize a .NET 9 application
- Understand container isolation and portability

## Prerequisites
- Docker Desktop installed and running
- .NET 9 SDK installed
- Visual Studio Code or similar IDE

## Step 1: Understanding Containers

### What are Containers?
Containers are lightweight, isolated environments that package applications and their dependencies. They provide:
- **Consistency**: Same environment across development, testing, and production
- **Isolation**: Applications don't interfere with each other
- **Portability**: Run anywhere Docker is available
- **Efficiency**: Share OS kernel, smaller footprint than VMs

### Why Containers for Application Modernization?
- **Legacy Application Migration**: Package existing applications without rewriting
- **Microservices Architecture**: Deploy services independently
- **DevOps Practices**: Consistent environments across the pipeline
- **Cloud-Native Development**: Build for cloud platforms from the start

## Step 2: Creating a .NET 9 Application

Let's create a simple .NET 9 Web API application:

```bash
# Create a new directory for our demo
mkdir 01-container-fundamentals
cd 01-container-fundamentals

# Create a new .NET 9 Web API project
dotnet new webapi -n ContainerDemoApp --framework net9.0

# Navigate to the project
cd ContainerDemoApp
```

## Step 3: Understanding the Application

The generated application includes:
- **WeatherForecastController**: Simple API endpoint
- **Program.cs**: Application entry point
- **appsettings.json**: Configuration
- **ContainerDemoApp.csproj**: Project file

### Key .NET 9 Features Used:
- **Minimal APIs**: Simplified startup and configuration
- **Built-in Dependency Injection**: Service registration
- **Configuration System**: Environment-based settings
- **Logging**: Structured logging with ILogger

## Step 4: Running the Application Locally

```bash
# Build the application
dotnet build

# Run the application
dotnet run
```

The application will be available at `https://localhost:7001` (or similar port).

## Step 5: Understanding Docker Concepts

### Docker Images vs Containers
- **Image**: Template/blueprint containing application code and dependencies
- **Container**: Running instance of an image

### Dockerfile
A text file with instructions to build a Docker image:
- Base image selection
- Copy application files
- Install dependencies
- Configure the environment
- Define startup command

## Step 6: Creating a Dockerfile

Create a `Dockerfile` in the project root:

```dockerfile
# Use the official .NET 9 runtime image
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Use the official .NET 9 SDK image for building
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["ContainerDemoApp.csproj", "./"]
RUN dotnet restore "ContainerDemoApp.csproj"
COPY . .
RUN dotnet build "ContainerDemoApp.csproj" -c Release -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish "ContainerDemoApp.csproj" -c Release -o /app/publish

# Final stage/image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ContainerDemoApp.dll"]
```

### Dockerfile Explanation:
1. **Multi-stage build**: Uses multiple FROM statements for optimization
2. **Base image**: Uses official Microsoft .NET 9 runtime
3. **Build stage**: Compiles the application
4. **Publish stage**: Creates optimized deployment package
5. **Final stage**: Creates minimal runtime image

## Step 7: Building the Docker Image

```bash
# Build the Docker image
docker build -t containerdemoapp:v1 .

# List images to verify
docker images
```

## Step 8: Running the Container

```bash
# Run the container
docker run -d -p 8080:8080 -p 8081:8081 --name demo-app containerdemoapp:v1

# Check running containers
docker ps

# View container logs
docker logs demo-app
```

## Step 9: Testing the Containerized Application

```bash
# Test the API endpoint
curl http://localhost:8080/weatherforecast

# Or use a web browser to visit:
# http://localhost:8080/weatherforecast
```

## Step 10: Container Management Commands

```bash
# Stop the container
docker stop demo-app

# Remove the container
docker rm demo-app

# Remove the image
docker rmi containerdemoapp:v1

# View all containers (including stopped)
docker ps -a

# View container resource usage
docker stats
```

## Step 11: Understanding Container Benefits

### Isolation
```bash
# Run multiple instances on different ports
docker run -d -p 8082:8080 --name demo-app-2 containerdemoapp:v1
docker run -d -p 8083:8080 --name demo-app-3 containerdemoapp:v1
```

### Portability
The same image can run on:
- Developer's laptop
- CI/CD pipeline
- Cloud environments
- Different operating systems

## Step 12: Environment Variables and Configuration

Create a `.dockerignore` file:
```
bin/
obj/
*.user
*.suo
.vscode/
```

Modify the Dockerfile to use environment variables:

```dockerfile
# Add environment variable support
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080;https://+:8081
```

## Step 13: Best Practices

### Security
- Use specific image tags (not `latest`)
- Run containers as non-root user
- Scan images for vulnerabilities
- Keep base images updated

### Optimization
- Use multi-stage builds
- Minimize layer count
- Use .dockerignore
- Optimize for layer caching

## Step 14: Cleanup

```bash
# Stop and remove all containers
docker stop $(docker ps -q)
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Or use docker system prune for a complete cleanup
docker system prune -a
```

## Key Takeaways

1. **Containers provide isolation and consistency** across different environments
2. **Docker images are templates** that can be versioned and shared
3. **Multi-stage builds** optimize image size and build time
4. **Environment variables** allow configuration without rebuilding images
5. **Containers are portable** and can run anywhere Docker is available

## Next Steps
In the next demo, we'll explore why container orchestration is necessary when running multiple containers in production environments.

## Troubleshooting

### Common Issues:
1. **Port conflicts**: Ensure ports aren't already in use
2. **Permission issues**: Run Docker commands with appropriate permissions
3. **Build failures**: Check Dockerfile syntax and file paths
4. **Container won't start**: Check logs with `docker logs <container-name>`

### Useful Commands:
```bash
# Inspect container details
docker inspect <container-name>

# Execute commands in running container
docker exec -it <container-name> /bin/bash

# View container resource usage
docker stats <container-name>
``` 