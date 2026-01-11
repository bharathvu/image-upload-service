# Deployment Checklist - 192.168.1.251

## Pre-Deployment Checklist

- [ ] Have password for `root@192.168.1.251`
- [ ] Verified SSH access works
- [ ] Docker installed on Ubuntu server
- [ ] Docker Compose installed
- [ ] Sufficient disk space (min 10GB)
- [ ] Ports 80 and 8080 are available

---

## Deployment Steps

### Phase 1: Preparation (1 minute)

- [ ] SSH into server: `ssh root@192.168.1.251`
- [ ] Create directories:
  ```bash
  mkdir -p /root/app /data/uploads /data/mediadb
  chmod -R 755 /data
  ```
- [ ] Verify directories created: `ls -la /data/`

### Phase 2: Clone Repository (1 minute)

- [ ] Navigate to app directory: `cd /root/app`
- [ ] Clone repo: `git clone https://github.com/bharathvu/image-upload-service.git .`
- [ ] Verify clone: `ls -la` (should show backend/, frontend/, docker-compose.yml)

### Phase 3: Build Backend (3-5 minutes)

- [ ] Build image: `docker build -t image-upload-service:1.0.0 backend/`
- [ ] Watch for: `Successfully tagged image-upload-service:1.0.0`
- [ ] Verify: `docker images | grep image-upload-service`

### Phase 4: Build Frontend (1-3 minutes)

- [ ] Build image: `docker build -t image-upload-frontend:1.0.0 frontend/`
- [ ] Watch for: `Successfully tagged image-upload-frontend:1.0.0`
- [ ] Verify: `docker images | grep image-upload-frontend`

### Phase 5: Deploy Services (1 minute)

- [ ] Deploy: `docker-compose up -d`
- [ ] Watch for: `Creating image-upload-backend ... done` and `Creating image-upload-frontend ... done`
- [ ] Verify: `docker-compose ps` (both should show UP)

### Phase 6: Verify Health (2 minutes)

- [ ] Check services: `docker-compose ps`
  - [ ] backend: UP
  - [ ] frontend: UP
  
- [ ] Test frontend: `curl http://localhost/`
  - [ ] Should return HTML
  
- [ ] Test backend: `curl http://localhost:8080/api/media`
  - [ ] Should return `[]`
  
- [ ] Test health: `curl http://localhost/health.html`
  - [ ] Should return `OK`

---

## Post-Deployment Verification

### From Ubuntu Server

- [ ] Services running: `docker-compose ps`
- [ ] Both containers healthy: `docker ps --format "table {{.Names}}\t{{.Status}}"`
- [ ] Check logs: `docker-compose logs` (no errors)
- [ ] Test API: `curl http://localhost:8080/api/media` returns `[]`

### From Your Local Machine

Open browser and test:

- [ ] Frontend loads: `http://192.168.1.251`
  - [ ] See Image Upload Service interface
  - [ ] Can see Camera tab
  - [ ] Can see Gallery tab
  
- [ ] Backend responds: `http://192.168.1.251:8080/api/media`
  - [ ] Returns empty array `[]`
  
- [ ] Health check: `http://192.168.1.251/health.html`
  - [ ] Shows `OK`

---

## Feature Testing

### Photo Capture Test

- [ ] Go to http://192.168.1.251
- [ ] Click "Capture" tab
- [ ] Select "Photo" mode
- [ ] Allow camera access
- [ ] Click "Take Photo" button
- [ ] Photo preview appears
- [ ] Click "Upload Photo"
- [ ] Success message appears
- [ ] Go to Gallery tab
- [ ] Uploaded photo appears

### Video Recording Test

- [ ] Click "Capture" tab
- [ ] Select "Video" mode
- [ ] Allow camera & microphone access
- [ ] Click "Start Recording"
- [ ] Record for a few seconds
- [ ] Click "Stop Recording"
- [ ] Video preview appears
- [ ] Click "Upload Video"
- [ ] Success message appears
- [ ] Go to Gallery tab
- [ ] Uploaded video appears

### Gallery Test

