#!/bin/bash

# Full Stack Docker Deployment to Ubuntu Server 192.168.1.251
# This script builds, exports, and deploys both frontend and backend Docker images

set -e

PROJECT_DIR="/c/Users/bhara/Downloads/prog-space/java/image-upload-service"
BACKEND_VERSION="1.0.0"
FRONTEND_VERSION="1.0.0"
REMOTE_HOST="root@192.168.1.251"
REMOTE_TMP="/tmp"
REMOTE_APP="/root/app"

echo "=========================================="
echo "Image Upload Service - Full Stack Deploy"
echo "=========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Build Backend Image
log_info "Step 1/6: Building backend Docker image..."
cd "$PROJECT_DIR/backend"
if docker build -t image-upload-service:$BACKEND_VERSION .; then
    log_info "✓ Backend image built successfully"
else
    log_error "Failed to build backend image"
    exit 1
fi

# Step 2: Build Frontend Image
log_info "Step 2/6: Building frontend Docker image..."
cd "$PROJECT_DIR/frontend"
if docker build -t image-upload-frontend:$FRONTEND_VERSION .; then
    log_info "✓ Frontend image built successfully"
else
    log_error "Failed to build frontend image"
    exit 1
fi

# Step 3: Export Images
log_info "Step 3/6: Exporting Docker images..."
cd "$PROJECT_DIR"

log_info "  - Exporting backend image..."
if docker save image-upload-service:$BACKEND_VERSION | gzip > image-upload-service-$BACKEND_VERSION.tar.gz; then
    BACKEND_SIZE=$(ls -lh image-upload-service-$BACKEND_VERSION.tar.gz | awk '{print $5}')
    log_info "  ✓ Backend image exported: $BACKEND_SIZE"
else
    log_error "Failed to export backend image"
    exit 1
fi

log_info "  - Exporting frontend image..."
if docker save image-upload-frontend:$FRONTEND_VERSION | gzip > image-upload-frontend-$FRONTEND_VERSION.tar.gz; then
    FRONTEND_SIZE=$(ls -lh image-upload-frontend-$FRONTEND_VERSION.tar.gz | awk '{print $5}')
    log_info "  ✓ Frontend image exported: $FRONTEND_SIZE"
else
    log_error "Failed to export frontend image"
    exit 1
fi

# Step 4: Transfer Images
log_info "Step 4/6: Transferring images to remote server..."
log_warn "Make sure SSH access is configured for $REMOTE_HOST"

log_info "  - Transferring backend image..."
if scp image-upload-service-$BACKEND_VERSION.tar.gz $REMOTE_HOST:$REMOTE_TMP/; then
    log_info "  ✓ Backend image transferred"
else
    log_error "Failed to transfer backend image"
    exit 1
fi

log_info "  - Transferring frontend image..."
if scp image-upload-frontend-$FRONTEND_VERSION.tar.gz $REMOTE_HOST:$REMOTE_TMP/; then
    log_info "  ✓ Frontend image transferred"
else
    log_error "Failed to transfer frontend image"
    exit 1
fi

# Step 5: Load Images on Remote Server
log_info "Step 5/6: Loading images on remote server..."

REMOTE_COMMANDS="
cd $REMOTE_TMP
docker load < image-upload-service-$BACKEND_VERSION.tar.gz
docker load < image-upload-frontend-$FRONTEND_VERSION.tar.gz
rm image-upload-*.tar.gz
mkdir -p /data/uploads /data/mediadb
chmod -R 755 /data
docker images | grep image-upload
"

if ssh $REMOTE_HOST bash -c "$REMOTE_COMMANDS"; then
    log_info "✓ Images loaded successfully on remote server"
else
    log_error "Failed to load images on remote server"
    exit 1
fi

# Step 6: Deploy with Docker Compose
log_info "Step 6/6: Deploying containers..."

# Create docker-compose.yml on remote if it doesn't exist
if ! ssh $REMOTE_HOST "[ -f $REMOTE_APP/docker-compose.yml ]"; then
    log_info "  - Creating docker-compose.yml on remote server..."
    COMPOSE_CONFIG='version: '"'"'3.8'"'"'

services:
  image-upload-frontend:
    image: image-upload-frontend:'"'"'1.0.0'"'"'
    ports:
      - "80:80"
    depends_on:
      - image-upload-backend
    networks:
      - app-network
    restart: always
    container_name: image-upload-frontend

  image-upload-backend:
    image: image-upload-service:'"'"'1.0.0'"'"'
    ports:
      - "8080:8080"
    environment:
      - JAVA_OPTS=-Xmx1024m -Xms512m
      - file.upload-dir=/app/uploads
    volumes:
      - /data/uploads:/app/uploads
      - /data/mediadb:/app/data
    networks:
      - app-network
    restart: always
    container_name: image-upload-backend

networks:
  app-network:
    driver: bridge'

    ssh $REMOTE_HOST "mkdir -p $REMOTE_APP && cat > $REMOTE_APP/docker-compose.yml << 'EOF'
$COMPOSE_CONFIG
EOF"
fi

# Start containers
if ssh $REMOTE_HOST "cd $REMOTE_APP && docker-compose up -d"; then
    log_info "✓ Containers deployed successfully"
else
    log_error "Failed to deploy containers"
    exit 1
fi

# Verify Deployment
log_info "Verifying deployment..."

VERIFY_COMMANDS="
sleep 5
echo 'Container Status:'
docker-compose ps
echo ''
echo 'Container Health:'
docker ps --format 'table {{.Names}}\t{{.Status}}'
"

ssh $REMOTE_HOST "cd $REMOTE_APP && bash -c '$VERIFY_COMMANDS'"

# Final Summary
echo ""
log_info "=========================================="
log_info "✓ Deployment Complete!"
log_info "=========================================="
echo ""
echo "Frontend URL: http://192.168.1.251"
echo "Backend API: http://192.168.1.251:8080/api"
echo "Health Check: http://192.168.1.251/health.html"
echo ""
echo "SSH into server:"
echo "  ssh $REMOTE_HOST"
echo "  cd $REMOTE_APP"
echo ""
echo "View logs:"
echo "  docker-compose logs -f"
echo ""
echo "Stop services:"
echo "  docker-compose stop"
echo ""
echo "Start services:"
echo "  docker-compose up -d"
echo ""
