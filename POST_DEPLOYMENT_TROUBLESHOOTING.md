# Post-Deployment Troubleshooting & Monitoring

## Quick Status Check (Run this first)

```bash
# Check if containers are running
docker-compose ps

# Check logs for both services
docker-compose logs --tail=50

# Check network connectivity
docker network ls
docker network inspect app_app-network

# Check volumes
docker volume ls
ls -la /data/uploads /data/mediadb

# Check disk usage
df -h /data
```

---

## Issue: "Connection refused" when accessing http://192.168.1.251

### Diagnosis
```bash
# Test port accessibility
nc -zv 192.168.1.251 80    # Frontend port
nc -zv 192.168.1.251 8080  # Backend port

# Alternative test
curl -I http://localhost/  # From server
curl -I http://localhost:8080/api/media
```

### Solutions
**Problem: Nginx not responding**
```bash
# Check container status
docker-compose ps image-upload-frontend
docker logs image-upload-frontend --tail=20

# Restart Nginx
docker-compose restart image-upload-frontend

# Check Nginx config
docker exec image-upload-frontend nginx -t
```

**Problem: Spring Boot not responding**
```bash
# Check container status
docker-compose ps image-upload-backend
docker logs image-upload-backend --tail=50

# Check Java process
docker exec image-upload-backend ps aux | grep java

# Restart Spring
docker-compose restart image-upload-backend
```

---

## Issue: File Upload Returns 500 Error

### Check Backend Logs
```bash
docker logs image-upload-backend --tail=100 | grep -i error
```

### Common Causes

**1. Permission Denied (Volume Mount)**
```bash
# Check permissions
ls -la /data/uploads/
ls -la /data/uploads/images/
ls -la /data/uploads/videos/

# Fix permissions
sudo chmod -R 755 /data/
sudo chmod -R 777 /data/uploads/
sudo chmod -R 777 /data/mediadb/

# Verify
ls -la /data/uploads/ | head -5
```

**2. Disk Space Full**
```bash
# Check disk usage
df -h /data

# If full:
du -sh /data/uploads/* | sort -h
# Delete old files if needed
```

**3. Database Connection Error**
```bash
# Check database directory
ls -la /data/mediadb/

# Check database logs
docker exec image-upload-backend tail -f /root/.h2.server.properties

# Restart database
docker-compose restart image-upload-backend
```

---

## Issue: Video Recording Not Working in Browser

### Diagnosis
```bash
# Check browser console (Developer Tools)
F12 → Console tab → Look for errors

# Test frontend health
curl -I http://192.168.1.251/
curl http://192.168.1.251/health.html

# Check if React app loaded
curl http://192.168.1.251/ | grep -i "react\|root"
```

### Solutions

**Problem: Frontend not loading React components**
```bash
# Check Nginx serving files
docker exec image-upload-frontend ls -la /usr/share/nginx/html/

# Verify React build exists
docker exec image-upload-frontend ls -la /usr/share/nginx/html/index.html

# Check Nginx logs
docker logs image-upload-frontend --tail=20
```

**Problem: MediaRecorder API not working**
- Ensure you're using HTTPS or localhost (browsers restrict MediaRecorder)
- For http://192.168.1.251, may need HTTPS or use localhost from server
- Test locally first: ssh to server, then `curl -I http://localhost/`

---

## Issue: API Gateway Returns 502 Bad Gateway

### Diagnosis
```bash
# Check if backend is running
docker-compose ps image-upload-backend

# Check if backend is listening
docker exec image-upload-backend netstat -tlnp | grep 8080

# Test backend directly
curl http://localhost:8080/api/media
```

### Solutions

**Problem: Backend container crashed**
```bash
# View error logs
docker logs image-upload-backend

# Restart
docker-compose restart image-upload-backend

# If keeps crashing, check:
docker logs image-upload-backend --tail=100 | tail -20
```

**Problem: Nginx proxy configuration wrong**
```bash
# Check Nginx config syntax
docker exec image-upload-frontend nginx -t

# View Nginx config
docker exec image-upload-frontend cat /etc/nginx/conf.d/default.conf

# Restart Nginx
docker-compose restart image-upload-frontend
```

---

## Performance Monitoring

### Container Resource Usage
```bash
# Real-time stats
docker stats

# View more details
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Log Monitoring (Real-time)
```bash
# Follow frontend logs
docker logs -f image-upload-frontend

# Follow backend logs
docker logs -f image-upload-backend

# Combined logs (requires manual view)
docker-compose logs -f
```

### Disk Usage
```bash
# Total usage
du -sh /data/

# Breakdown
du -sh /data/uploads/
du -sh /data/mediadb/

# Files per type
find /data/uploads -type f | wc -l
ls -la /data/uploads/images/ | wc -l
ls -la /data/uploads/videos/ | wc -l
```

---

## Container Maintenance

### View Container Details
```bash
# Full container info
docker inspect image-upload-backend
docker inspect image-upload-frontend

# Network configuration
docker inspect image-upload-backend | grep -A 20 '"Networks"'
```

### Update and Rebuild

**Pull latest code**
```bash
cd /root/app
git pull origin main
```

**Rebuild images**
```bash
# Backend only
docker build -t image-upload-service:1.0.0 backend/
docker-compose up -d image-upload-backend

# Frontend only
docker build -t image-upload-frontend:1.0.0 frontend/
docker-compose up -d image-upload-frontend