- [ ] Go to http://192.168.1.251
- [ ] Click "Gallery" tab
- [ ] See uploaded files
- [ ] Select "Images" filter - only images show
- [ ] Select "Videos" filter - only videos show
- [ ] Select "All" filter - all files show
- [ ] Click download button - file downloads
- [ ] Click delete button - file removed

---

## Monitoring Setup

### View Live Logs

```bash
# Keep this running during initial testing
docker-compose logs -f
```

### Monitor Resource Usage

```bash
docker stats
```

### Check Individual Service Logs

```bash
# Backend
docker logs image-upload-backend -f

# Frontend
docker logs image-upload-frontend -f
```

---

## Troubleshooting Checklist

If something doesn't work:

### Services Not Starting
- [ ] Check logs: `docker-compose logs`
- [ ] Check ports: `sudo lsof -i :80` and `sudo lsof -i :8080`
- [ ] Restart: `docker-compose restart`

### Frontend Not Loading
- [ ] Check nginx: `docker logs image-upload-frontend`
- [ ] Test frontend: `curl http://localhost/`
- [ ] Restart frontend: `docker-compose restart image-upload-frontend`

### API Not Responding
- [ ] Check backend: `docker logs image-upload-backend`
- [ ] Test API: `curl http://localhost:8080/api/media`
- [ ] Check Java: `docker exec image-upload-backend ps aux | grep java`
- [ ] Restart backend: `docker-compose restart image-upload-backend`

### Upload Fails
- [ ] Check upload directory: `ls -la /data/uploads/`
- [ ] Check permissions: `chmod -R 755 /data/uploads`
- [ ] Check disk space: `df -h /data`
- [ ] Check backend logs: `docker logs image-upload-backend`

### Slow Performance
- [ ] Check resource usage: `docker stats`
- [ ] Check memory: `free -h`
- [ ] Check CPU: `top -bn1 | head -20`
- [ ] Check disk I/O: `iotop`

---

## Success Indicators

✅ **Deployment is successful when:**

1. ✅ SSH connection established to 192.168.1.251
2. ✅ Directories created at `/data/uploads` and `/data/mediadb`
3. ✅ Repository cloned to `/root/app`
4. ✅ Backend image built: `image-upload-service:1.0.0`
5. ✅ Frontend image built: `image-upload-frontend:1.0.0`
6. ✅ Docker Compose deployment successful
7. ✅ Both containers running (docker-compose ps shows UP)
8. ✅ http://192.168.1.251 loads in browser
9. ✅ http://192.168.1.251:8080/api/media returns `[]`
10. ✅ Photo capture and upload works
11. ✅ Video recording and upload works
12. ✅ Gallery displays files
13. ✅ Download and delete functionality works

---

## Estimated Timeline

| Phase | Time | Cumulative |
|-------|------|-----------|
| SSH + Prepare | 1 min | 1 min |
| Clone | 1 min | 2 min |
| Build Backend | 3-5 min | 5-7 min |
| Build Frontend | 1-3 min | 6-10 min |
| Deploy | 1 min | 7-11 min |
| Verify | 2 min | 9-13 min |
| **Total** | - | **~10-15 min** |

---

## Post-Deployment Commands

```bash
# SSH into server
ssh root@192.168.1.251

# Navigate to app
cd /root/app

# View services
docker-compose ps

# View logs
docker-compose logs -f

# Restart all
docker-compose restart

# Stop all
docker-compose stop

# Start all
docker-compose up -d

# Check health
docker-compose ps --format "table {{.Names}}\t{{.Status}}"

# Backup data
tar -czf /root/media-backup-$(date +%Y%m%d).tar.gz /data/

# Exit SSH
exit
```

---

## Need Help?

1. **Deployment stuck?** → See DEPLOYMENT_STEPS.md
2. **Want detailed guide?** → See FULLSTACK_DEPLOYMENT.md
3. **Need quick reference?** → See DOCKER_REFERENCE.md
4. **Architecture questions?** → See FULLSTACK_SUMMARY.md

---

**Status:** Ready to deploy ✅
**Target:** 192.168.1.251 ✅
**Time Estimate:** 10-15 minutes ✅

---

*Print this checklist and follow it step-by-step for smooth deployment!*
