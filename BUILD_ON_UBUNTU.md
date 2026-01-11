# Building Docker Images on Ubuntu Server (Alternative Approach)

## Overview

Due to Docker Desktop limitations on Windows (build timeouts), this guide provides an alternative approach: **clone the repository on the Ubuntu server and build the images directly there**.

This is actually a better approach for production because:
1. Builds happen on the target platform
2. No need to transfer large compressed images
3. Faster build times with direct dependencies
4. Easier to troubleshoot and rebuild

## Prerequisites

On Ubuntu Server (192.168.1.251):
- Git installed
- Docker installed and running
- Docker Compose installed
- At least 5GB free disk space
- SSH access available

## Step-by-Step Guide

### Step 1: SSH into Ubuntu Server

```bash
ssh root@192.168.1.251
```

### Step 2: Clone the Repository

```bash
cd /root
git clone https://github.com/bharathvu/image-upload-service.git app
cd app
```

Or if you prefer a specific tag:
```bash
git clone -b v1.1.0 https://github.com/bharathvu/image-upload-service.git app
cd app
```

### Step 3: Prepare Build Environment

```bash
# Create data directories for persistence
mkdir -p /data/uploads
mkdir -p /data/mediadb
chmod -R 755 /data

# Verify Docker is running
docker --version
docker-compose --version
```

### Step 4: Build Both Images

**Option A: Build Backend**
```bash
cd /root/app/backend
docker build -t image-upload-service:1.0.0 .

# Verify
docker images | grep image-upload-service
```

**Option B: Build Frontend**
```bash
cd /root/app/frontend
docker build -t image-upload-frontend:1.0.0 .

# Verify
docker images | grep image-upload-frontend
```

**Option C: Build Both (Sequential)**
```bash
cd /root/app

# Build backend
echo "Building backend..."
docker build -t image-upload-service:1.0.0 backend/

# Build frontend
echo "Building frontend..."
docker build -t image-upload-frontend:1.0.0 frontend/

# Verify both
docker images | grep image-upload
```

**Option D: Build Both (Parallel)**
```bash
cd /root/app

# Start backend build in background
docker build -t image-upload-service:1.0.0 backend/ > /tmp/backend-build.log 2>&1 &
BACKEND_PID=$!

# Start frontend build in background
docker build -t image-upload-frontend:1.0.0 frontend/ > /tmp/frontend-build.log 2>&1 &
FRONTEND_PID=$!

# Wait for both to complete
wait $BACKEND_PID $FRONTEND_PID

# Check results
echo "Backend build status: $?"
echo "Frontend build status: $?"

# View logs if needed
# tail -50 /tmp/backend-build.log
# tail -50 /tmp/frontend-build.log

# Verify both images exist
docker images | grep image-upload
```

### Step 5: Deploy with Docker Compose

```bash
cd /root/app

# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### Step 6: Verify Deployment

```bash
# Check if containers are running
docker ps | grep image-upload

# Test backend API
curl http://localhost:8080/api/media
# Should return: []

# Test frontend (from your local machine)
curl http://192.168.1.251/
# Should return HTML

