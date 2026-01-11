# Quick Start: Deploy to 192.168.1.251

## TL;DR (Fastest Way)

### Recommended: Build on Ubuntu Server

```bash
# SSH into server
ssh root@192.168.1.251

# Clone and build
git clone https://github.com/bharathvu/image-upload-service.git /root/app
cd /root/app

# Build both images (total time: 3-8 minutes)
docker build -t image-upload-service:1.0.0 backend/
docker build -t image-upload-frontend:1.0.0 frontend/

# Deploy
docker-compose up -d

# Verify
curl http://localhost/health.html
curl http://localhost:8080/api/media
```

**Done!** Frontend: http://192.168.1.251 | Backend: http://192.168.1.251:8080/api

---

## Full Instructions (3 Options)

### Option 1: Build on Ubuntu Server (Fastest & Recommended)

**Time:** 5-10 minutes total
**Requirement:** Git, Docker, Docker Compose on Ubuntu

```bash
# Step 1: SSH into server
ssh root@192.168.1.251

# Step 2: Prepare
mkdir -p /data/{uploads,mediadb}
chmod -R 755 /data

# Step 3: Clone repository
cd /root
git clone https://github.com/bharathvu/image-upload-service.git app
cd app

# Step 4: Build backend (5 minutes)
docker build -t image-upload-service:1.0.0 backend/
# Output: Successfully tagged image-upload-service:1.0.0

# Step 5: Build frontend (2 minutes)
docker build -t image-upload-frontend:1.0.0 frontend/
# Output: Successfully tagged image-upload-frontend:1.0.0

# Step 6: Start services
docker-compose up -d
# Output: Creating image-upload-frontend ... done
#         Creating image-upload-backend ... done

# Step 7: Verify
docker-compose ps
# Should show both containers as UP

curl http://localhost/health.html
# Should return: OK

curl http://localhost:8080/api/media
# Should return: []
```

**Access from Browser:**
- Frontend: http://192.168.1.251
- API: http://192.168.1.251:8080/api/media

---

### Option 2: Transfer Pre-built Images from Windows

**Time:** 10-15 minutes
**Requirement:** Docker on Windows, SSH/SCP access to Ubuntu

```bash
# On Windows: Build images
cd c:\Users\bhara\Downloads\prog-space\java\image-upload-service
docker build -t image-upload-service:1.0.0 backend/
docker build -t image-upload-frontend:1.0.0 frontend/

# Export as compressed files
docker save image-upload-service:1.0.0 | gzip > image-upload-service-1.0.0.tar.gz
docker save image-upload-frontend:1.0.0 | gzip > image-upload-frontend-1.0.0.tar.gz

# Transfer to server
scp image-upload-service-1.0.0.tar.gz root@192.168.1.251:/tmp/
scp image-upload-frontend-1.0.0.tar.gz root@192.168.1.251:/tmp/

# On Ubuntu: Load images
ssh root@192.168.1.251 "
  docker load < /tmp/image-upload-service-1.0.0.tar.gz
  docker load < /tmp/image-upload-frontend-1.0.0.tar.gz
  rm /tmp/image-upload-*.tar.gz
  mkdir -p /data/{uploads,mediadb}
  cd /root/app && docker-compose up -d
"

# Verify
ssh root@192.168.1.251 "docker-compose ps"
```

---

### Option 3: Use Automated Script (Windows)

**Time:** 10-15 minutes
**Requirement:** PowerShell, SCP/SSH configured

```bash
# Windows PowerShell
cd c:\Users\bhara\Downloads\prog-space\java\image-upload-service
.\deploy-fullstack.bat

# Follow on-screen prompts
# Script will:
# 1. Build both images
# 2. Export images to tar.gz
# 3. Transfer to 192.168.1.251
# 4. Load images on remote
# 5. Start docker-compose
# 6. Verify deployment
```

---

## Verify Deployment

### Check Services Running
```bash
ssh root@192.168.1.251 "docker-compose ps"

# Expected output:
# NAME                      STATUS
# image-upload-frontend     Up 2 minutes
# image-upload-backend      Up 2 minutes
```

### Test Frontend
```bash
# From browser
http://192.168.1.251

# From command line
curl http://192.168.1.251/
curl http://192.168.1.251/health.html
```

### Test Backend API
```bash
# Get all media
curl http://192.168.1.251:8080/api/media
# Response: []

# Upload test image
curl -X POST http://192.168.1.251:8080/api/media/upload/image \
  -F "file=@test.jpg"

# Get all media again
curl http://192.168.1.251:8080/api/media
# Response: [{...file info...}]
```

