# Full Stack Deployment Guide - Frontend & Backend

## Overview

This guide provides complete instructions for building and deploying both the React frontend and Spring Boot backend to the Ubuntu server at **192.168.1.251**.

**Target Environment:**
- Server: Ubuntu Server (192.168.1.251)
- Frontend: Nginx reverse proxy + React app (Port 80)
- Backend: Spring Boot REST API (Port 8080)
- Communication: Frontend proxies `/api/*` requests to backend

## Architecture

```
┌─────────────────────────────────────────────┐
│         Client (Browser)                    │
└──────────┬──────────────────────────────────┘
           │
           │ HTTP requests
           ▼
┌─────────────────────────────────────────────┐
│  192.168.1.251:80 - Frontend Container     │
│  (Nginx reverse proxy)                      │
│  - Serves React app                         │
│  - Proxies /api/* → localhost:8080          │
└──────────┬──────────────────────────────────┘
           │
           │ http://localhost:8080/api/*
           ▼
┌─────────────────────────────────────────────┐
│  192.168.1.251:8080 - Backend Container    │
│  (Spring Boot REST API)                     │
│  - Handles file uploads/downloads           │
│  - Database operations                      │
│  - Media management                         │
└─────────────────────────────────────────────┘
```

## Prerequisites

**On Ubuntu Server (192.168.1.251):**
- Docker installed and running
- Docker Compose installed (v1.29+)
- SSH access
- Sufficient disk space (min 2GB)
- Port 80 and 8080 available

**Check Prerequisites:**
```bash
ssh root@192.168.1.251
docker --version
docker-compose --version
sudo systemctl status docker
```

## Step 1: Build Docker Images (Local Machine)

### 1.1 Build Backend Image

```bash
cd c:\Users\bhara\Downloads\prog-space\java\image-upload-service
docker build -t image-upload-service:1.0.0 backend/
```

**Output:** Image ~300-400MB (multi-stage build optimized)

**Verify:**
```bash
docker images | grep image-upload-service
```

**Expected Output:**
```
image-upload-service          1.0.0     <image-id>   XX minutes ago   300MB
```

### 1.2 Build Frontend Image

```bash
docker build -t image-upload-frontend:1.0.0 frontend/
```

**Output:** Image ~100-150MB (nginx + built React app)

**Verify:**
```bash
docker images | grep image-upload-frontend
```

**Expected Output:**
```
image-upload-frontend         1.0.0     <image-id>   XX minutes ago   100MB
```

### 1.3 Test Locally (Optional)

```bash
docker-compose up -d
# Frontend: http://localhost
# Backend: http://localhost:8080/api/media
docker-compose down
```

## Step 2: Export and Transfer Images

### 2.1 Export Backend Image

```bash
docker save image-upload-service:1.0.0 | gzip > image-upload-service-1.0.0.tar.gz
```

**Verify file size:**
```bash
ls -lh image-upload-service-1.0.0.tar.gz
# Should be ~60-100MB (compressed)
```

### 2.2 Export Frontend Image

```bash
docker save image-upload-frontend:1.0.0 | gzip > image-upload-frontend-1.0.0.tar.gz
```

**Verify:**
```bash
ls -lh image-upload-frontend-1.0.0.tar.gz
# Should be ~30-50MB (compressed)
```

### 2.3 Transfer Images to Remote Server

**Option A: Using SCP (Recommended)**

```bash
scp image-upload-service-1.0.0.tar.gz root@192.168.1.251:/tmp/
scp image-upload-frontend-1.0.0.tar.gz root@192.168.1.251:/tmp/
```

**Option B: Using SSH Password/Key**
Ensure SSH key is configured for password-less access.

**Verify Transfer:**
```bash
ssh root@192.168.1.251 "ls -lh /tmp/*.tar.gz"
```

**Expected Output:**
```
-rw-r--r-- 1 root root  60M Jan 11 12:00 image-upload-service-1.0.0.tar.gz
-rw-r--r-- 1 root root  35M Jan 11 12:00 image-upload-frontend-1.0.0.tar.gz
```