# Health check
curl http://192.168.1.251/health.html
# Should return: OK
```

## Build Output Examples

### Successful Backend Build

```
[+] Building 180.3s (16/16) FINISHED
 => [internal] load build definition from Dockerfile
 => [builder 1/6] FROM maven:3.9-eclipse-temurin-17-alpine
 => [builder 2/6] WORKDIR /app
 => [builder 3/6] COPY pom.xml .
 => [builder 4/6] RUN mvn dependency:go-offline -B
 => [builder 5/6] COPY src ./src
 => [builder 6/6] RUN mvn clean package -DskipTests
 => [stage-1 1/4] FROM eclipse-temurin:17-jdk-alpine
 => [stage-1 2/4] WORKDIR /app
 => [stage-1 3/4] COPY --from=builder /app/target/*.jar app.jar
 => [stage-1 4/4] RUN mkdir -p /app/uploads/images /app/uploads/videos
 => exporting to image
 => => writing image sha256:...
 => => naming to docker.io/library/image-upload-service:1.0.0
```

### Successful Frontend Build

```
[+] Building 150.2s (15/15) FINISHED
 => [internal] load build definition from Dockerfile
 => [builder 1/7] FROM node:18-alpine
 => [builder 2/7] WORKDIR /app
 => [builder 3/7] COPY package.json package-lock.json ./
 => [builder 4/7] RUN npm install --legacy-peer-deps
 => [builder 5/7] COPY public ./public
 => [builder 6/7] COPY src ./src
 => [builder 7/7] RUN npm run build
 => [stage-1 1/4] FROM nginx:alpine
 => [stage-1 2/4] RUN rm /etc/nginx/conf.d/default.conf
 => [stage-1 3/4] COPY nginx.conf /etc/nginx/conf.d/default.conf
 => [stage-1 4/4] COPY --from=builder /app/build /usr/share/nginx/html
 => exporting to image
 => => writing image sha256:...
 => => naming to docker.io/library/image-upload-frontend:1.0.0
```

## Troubleshooting

### Issue: "npm: command not found" during frontend build

**Cause:** Node.js not available in Docker Alpine image path

**Solution:** The Dockerfile includes `node:18-alpine` which has npm. The error should not occur. If it does, ensure the Dockerfile is correct.

### Issue: Maven Central not accessible

**Cause:** Network issues downloading Maven dependencies

**Solution:**
```bash
# Try building again
docker build --no-cache -t image-upload-service:1.0.0 backend/

# Or check internet connectivity
curl https://repo.maven.apache.org/maven2/
```

### Issue: "No space left on device"

**Cause:** Docker images and build artifacts consume disk space

**Solution:**
```bash
# Check disk space
df -h /

# Clean up Docker resources
docker system prune -a

# Free up more space if needed
rm -rf /data/* # WARNING: This deletes uploaded media!
```

### Issue: Docker daemon not responding

**Cause:** Docker service not running

**Solution:**
```bash
# Check Docker status
sudo systemctl status docker

# Start Docker if stopped
sudo systemctl start docker

# Enable auto-start
sudo systemctl enable docker
```

### Issue: Permission denied errors

**Cause:** User doesn't have Docker permissions

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply group membership
newgrp docker

# Or use sudo
sudo docker build ...
```

## Monitoring Build Progress

### Watch Real-time Build Logs

```bash
# In one terminal, start the build
docker build -t image-upload-service:1.0.0 backend/

# In another terminal, watch Docker events
docker events --filter type=image
```

### Check Build Status

```bash
# List all images
docker images

# View specific image details
docker image inspect image-upload-service:1.0.0 | jq '.[] | {Created, Size, RepoTags}'
```

### Build Statistics

```bash
# Image sizes
docker images --format "table {{.Repository}}\t{{.Size}}"

# Disk usage
docker system df
```

## Managing Built Images

### Save Images for Backup

```bash
# Export both images
docker save image-upload-service:1.0.0 | gzip > /root/image-upload-service-1.0.0.tar.gz
docker save image-upload-frontend:1.0.0 | gzip > /root/image-upload-frontend-1.0.0.tar.gz

# List saved files
ls -lh /root/image-upload-*.tar.gz
```

### Load from Backup

```bash
docker load < /root/image-upload-service-1.0.0.tar.gz
docker load < /root/image-upload-frontend-1.0.0.tar.gz
```

### Push to Docker Registry (Optional)

```bash
# Tag for registry (e.g., Docker Hub)
docker tag image-upload-service:1.0.0 yourusername/image-upload-service:1.0.0
docker tag image-upload-frontend:1.0.0 yourusername/image-upload-frontend:1.0.0

# Login to Docker Hub
docker login

# Push images
docker push yourusername/image-upload-service:1.0.0
docker push yourusername/image-upload-frontend:1.0.0
```

## Performance Tips

### Speed Up Builds

```bash
# Use BuildKit for faster, more efficient builds
DOCKER_BUILDKIT=1 docker build -t image-upload-service:1.0.0 backend/

# Build with reduced cache layers
docker build --no-cache -t image-upload-service:1.0.0 backend/

# Parallel builds with job control
docker build -t image-upload-service:1.0.0 --build-arg JAVA_TOOL_OPTIONS="-XX:+UseG1GC" backend/
```

### Reduce Image Size

Current sizes:
- Backend: ~300MB (Maven builder stage + OpenJDK runtime)
- Frontend: ~100MB (Node builder stage + Nginx runtime)

To reduce further:
- Switch to `eclipse-temurin:17-jre-alpine` (JRE only, no dev tools)
- Use multi-stage builds more aggressively
- Minimize npm dependencies in frontend

## Next Steps

After successful builds:

1. **Verify Running Services**
   ```bash
   docker-compose ps
   curl http://localhost/health.html
   curl http://localhost:8080/api/media
   ```

2. **Configure Auto-start**
   ```bash
   # Edit docker-compose service to auto-start
   # Add systemd service or cron job
   ```

3. **Set Up Monitoring**
   ```bash
   # Monitor logs
   docker-compose logs -f

   # Monitor resources
   docker stats
   ```

4. **Backup Configuration**
   ```bash
   cp /root/app/docker-compose.yml /root/app/docker-compose.yml.bak
   ```

## Quick Command Reference

```bash
# Build both images
cd /root/app && docker build -t image-upload-service:1.0.0 backend/ && docker build -t image-upload-frontend:1.0.0 frontend/

# Deploy
docker-compose up -d

# View status
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Remove all images
docker rmi image-upload-service:1.0.0 image-upload-frontend:1.0.0
```

---

**Estimated Build Times on Ubuntu:**
- Backend: 2-5 minutes (Maven compile + package)
- Frontend: 1-3 minutes (npm install + React build)
- Total: 3-8 minutes depending on network and CPU