### View Logs
```bash
ssh root@192.168.1.251 "cd /root/app && docker-compose logs -f"

# Press Ctrl+C to exit
```

---

## Troubleshooting

### Build Takes Too Long / Times Out

**Solution:** Run build with BuildKit (faster)
```bash
DOCKER_BUILDKIT=1 docker build -t image-upload-service:1.0.0 backend/
```

### Port 80 or 8080 Already in Use

**Check what's using it:**
```bash
ssh root@192.168.1.251 "sudo lsof -i :80"
ssh root@192.168.1.251 "sudo lsof -i :8080"

# Kill the process or change port in docker-compose.yml
# Then: docker-compose up -d
```

### Cannot Connect to 192.168.1.251

**Check:**
1. Server is reachable: `ping 192.168.1.251`
2. Docker services running: `ssh root@192.168.1.251 "docker-compose ps"`
3. Firewall allows ports 80 and 8080

### No Space on Disk

**Clean up Docker:**
```bash
ssh root@192.168.1.251 "docker system prune -a"
```

### Containers Keep Restarting

**Check logs:**
```bash
ssh root@192.168.1.251 "docker-compose logs"

# Common issues:
# - Backend: Check Java heap size (JAVA_OPTS)
# - Frontend: Check nginx configuration
# - Network: Verify docker-compose.yml network settings
```

---

## Post-Deployment

### View Logs
```bash
ssh root@192.168.1.251 "cd /root/app && docker-compose logs -f backend"
ssh root@192.168.1.251 "cd /root/app && docker-compose logs -f frontend"
```

### Stop Services
```bash
ssh root@192.168.1.251 "cd /root/app && docker-compose stop"
```

### Start Services
```bash
ssh root@192.168.1.251 "cd /root/app && docker-compose up -d"
```

### Restart Services
```bash
ssh root@192.168.1.251 "cd /root/app && docker-compose restart"
```

### View Resource Usage
```bash
ssh root@192.168.1.251 "docker stats"
```

### Backup Data
```bash
ssh root@192.168.1.251 "tar -czf /root/media-backup-$(date +%Y%m%d).tar.gz /data/"
```

---

## What Was Deployed

### Frontend Service
- **Image:** `image-upload-frontend:1.0.0`
- **Port:** 80 (HTTP)
- **Technology:** Nginx + React
- **Purpose:** Web UI for uploading and managing media

### Backend Service
- **Image:** `image-upload-service:1.0.0`
- **Port:** 8080 (HTTP)
- **Technology:** Spring Boot + H2 Database
- **Purpose:** REST API for file management

### Data Persistence
- **Uploads:** `/data/uploads/` (images and videos)
- **Database:** `/data/mediadb/` (H2 database files)

---

## Accessing the Application

| Component | URL | Purpose |
|-----------|-----|---------|
| Frontend | http://192.168.1.251 | Upload/download photos and videos |
| Backend API | http://192.168.1.251:8080/api | REST API endpoints |
| Health Check | http://192.168.1.251/health.html | Service status |
| All Media | http://192.168.1.251:8080/api/media | List all uploads |

---

## Key Features

✅ **Photo Capture** - Capture photos from webcam
✅ **Video Recording** - Record videos from webcam
✅ **Gallery View** - View all uploaded media
✅ **Filter** - Filter by images or videos
✅ **Download** - Download files from gallery
✅ **Delete** - Remove files from gallery
✅ **API** - RESTful API for integration
✅ **Persistent Storage** - Files survive container restarts
✅ **Docker Compose** - Easy management of both services

---

## Documentation

For detailed information, see:
- [FULLSTACK_DEPLOYMENT.md](FULLSTACK_DEPLOYMENT.md) - Complete deployment guide
- [BUILD_ON_UBUNTU.md](BUILD_ON_UBUNTU.md) - Build process details
- [DOCKER_REFERENCE.md](DOCKER_REFERENCE.md) - Docker command reference
- [README.md](README.md) - Project overview

---

## Support

**GitHub:** https://github.com/bharathvu/image-upload-service

**Tags:**
- v1.0.0 - Initial release
- v1.1.0 - Backend Docker
- v1.2.0 - Full-stack Docker (Current)

---

**Deployed Successfully When:**
- ✅ `docker-compose ps` shows both containers as UP
- ✅ `curl http://192.168.1.251` returns HTML
- ✅ `curl http://192.168.1.251:8080/api/media` returns `[]`
- ✅ Browser shows the React application at http://192.168.1.251

**Estimated Time:** 5-15 minutes depending on chosen option

**Next Steps:** Open http://192.168.1.251 in your browser and start uploading media!