## Step 3: Load Images on Remote Server

SSH into the remote server:
```bash
ssh root@192.168.1.251
```

### 3.1 Load Backend Image

```bash
docker load < /tmp/image-upload-service-1.0.0.tar.gz
```

**Output:** `Loaded image: image-upload-service:1.0.0`

**Verify:**
```bash
docker images | grep image-upload-service
```

### 3.2 Load Frontend Image

```bash
docker load < /tmp/image-upload-frontend-1.0.0.tar.gz
```

**Output:** `Loaded image: image-upload-frontend:1.0.0`

**Verify:**
```bash
docker images | grep image-upload-frontend
```

### 3.3 Clean Up Transferred Files

```bash
rm /tmp/image-upload-*.tar.gz
```

## Step 4: Prepare Server Environment

### 4.1 Create Data Directories

```bash
mkdir -p /data/uploads
mkdir -p /data/mediadb
chmod -R 755 /data
```

### 4.2 Download Docker Compose File

**Option A: Copy from your machine**
```bash
# From your local machine
scp docker-compose.yml root@192.168.1.251:/root/app/
scp docker-compose.prod.yml root@192.168.1.251:/root/app/
```

**Option B: Create on server**
```bash
mkdir -p /root/app
cd /root/app
```

Then create `docker-compose.yml` with:
```yaml
version: '3.8'

services:
  image-upload-frontend:
    image: image-upload-frontend:1.0.0
    ports:
      - "80:80"
    depends_on:
      - image-upload-backend
    networks:
      - app-network
    restart: always
    container_name: image-upload-frontend

  image-upload-backend:
    image: image-upload-service:1.0.0
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
    driver: bridge
```

## Step 5: Deploy Containers

### 5.1 Start Services

```bash
cd /root/app
docker-compose up -d
```

**Output:**
```
Creating network "app_app-network" with driver "bridge"
Creating image-upload-backend  ... done
Creating image-upload-frontend ... done
```

### 5.2 Verify Services Running

```bash
docker-compose ps
```

**Expected Output:**
```
NAME                      STATUS          PORTS
image-upload-backend      Up 2 minutes    0.0.0.0:8080->8080/tcp
image-upload-frontend     Up 1 minute     0.0.0.0:80->80/tcp
```

### 5.3 Check Container Logs

**Backend:**
```bash
docker logs image-upload-backend --tail=50
# Should see Spring Boot startup logs
```

**Frontend:**
```bash
docker logs image-upload-frontend --tail=50
# Should see Nginx startup logs
```

## Step 6: Verify Deployment

### 6.1 Check Backend API

```bash
curl http://192.168.1.251:8080/api/media
```

**Expected Response:**
```json
[]
```

### 6.2 Check Frontend (From Browser or curl)

```bash
curl http://192.168.1.251/
# Should return HTML (React app)

# Or from browser: http://192.168.1.251
```

### 6.3 Check Health Status

```bash
docker inspect --format='{{json .State.Health}}' image-upload-backend | jq
docker inspect --format='{{json .State.Health}}' image-upload-frontend | jq
```

### 6.4 Test Full Stack

**Upload test image:**
```bash
# From client machine
curl -X POST http://192.168.1.251:8080/api/media/upload/image \
  -F "file=@test-image.jpg"
```

**View in frontend:**
Open browser to `http://192.168.1.251` and check Gallery tab.

## Step 7: Monitoring & Maintenance

### View Real-time Logs

```bash
docker-compose logs -f
```

### Restart Services

```bash
docker-compose restart
```

### Stop Services

```bash
docker-compose stop
```

### Remove Services (WARNING: Data will be preserved in /data/)

```bash
docker-compose down
```

### View Resource Usage

```bash
docker stats
```

### Backup Data

```bash
tar -czf mediadb-backup-$(date +%Y%m%d).tar.gz /data/
```

## Troubleshooting

### Issue: Port 80 Already in Use

```bash
sudo lsof -i :80
# Kill the process or choose different port in docker-compose.yml
```

