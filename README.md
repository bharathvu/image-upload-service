# Image Upload Service - Full-Stack Photo/Video Application

A complete full-stack web application for capturing, uploading, and managing photos and videos with **Docker containerization** and production-ready deployment.

**Status:** ✅ Deployment-Ready (v1.2.0)

## 🚀 Quick Start (Deployment to 192.168.1.251)

### Read these files in order:
1. [DEPLOYMENT_NAVIGATION.md](DEPLOYMENT_NAVIGATION.md) - Where to start (2 min)
2. [DEPLOY_NOW.txt](DEPLOY_NOW.txt) - Quick reference (2 min)
3. [DEPLOYMENT_VISUAL_GUIDE.md](DEPLOYMENT_VISUAL_GUIDE.md) - Understand the flow (5 min)
4. [DEPLOYMENT_STEPS.md](DEPLOYMENT_STEPS.md) - Actually deploy (follow step-by-step)

**Estimated deployment time:** 10-15 minutes

## 📦 What's Included

### Frontend Application
- ⚛️ **React 18.2.0** - Modern UI framework
- 📷 **Photo Capture** - Canvas API for instant photo capture
- 🎥 **Video Recording** - MediaRecorder API for video recording
- 🖼️ **Gallery** - Browse, filter, and manage media
- 🔍 **Responsive Design** - Works on desktop, tablet, mobile
- ✨ **Modern UI** - Clean, intuitive interface

### Backend API
- 🍃 **Spring Boot 3.2.0** - Enterprise Java framework
- 📡 **REST API** - Full CRUD operations for media management
- 💾 **H2 Database** - Embedded database with JPA persistence
- 🔐 **File Storage** - Secure upload/download handling
- 🚀 **Production-Ready** - Health checks, error handling, logging

### DevOps & Infrastructure
- 🐳 **Docker** - Multi-stage builds for optimized images
- 📦 **Docker Compose** - Complete service orchestration
- 🔄 **CI/CD Ready** - Git integration, versioning
- 🌐 **Nginx Reverse Proxy** - API gateway and static serving
- 📊 **Monitoring** - Health checks, logging, status endpoints

## Getting Started

### 1. Backend Setup

**Option A: Maven**
```bash
cd backend
mvn spring-boot:run
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    End User (Browser)                   │
└─────────────────────────────────────────────────────────┘
                            │
                   HTTP (Port 80 & 8080)
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌──────────────────┐                  ┌──────────────────┐
│  Nginx Server    │                  │  Spring Boot API │
│  (Port 80)       │                  │  (Port 8080)     │
│  - React SPA     │                  │  - REST API      │
│  - Static Files  │                  │  - File Storage  │
│  - Reverse Proxy │                  │  - H2 Database   │
└──────────────────┘                  └──────────────────┘
```

## 📊 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/media` | List all media |
| POST | `/api/upload` | Upload photo/video |
| GET | `/api/media/{id}` | Get media details |
| DELETE | `/api/media/{id}` | Delete media |
| GET | `/api/download/{id}` | Download media |
| GET | `/health` | Health check |

## 🐳 Deployment Options

### Option 1: Build on Ubuntu Server (RECOMMENDED ✅)
- Time: 10-15 minutes
- Difficulty: Medium
- Success Rate: 95%
- See: [DEPLOYMENT_STEPS.md](DEPLOYMENT_STEPS.md)

### Option 2: Build on Windows → Transfer
- Time: 20-30 minutes
- Difficulty: Advanced
- Success Rate: 70%
- See: [FULLSTACK_DEPLOYMENT.md](FULLSTACK_DEPLOYMENT.md)

## 💾 Data Storage

- **Frontend:** Runs on Nginx (port 80)
- **Backend API:** Runs on Spring Boot (port 8080)
- **Uploaded Files:** `/data/uploads/`
- **Database:** `/data/mediadb/` (H2)

## ✅ Verification

After deployment:
```bash
# Check services
docker-compose ps

# Test frontend
http://192.168.1.251

# Test backend API
http://192.168.1.251:8080/api/media

# View logs
docker-compose logs --tail=50
```

## 🐛 Troubleshooting

See [POST_DEPLOYMENT_TROUBLESHOOTING.md](POST_DEPLOYMENT_TROUBLESHOOTING.md) for comprehensive troubleshooting guide.

Common issues:
- **Connection refused:** Check `docker-compose ps`
- **502 error:** Check `docker logs image-upload-backend`
- **File upload fails:** Check permissions `chmod -R 777 /data/uploads/`
- **Slow uploads:** Check disk space `df -h /data/`

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [DEPLOYMENT_NAVIGATION.md](DEPLOYMENT_NAVIGATION.md) | Where to start |
| [DEPLOYMENT_STEPS.md](DEPLOYMENT_STEPS.md) | Main deployment guide |
| [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) | Verify deployment |
| [POST_DEPLOYMENT_TROUBLESHOOTING.md](POST_DEPLOYMENT_TROUBLESHOOTING.md) | Fix issues |
| [DEPLOYMENT_VISUAL_GUIDE.md](DEPLOYMENT_VISUAL_GUIDE.md) | Understand flow |
| [QUICK_START_DEPLOY.md](QUICK_START_DEPLOY.md) | Deployment options |
| [BUILD_ON_UBUNTU.md](BUILD_ON_UBUNTU.md) | Alternative method |
| [START_HERE.md](START_HERE.md) | Project overview |
| [FULLSTACK_DEPLOYMENT.md](FULLSTACK_DEPLOYMENT.md) | Complete guide |

## 📖 Repository

**GitHub:** https://github.com/bharathvu/image-upload-service

**Versions:**
- v1.0.0 - Initial release
- v1.1.0 - Backend Docker support
- v1.2.0 - Full-stack Docker (current)

## 🚀 Get Started

1. Read [DEPLOYMENT_NAVIGATION.md](DEPLOYMENT_NAVIGATION.md)
2. Follow [DEPLOYMENT_STEPS.md](DEPLOYMENT_STEPS.md)
3. Verify with [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

**Estimated Time:** 10-15 minutes  
**Target:** 192.168.1.251