# Both
docker build -t image-upload-service:1.0.0 backend/ && \
docker build -t image-upload-frontend:1.0.0 frontend/ && \
docker-compose up -d
```

### Clean Up

**Remove stopped containers**
```bash
docker container prune -f
```

**Remove unused images**
```bash
docker image prune -f
```

**View system usage**
```bash
docker system df
docker system df -v | head -50
```

---

## Database Management

### H2 Database Status
```bash
# Check database file
ls -la /data/mediadb/

# View file size
du -h /data/mediadb/

# Backup database (IMPORTANT!)
cp /data/mediadb/mediadb.mv.db /data/mediadb/mediadb.mv.db.backup
```

### Reset Database (Dangerous!)
```bash
# Stop services
docker-compose down

# Backup existing database
cp /data/mediadb/mediadb.mv.db /data/mediadb/mediadb.mv.db.old

# Delete database (will recreate on restart)
rm /data/mediadb/mediadb.*

# Restart services
docker-compose up -d

# Verify new database created
ls -la /data/mediadb/
```

---

## Network Debugging

### Check Docker Network
```bash
# List networks
docker network ls

# Inspect app network
docker network inspect app_app-network

# Test connectivity between containers
docker exec image-upload-frontend ping image-upload-backend
docker exec image-upload-backend ping image-upload-frontend
```

### Port Mapping
```bash
# View port bindings
docker-compose ps
docker port image-upload-frontend
docker port image-upload-backend

# Verify ports accessible from host
netstat -tuln | grep -E "80|8080"

# Test from outside server
# From your local machine:
curl -I http://192.168.1.251
```

---

## Log Analysis

### Extract Specific Errors
```bash
# All errors in backend
docker logs image-upload-backend | grep -i error

# All warnings
docker logs image-upload-backend | grep -i warning

# Java exceptions
docker logs image-upload-backend | grep -i "exception\|caused by"

# Nginx errors
docker logs image-upload-frontend | grep -i error
```

### Parse Upload Attempts
```bash
# Find all upload requests
docker logs image-upload-backend | grep -i "upload\|/api/upload"

# Find all errors from specific time
docker logs image-upload-backend --since 10m | grep error
```

---

## Recovery Procedures

### If Everything Crashes
```bash
# 1. Stop all services
docker-compose down

# 2. Check data integrity
ls -la /data/uploads/
ls -la /data/mediadb/

# 3. Restart services
docker-compose up -d

# 4. Verify health
docker-compose ps
sleep 10
curl http://localhost/
curl http://localhost:8080/api/media
```

### If Database is Corrupted
```bash
# 1. Stop services
docker-compose down

# 2. Backup corrupted database
mv /data/mediadb/mediadb.mv.db /data/mediadb/mediadb.mv.db.corrupted

# 3. Restart (will create new empty database)
docker-compose up -d

# 4. Verify
docker logs image-upload-backend | tail -20
```

### If Out of Disk Space
```bash
# 1. Check what's using space
du -sh /data/* | sort -h

# 2. If uploads folder is huge
find /data/uploads -type f -mtime +30 -delete  # Delete files older than 30 days

# 3. Or manually delete oldest files
ls -lt /data/uploads/images/ | tail -10  # Oldest files
# Then delete specific files:
rm /data/uploads/images/old-file-uuid.jpg

# 4. Verify space freed
df -h /data/
```

---

## Verification Checklist After Restart

- [ ] Run `docker-compose ps` - both containers showing "Up"
- [ ] Run `curl http://localhost/` - returns HTML
- [ ] Run `curl http://localhost:8080/api/media` - returns JSON
- [ ] Check `/data/uploads/` directory exists
- [ ] Check `/data/mediadb/` directory has database files
- [ ] Test from browser: http://192.168.1.251
- [ ] Try uploading a photo (small file)
- [ ] Check `/data/uploads/images/` for new file
- [ ] Try taking a new video
- [ ] Check `/data/uploads/videos/` for new file
- [ ] Check `/data/mediadb/mediadb.mv.db` file size increased
- [ ] View full logs: `docker-compose logs --tail=100`
- [ ] Check system resources: `docker stats --no-stream`

---

## Emergency Contacts & Resources

**If you need to reset everything:**
```bash
# Backup all data first
tar -czf /root/backup-data-$(date +%Y%m%d).tar.gz /data/

# Then reset
docker-compose down -v  # Removes containers and volumes
```

**Useful Commands Reference:**
```bash
# Quick access
docker-compose ps              # Status
docker-compose logs -f         # Live logs
docker-compose restart         # Restart all
docker exec CONTAINER COMMAND  # Run command in container
docker inspect CONTAINER       # See all details
```

---

## What to Include When Reporting Issues

When something breaks, gather this information:

```bash
# 1. Container status
docker-compose ps > status.txt

# 2. Error logs (last 100 lines)
docker logs image-upload-backend | tail -100 > backend-logs.txt
docker logs image-upload-frontend | tail -100 > frontend-logs.txt

# 3. System info
docker system df > system-info.txt
df -h >> system-info.txt
docker network ls >> system-info.txt

# 4. Data integrity
ls -la /data/ > data-structure.txt

# 5. Docker version
docker --version >> docker-info.txt
docker-compose --version >> docker-info.txt
```

---

**Need help? Check DEPLOYMENT_STEPS.md or DEPLOYMENT_CHECKLIST.md**
