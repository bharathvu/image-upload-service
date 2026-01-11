# Docker Quick Reference Guide

## Local Development

```bash
# Build Docker image
docker build -t image-upload-service:1.0.0 backend/

# Run container locally
docker run -d -p 8080:8080 -v $(pwd)/backend/uploads:/app/uploads \
  --name image-upload-backend image-upload-service:1.0.0

# Using Docker Compose
docker-compose up -d
docker-compose down
```

## Remote Deployment to 192.168.1.251

```bash
# Build image
docker build -t image-upload-service:1.0.0 backend/

# Save to file
docker save image-upload-service:1.0.0 | gzip > image-upload-service-1.0.0.tar.gz

# Copy to remote (Windows)
scp image-upload-service-1.0.0.tar.gz root@192.168.1.251:/tmp/

# SSH into remote
ssh root@192.168.1.251

# Load image on remote
docker load < /tmp/image-upload-service-1.0.0.tar.gz

# Create data directories
mkdir -p /data/uploads/{images,videos}

# Run container
docker run -d \
  --name image-upload-backend \
  -p 8080:8080 \
  -v /data/uploads:/app/uploads \
  -e JAVA_OPTS="-Xmx1024m -Xms512m" \
  --restart unless-stopped \
  image-upload-service:1.0.0

# Verify
docker ps | grep image-upload
docker logs -f image-upload-backend
```

## Monitoring & Management

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container stats
docker stats image-upload-backend

# View logs
docker logs image-upload-backend
docker logs -f image-upload-backend           # Follow logs
docker logs --tail 50 image-upload-backend    # Last 50 lines

# Execute command in container
docker exec -it image-upload-backend /bin/bash

# Stop container
docker stop image-upload-backend

# Start container
docker start image-upload-backend

# Restart container
docker restart image-upload-backend

# Remove container
docker rm image-upload-backend

# Remove image
docker rmi image-upload-service:1.0.0
```

## Health & Troubleshooting

```bash
# Check container health
docker inspect image-upload-backend | grep -i health

# Check port usage
netstat -tulpn | grep 8080

# View resource usage
docker stats

# Clean up (WARNING: removes unused images/volumes)
docker system prune -a --volumes

# Check image size
docker images | grep image-upload-service

# View image layers
docker history image-upload-service:1.0.0
```

## Environment Variables

Available environment variables for the container:

```bash
JAVA_OPTS="-Xmx1024m -Xms512m"    # JVM heap size
file.upload-dir=/app/uploads       # Upload directory
spring.h2.console.enabled=false    # H2 console access
```

## Volume Paths

Inside container:
- `/app/uploads/` - Media files (images and videos)
- `/app/data/` - H2 database files
- `/app` - Application root

## Network

The container listens on:
- Port: 8080 (HTTP)
- API Base: http://hostname:8080/api

## Common Issues

| Issue | Solution |
|-------|----------|
| Port 8080 already in use | `docker run -p 8081:8080 ...` or kill the conflicting process |
| Out of memory | Increase `JAVA_OPTS` heap size |
| Permission denied on volumes | Check volume permissions: `chmod 755 /data/uploads` |
| Container exits immediately | Check logs: `docker logs <container-id>` |
| Cannot connect from host | Verify port mapping: `docker port <container-id>` |

## Backup & Restore

```bash
# Backup uploaded files
docker exec image-upload-backend tar czf - /app/uploads | gzip > backup-$(date +%Y%m%d).tar.gz

# Backup database
docker exec image-upload-backend tar czf - /app/data | gzip > db-backup-$(date +%Y%m%d).tar.gz

# Restore from backup
gunzip < backup-20240101.tar.gz | docker exec -i image-upload-backend tar xzf -
```

## Production Checklist

- [ ] Use production docker-compose file (`docker-compose.prod.yml`)
- [ ] Set appropriate JAVA_OPTS for production load
- [ ] Configure volume mounts for persistent storage
- [ ] Set restart policy to `unless-stopped` or `always`
- [ ] Configure health checks
- [ ] Set up logging and monitoring
- [ ] Back up data regularly
- [ ] Use environment variables for sensitive config
- [ ] Don't run as root if possible
- [ ] Limit container resources (memory, CPU)

## Performance Tuning

```bash
# Limit container resources
docker run -d \
  --memory="1g" \
  --cpus="1.5" \
  -p 8080:8080 \
  image-upload-service:1.0.0

# Monitor performance
docker stats --no-stream
```
