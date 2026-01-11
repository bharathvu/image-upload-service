# Deployment Guide to 192.168.1.251

## Prerequisites

Ensure the following is installed on the remote server (192.168.1.251):

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

## Deployment Steps

### Step 1: Build Docker Image Locally

On your local machine (Windows):

```bash
cd backend
docker build -t image-upload-service:1.0.0 .
```

**Note**: If Docker is not running, start Docker Desktop first.

### Step 2: Save Image for Transfer

```bash
docker save image-upload-service:1.0.0 | gzip > image-upload-service-1.0.0.tar.gz
```

### Step 3: Transfer to Remote Server

```bash
# Windows: Use SCP or WinSCP
scp image-upload-service-1.0.0.tar.gz root@192.168.1.251:/tmp/

# Or using Windows PowerShell
$source = "C:\Users\bhara\Downloads\prog-space\java\image-upload-service\image-upload-service-1.0.0.tar.gz"
$destination = "root@192.168.1.251:/tmp/"
scp $source $destination
```

### Step 4: SSH into Remote Server and Deploy

```bash
ssh root@192.168.1.251

# Load Docker image
docker load < /tmp/image-upload-service-1.0.0.tar.gz

# Create directories for volumes
mkdir -p /data/uploads/{images,videos}
mkdir -p /data/mediadb

# Run the container
docker run -d \
  --name image-upload-backend \
  -p 8080:8080 \
  -v /data/uploads:/app/uploads \
  -v /data/mediadb:/app/data \
  -e JAVA_OPTS="-Xmx1024m -Xms512m" \
  --restart unless-stopped \
  image-upload-service:1.0.0

# Verify container is running
docker ps | grep image-upload

# Check logs
docker logs -f image-upload-backend
```

### Step 5: Verify Deployment

```bash
# From your local machine
curl http://192.168.1.251:8080/api/media

# Or from remote server
curl http://localhost:8080/api/media
```

## Using Docker Compose (Alternative)

If you prefer using docker-compose on the remote server:

### Step 1: Copy docker-compose files

```bash
scp docker-compose.yml root@192.168.1.251:/opt/image-upload-service/
scp docker-compose.prod.yml root@192.168.1.251:/opt/image-upload-service/
```

### Step 2: Deploy using docker-compose

```bash
ssh root@192.168.1.251

cd /opt/image-upload-service

# Load the image
docker load < /tmp/image-upload-service-1.0.0.tar.gz

# Start services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# View logs
docker-compose logs -f image-upload-backend

# Stop services
docker-compose down
```

## Container Management

### View Container Status
```bash
docker ps -a
docker stats image-upload-backend
```

### View Logs
```bash
docker logs -f image-upload-backend
docker logs image-upload-backend --tail 50
```

### Stop Container
```bash
docker stop image-upload-backend
```

### Start Container
```bash
docker start image-upload-backend
```

### Remove Container
```bash
docker stop image-upload-backend
docker rm image-upload-backend
```

### Access Container Shell
```bash
docker exec -it image-upload-backend /bin/bash
```

## Verify API Endpoints

```bash
# Get all media
curl http://192.168.1.251:8080/api/media

# Get images only
curl http://192.168.1.251:8080/api/media/images

# Get videos only
curl http://192.168.1.251:8080/api/media/videos

# Check health
curl http://192.168.1.251:8080/api/media || echo "Service not ready"
```

## Volume Persistence

Uploaded files are stored in `/data/uploads/`:
- Images: `/data/uploads/images/`
- Videos: `/data/uploads/videos/`

Database files: `/data/mediadb/`

To backup data:
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz /data/
```

## Configuration

Edit environment variables in docker-compose or docker run command:
- `JAVA_OPTS`: JVM options (memory, etc.)
- `file.upload-dir`: Directory for uploads
- `spring.h2.console.enabled`: Enable/disable H2 console

## Troubleshooting

### Port already in use
```bash
# Find process using port 8080
sudo lsof -i :8080
# Kill the process
sudo kill -9 <PID>
```

### Out of memory
Increase JVM heap size in JAVA_OPTS:
```bash
JAVA_OPTS="-Xmx2048m -Xms1024m"
```

### Container keeps restarting
```bash
docker logs image-upload-backend
# Check the error and fix it
```

### Remove all containers and images
```bash
docker system prune -a --volumes
```

## Next Steps

1. Point frontend to http://192.168.1.251:8080/api
2. Update REACT_APP_API_URL in frontend .env file
3. Deploy frontend to a web server
4. Set up monitoring/alerting for production use

## Support

For issues or questions, check:
- Docker logs: `docker logs image-upload-backend`
- Application logs inside container: `docker exec image-upload-backend tail -f /var/log/app.log` (if available)
