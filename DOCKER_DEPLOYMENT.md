# Docker Deployment Instructions

## Build Docker Image

```bash
cd backend
docker build -t image-upload-service:1.0.0 .
```

Or using docker-compose:

```bash
docker-compose build
```

## Run Container Locally

### Option 1: Using Docker directly

```bash
docker run -p 8080:8080 \
  -v $(pwd)/backend/uploads:/app/uploads \
  -e JAVA_OPTS="-Xmx512m -Xms256m" \
  --name image-upload-backend \
  image-upload-service:1.0.0
```

### Option 2: Using docker-compose

```bash
docker-compose up -d
```

## Deploy to Remote Server (192.168.1.251)

### Prerequisites
- Docker and Docker Compose installed on remote server
- SSH access to the server
- Network connectivity to 192.168.1.251

### Step 1: Build Image on Local Machine

```bash
cd backend
docker build -t image-upload-service:1.0.0 .
```

### Step 2: Save and Transfer Image

```bash
# Save the image
docker save image-upload-service:1.0.0 | gzip > image-upload-service-1.0.0.tar.gz

# Transfer to remote server
scp image-upload-service-1.0.0.tar.gz user@192.168.1.251:/home/user/
```

### Step 3: Load and Run on Remote Server

```bash
# SSH into remote server
ssh user@192.168.1.251

# Load the image
docker load < /home/user/image-upload-service-1.0.0.tar.gz

# Run the container
docker run -d \
  -p 8080:8080 \
  -v /data/uploads:/app/uploads \
  -e JAVA_OPTS="-Xmx512m -Xms256m" \
  --name image-upload-backend \
  --restart unless-stopped \
  image-upload-service:1.0.0
```

### Alternative: Use docker-compose on Remote Server

```bash
# Copy docker-compose file
scp docker-compose.yml user@192.168.1.251:/home/user/image-upload-service/

# SSH and deploy
ssh user@192.168.1.251
cd /home/user/image-upload-service
docker-compose up -d
```

## Verify Deployment

```bash
# Check if container is running
docker ps | grep image-upload

# Check logs
docker logs image-upload-backend

# Test API
curl http://192.168.1.251:8080/api/media
```

## View Logs

```bash
docker logs -f image-upload-backend
```

## Stop and Remove Container

```bash
docker stop image-upload-backend
docker rm image-upload-backend
```

## Push to Docker Registry (Optional)

```bash
docker tag image-upload-service:1.0.0 your-registry/image-upload-service:1.0.0
docker push your-registry/image-upload-service:1.0.0
```
