#!/bin/bash
# Docker build and deployment script for Linux/Mac

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
IMAGE_NAME="image-upload-service"
IMAGE_TAG="1.0.0"
REMOTE_SERVER="192.168.1.251"
REMOTE_USER="root"

echo "========================================="
echo "Docker Build and Deployment Script"
echo "========================================="

# Build Docker image
echo ""
echo "Step 1: Building Docker image..."
cd "$BACKEND_DIR"
docker build -t "$IMAGE_NAME:$IMAGE_TAG" .

if [ $? -eq 0 ]; then
    echo "✓ Image built successfully: $IMAGE_NAME:$IMAGE_TAG"
else
    echo "✗ Error building image"
    exit 1
fi

# Save image
echo ""
echo "Step 2: Saving Docker image..."
docker save "$IMAGE_NAME:$IMAGE_TAG" | gzip > "$PROJECT_DIR/$IMAGE_NAME-$IMAGE_TAG.tar.gz"
echo "✓ Image saved to: $PROJECT_DIR/$IMAGE_NAME-$IMAGE_TAG.tar.gz"

# Option to deploy to remote server
read -p "Deploy to remote server ($REMOTE_SERVER)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Step 3: Transferring image to remote server..."
    scp "$PROJECT_DIR/$IMAGE_NAME-$IMAGE_TAG.tar.gz" "$REMOTE_USER@$REMOTE_SERVER:/tmp/"
    echo "✓ Image transferred"
    
    echo ""
    echo "Step 4: Loading image on remote server..."
    ssh "$REMOTE_USER@$REMOTE_SERVER" "docker load < /tmp/$IMAGE_NAME-$IMAGE_TAG.tar.gz"
    echo "✓ Image loaded on remote server"
    
    echo ""
    echo "Step 5: Starting container on remote server..."
    ssh "$REMOTE_USER@$REMOTE_SERVER" "
        mkdir -p /data/uploads/{images,videos}
        docker run -d \
          -p 8080:8080 \
          -v /data/uploads:/app/uploads \
          -e JAVA_OPTS='-Xmx512m -Xms256m' \
          --name image-upload-backend \
          --restart unless-stopped \
          $IMAGE_NAME:$IMAGE_TAG
    "
    echo "✓ Container started on remote server"
    
    echo ""
    echo "Step 6: Verifying deployment..."
    sleep 5
    ssh "$REMOTE_USER@$REMOTE_SERVER" "docker ps | grep image-upload"
    
    echo ""
    echo "========================================="
    echo "✓ Deployment successful!"
    echo "========================================="
    echo "Backend available at: http://$REMOTE_SERVER:8080"
    echo "API available at: http://$REMOTE_SERVER:8080/api"
    echo ""
    echo "View logs: ssh $REMOTE_USER@$REMOTE_SERVER 'docker logs -f image-upload-backend'"
fi

echo ""
echo "Done!"
