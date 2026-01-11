# Manual Deployment to 192.168.1.251 - Step by Step

## Prerequisites Verification

Before starting, ensure you have:
✅ SSH access to `root@192.168.1.251`
✅ Ubuntu Server running at 192.168.1.251
✅ Administrator password or SSH key configured

---

## Step 1: SSH into Ubuntu Server

Open your terminal/PowerShell and connect:

```bash
ssh root@192.168.1.251
```

You'll be prompted for the password. Enter it and press Enter.

**Expected output:**
```
Welcome to Ubuntu ...
root@192.168.1.251:~#
```

---

## Step 2: Prepare the Server (Run on Ubuntu)

```bash
# Create necessary directories
mkdir -p /root/app /data/uploads /data/mediadb

# Set permissions
chmod -R 755 /data

# Verify directories
ls -la /data/
```

**Expected output:**
```
total 16
drwxr-xr-x  4 root root 4096 Jan 11 12:00 .
drwxr-xr-x 27 root root 4096 Jan 11 12:00 ..
drwxr-xr-x  2 root root 4096 Jan 11 12:00 mediadb
drwxr-xr-x  2 root root 4096 Jan 11 12:00 uploads
```

---

## Step 3: Clone Repository (Run on Ubuntu)

```bash
cd /root/app
git clone https://github.com/bharathvu/image-upload-service.git .
```

**Expected output:**
```
Cloning into '.'...
remote: Enumerating objects: ...
...
```

Verify clone:
```bash
ls -la
# Should show: backend/, frontend/, docker-compose.yml, etc.
```

---

## Step 4: Build Backend Image (Run on Ubuntu)

```bash
cd /root/app
docker build -t image-upload-service:1.0.0 backend/
```

**This will take 3-5 minutes.** You'll see:
```
[+] Building 180.3s (16/16) FINISHED
...
=> naming to docker.io/library/image-upload-service:1.0.0
```

**Verify:**
```bash
docker images | grep image-upload-service
```

**Expected output:**
```
image-upload-service     1.0.0    <sha>  3 minutes ago  300MB
```

---

## Step 5: Build Frontend Image (Run on Ubuntu)

```bash
docker build -t image-upload-frontend:1.0.0 frontend/
```

**This will take 1-3 minutes.** You'll see:
```
[+] Building 150.2s (15/15) FINISHED
...
=> naming to docker.io/library/image-upload-frontend:1.0.0
```

**Verify:**
```bash
docker images | grep image-upload-frontend
```

**Expected output:**
```
image-upload-frontend    1.0.0    <sha>  1 minute ago   100MB
```

---

## Step 6: Verify Both Images Built

```bash
docker images | grep image-upload
```

**Expected output:**
```
image-upload-frontend       1.0.0    <sha>  1 minute ago   100MB
image-upload-service        1.0.0    <sha>  3 minutes ago  300MB
```

If both images are present, continue. If not, check build logs above.

---

## Step 7: Deploy with Docker Compose

```bash
cd /root/app
docker-compose up -d
```

**Expected output:**
```
Creating network "app_app-network" with driver "bridge"
Creating image-upload-backend  ... done
Creating image-upload-frontend ... done
```

---

## Step 8: Verify Services Running

```bash
docker-compose ps
```

**Expected output:**
```
NAME                      STATUS           PORTS
image-upload-backend      Up 2 minutes     0.0.0.0:8080->8080/tcp
image-upload-frontend     Up 1 minute      0.0.0.0:80->80/tcp
```

Both should show **UP** (not unhealthy or restarting).

---

## Step 9: Verify Containers Are Healthy

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

**Expected output:**
```
NAMES                   STATUS
image-upload-frontend   Up 2 minutes (healthy)
image-upload-backend    Up 2 minutes (healthy)
```

---

## Step 10: Test Frontend

```bash
curl http://localhost/
```

**Expected:** HTML response (React app)

Or from your local machine browser:
```
http://192.168.1.251
```

Should show the Image Upload Service interface.

---

## Step 11: Test Backend API

```bash
curl http://localhost:8080/api/media
```

**Expected output:**
```
[]
```

Or from your local machine:
```bash
curl http://192.168.1.251:8080/api/media
```

---

## Step 12: Test Health Checks

```bash
curl http://localhost/health.html
```

**Expected output:**
```
OK
```

---

## ✅ Deployment Complete!

If you've reached here with all tests passing, your deployment is successful!

---

## Access from Your Browser

| Component | URL |
|-----------|-----|
| Frontend | `http://192.168.1.251` |
| Backend API | `http://192.168.1.251:8080/api` |
| Health Check | `http://192.168.1.251/health.html` |
| Media List | `http://192.168.1.251:8080/api/media` |

---

## View Logs

**To see what's happening:**

```bash
docker-compose logs -f
```

Press `Ctrl+C` to exit logs.

**Specific service logs:**
```bash
docker-compose logs -f backend
docker-compose logs -f frontend
```

---

## Troubleshooting

### Issue: "Connection refused" when testing API

**Solution:**
```bash
# Check if containers are still running
docker-compose ps

# Check backend logs
docker logs image-upload-backend

# Restart if needed
docker-compose restart
```

### Issue: Port 80 or 8080 already in use

**Check what's using it:**
```bash
sudo lsof -i :80
sudo lsof -i :8080

# If needed, stop other services and restart
docker-compose restart
```

### Issue: Build fails with network error

**Retry the build:**
```bash
docker build -t image-upload-service:1.0.0 backend/
docker build -t image-upload-frontend:1.0.0 frontend/
```

Or skip the build and use pre-built images from Docker Hub (if available).

### Issue: Can't connect to server

**Verify connectivity:**
```bash
ping 192.168.1.251

# Check SSH
ssh root@192.168.1.251 "echo 'Connected!'"
```

---

## Next Steps After Deployment

### 1. Test Upload Feature
- Go to http://192.168.1.251
- Click "Capture" tab
- Take a photo
- Upload it
- Check Gallery tab

### 2. Monitor Services
```bash
docker-compose logs -f
docker stats
```

### 3. Backup Configuration
```bash
cp docker-compose.yml docker-compose.yml.bak
```

### 4. Setup Auto-start (Optional)
```bash
# Create systemd service
sudo systemctl enable docker
```

---

## Quick Reference Commands

```bash
# View running services
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose stop

# Start services
docker-compose up -d

# Remove containers (data persists in /data/)
docker-compose down

# Check resource usage
docker stats

# Update to new version
# 1. Update images
# 2. docker-compose up -d
```

---

## Estimated Timeline

| Step | Time |
|------|------|
| SSH + Prepare | 1 minute |
| Clone repo | 1 minute |
| Build backend | 3-5 minutes |
| Build frontend | 1-3 minutes |
| Deploy | 1 minute |
| Test | 2 minutes |
| **Total** | **~10-15 minutes** |

---

## Support

If you encounter issues:

1. **Check logs:** `docker-compose logs`
2. **Check services:** `docker-compose ps`
3. **Verify connectivity:** `curl http://localhost:8080/api/media`
4. **Restart:** `docker-compose restart`
5. **Read guides:** See FULLSTACK_DEPLOYMENT.md for detailed help

---

**You're all set! The application should now be running at http://192.168.1.251 🎉**