### Issue: Backend Connection Refused

1. Check backend is running:
   ```bash
   docker exec image-upload-backend ps aux | grep java
   ```

2. Check logs:
   ```bash
   docker logs image-upload-backend
   ```

3. Verify network:
   ```bash
   docker network inspect app_app-network
   ```

### Issue: Frontend Not Loading

1. Check nginx is running:
   ```bash
   docker exec image-upload-frontend nginx -t
   ```

2. Check frontend logs:
   ```bash
   docker logs image-upload-frontend
   ```

3. Test directly:
   ```bash
   curl http://192.168.1.251/health.html
   # Should return: OK
   ```

### Issue: File Upload Fails

1. Check volume permissions:
   ```bash
   ls -la /data/uploads
   # Should be rwxr-xr-x
   ```

2. Check container can write:
   ```bash
   docker exec image-upload-backend touch /app/uploads/test.txt
   ```

### Issue: Out of Disk Space

```bash
df -h /data
# If full, backup and clean old files
docker exec image-upload-backend rm /app/uploads/old-file.jpg
```

## Performance Tuning

### Increase Java Memory for Large Files

Edit `/root/app/docker-compose.yml`:
```yaml
environment:
  - JAVA_OPTS=-Xmx2048m -Xms1024m
```

Then:
```bash
docker-compose up -d
```

### Nginx Caching (For Static Assets)

Edit docker-compose.yml to mount custom nginx config:
```yaml
image-upload-frontend:
  volumes:
    - ./nginx-cache.conf:/etc/nginx/conf.d/default.conf
```

### Database Connection Pooling

The H2 database is configured for optimal performance. For production, consider upgrading to PostgreSQL or MySQL.

## Updating to New Versions

### 1. Build new images locally
```bash
docker build -t image-upload-service:1.1.0 backend/
docker build -t image-upload-frontend:1.1.0 frontend/
```

### 2. Export and transfer
```bash
docker save image-upload-service:1.1.0 | gzip > image-upload-service-1.1.0.tar.gz
docker save image-upload-frontend:1.1.0 | gzip > image-upload-frontend-1.1.0.tar.gz
scp image-upload-*.tar.gz root@192.168.1.251:/tmp/
```

### 3. Load and restart
```bash
ssh root@192.168.1.251
cd /root/app
docker load < /tmp/image-upload-service-1.1.0.tar.gz
docker load < /tmp/image-upload-frontend-1.1.0.tar.gz

# Update docker-compose.yml with new version (1.1.0)
docker-compose up -d
```

## Database Management

### View H2 Database Files

```bash
ls -la /data/mediadb/
# mediadb.mv.db - main database file
# mediadb.trace.db - debug trace
```

### Access H2 Console (If Enabled in Dev)

Backend allows H2 console access in development:
```
http://192.168.1.251:8080/h2-console
# Driver Class: org.h2.Driver
# JDBC URL: jdbc:h2:/app/data/mediadb
# User: sa
# Password: (empty)
```

**IMPORTANT:** H2 console is disabled in production (application.properties) for security.

## Summary

✅ **Deployment Complete When:**
- Both containers running: `docker-compose ps`
- Frontend accessible: `curl http://192.168.1.251`
- Backend responding: `curl http://192.168.1.251:8080/api/media`
- Health checks passing: `docker inspect` shows `healthy`
- Data persisting: `/data/uploads/` contains uploaded files

---

**Quick Deployment Command Cheat Sheet:**
```bash
# On Ubuntu Server
cd /root/app
docker-compose down                    # Stop services
docker load < /tmp/image-upload-service-*.tar.gz
docker load < /tmp/image-upload-frontend-*.tar.gz
docker-compose up -d                   # Start all services
docker-compose logs -f                 # Monitor logs
docker-compose ps                      # Check status
```

**URLs After Deployment:**
- Frontend: `http://192.168.1.251`
- Backend API: `http://192.168.1.251:8080/api/media`
- Health Check: `http://192.168.1.251/health.html`
