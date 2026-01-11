# Deployment Visual Guide - 192.168.1.251

## Overview of What Happens

```
Your Windows Machine              Ubuntu Server (192.168.1.251)
                                 ┌─────────────────────────────┐
                                 │      Before Deployment      │
                                 │  • Empty directories        │
                                 │  • No Docker images         │
                                 │  • No containers running    │
                                 └─────────────────────────────┘
                                           ▲
                                           │
                            ssh root@192.168.1.251
                                           │
                                           ▼
                                 ┌─────────────────────────────┐
                                 │  Step 1-2: Prepare (1 min)  │
                                 │  • mkdir /root/app          │
                                 │  • mkdir /data/uploads      │
                                 │  • mkdir /data/mediadb      │
                                 └─────────────────────────────┘
                                           ▲
                                           │
                            git clone (repository)
                                           │
                                           ▼
                                 ┌─────────────────────────────┐
                                 │   Step 3: Clone (1 min)     │
                                 │  • Docker files downloaded  │
                                 │  • Source code present      │
                                 │  • Ready to build           │
                                 └─────────────────────────────┘
                                           ▲
                                           │
                             docker build backend/
                                           │
                                           ▼
                                 ┌─────────────────────────────┐
                                 │  Step 4: Build Backend      │
                                 │         (3-5 minutes)       │
                                 │  • Maven compile            │
                                 │  • Package JAR              │
                                 │  • Create Docker image      │
                                 │  • Size: ~300MB             │
                                 └─────────────────────────────┘
                                           ▲
                                           │
                             docker build frontend/
                                           │
                                           ▼
                                 ┌─────────────────────────────┐
                                 │  Step 5: Build Frontend     │
                                 │         (1-3 minutes)       │
                                 │  • npm install              │
                                 │  • npm build                │
                                 │  • Create Docker image      │
                                 │  • Size: ~100MB             │
                                 └─────────────────────────────┘
                                           ▲
                                           │
                            docker-compose up -d
                                           │
                                           ▼
                                 ┌─────────────────────────────┐
                                 │  Step 6: Deploy (1 min)     │
                                 │  • Start Frontend container │
                                 │  • Start Backend container  │
                                 │  • Create Docker network    │
                                 │  • Mount volumes            │
                                 └─────────────────────────────┘
                                           ▲
                                           │
                                  curl /docker ps
                                           │
                                           ▼
                                 ┌─────────────────────────────┐
                                 │   After Deployment          │
                                 │  ✅ Frontend (nginx:80)     │
                                 │  ✅ Backend (spring:8080)   │
                                 │  ✅ Network connected       │
                                 │  ✅ Data volumes mounted    │
                                 │  ✅ Services healthy        │
                                 └─────────────────────────────┘
                                           ▲
                                           │
                                 Browser access:
                                           │
           ┌─────────────────┬─────────────┴──────┬──────────────────┐
           │                 │                    │                  │
           ▼                 ▼                    ▼                  ▼
      Frontend          API Gateway           Health Check      Media List
http://192.168.1.251  :8080/api/*           /health.html      /api/media
```

---

## Step-by-Step Process

### STEP 1: SSH Connection
```
Input:  ssh root@192.168.1.251
Output: root@192.168.1.251:~#
Status: Connected ✅
```

### STEP 2: Directory Preparation
```
mkdir -p /root/app /data/uploads /data/mediadb
chmod -R 755 /data

/root/
├── app/                    ← App directory (empty)
└── /data/
    ├── uploads/            ← For uploaded media
    └── mediadb/            ← For database files
```

### STEP 3: Clone Repository
```
git clone https://github.com/bharathvu/image-upload-service.git .

/root/app/
├── backend/
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   └── src/
├── docker-compose.yml
└── ... (other files)
```

### STEP 4: Build Backend Image
```
Time: 3-5 minutes

Progress:
[+] Building 180.3s
  => [builder] Docker base image (maven:3.9-eclipse-temurin-17)
  => Download dependencies
  => Compile source code
  => Package as JAR
  => Create final image

Result: image-upload-service:1.0.0 (300MB)
```

### STEP 5: Build Frontend Image
```
Time: 1-3 minutes

Progress:
[+] Building 150.2s
  => [builder] Docker base image (node:18-alpine)
  => npm install dependencies
  => npm build React app
  => Copy to nginx
  => Create final image

Result: image-upload-frontend:1.0.0 (100MB)
```

### STEP 6: Deploy with Docker Compose
```
docker-compose up -d

Creates:
  Container 1: image-upload-frontend:1.0.0
    - Port: 80
    - Network: app-network
    - Health check: /health.html

  Container 2: image-upload-service:1.0.0
    - Port: 8080
    - Network: app-network
    - Health check: /api/media

  Volumes:
    - /data/uploads → /app/uploads
    - /data/mediadb → /app/data
```

### STEP 7: Verify Deployment
```
docker-compose ps

Output:
NAME                      STATUS           PORTS
image-upload-backend      Up 2 minutes     0.0.0.0:8080->8080/tcp
image-upload-frontend     Up 1 minute      0.0.0.0:80->80/tcp

Status: ✅ Both UP
```

### STEP 8: Test Application
```
Tests:
  ✅ curl http://localhost/              → HTML (Frontend)
  ✅ curl http://localhost:8080/api/media → [] (Backend)
  ✅ curl http://localhost/health.html   → OK (Health)
```

---

## Network Architecture After Deployment

```
┌─────────────────────────────────────────────────────────┐
│                    Internet / Browser                   │
└─────────────────────────────────────────────────────────┘
                            │
                   HTTP Port 80 & 8080
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌──────────────────┐                  ┌──────────────────┐
│   Nginx Server   │                  │  Direct Backend  │
│  (Port 80)       │                  │  (Port 8080)     │
│  - React App     │                  │  - REST API      │
│  - Static Files  │                  │  - File upload   │
│  - Reverse Proxy │                  │  - Database      │
└──────────────────┘                  └──────────────────┘
        │                                       │
        └────────────────────┬──────────────────┘
                             │
                   Docker Internal Network
                        app-network
                             │
         ┌───────────────────┴───────────────────┐
         │                                       │
         ▼                                       ▼
   ┌─────────────┐                         ┌─────────────┐
   │ Frontend    │    /api/* proxied to   │  Backend    │
   │ Container   │◄──────────────────────►│  Container  │
   │             │   (port 8080)          │             │
   └─────────────┘                         └─────────────┘
         │                                       │
         ├──────────────────┬────────────────────┤
         │                  │                    │
         ▼                  ▼                    ▼
    Volumes         /data/uploads         /data/mediadb
   (nginx.conf)     (uploaded files)      (H2 database)
```

---

## Data Flow During Deployment

### Timeline

```
Time    Action              Duration    Cumulative   Status
────    ──────────────────  ────────    ──────────   ──────
0:00    SSH Connect         0 sec       0:00         🔐 Auth
0:15    Prepare dirs        15 sec      0:15         📁 Ready
0:25    Clone repo          10 sec      0:25         📥 Code
0:35    Start backend build 10 sec      0:35         🏗️  Building
3:35    Backend image       3 min       3:35         ✅ Image 1
3:45    Start frontend build 10 sec     3:45         🏗️  Building
5:45    Frontend image      2 min       5:45         ✅ Image 2
5:50    Deploy compose      5 sec       5:50         🚀 Starting
6:00    Services health     10 sec      6:00         💚 Healthy
6:05    Tests pass          5 sec       6:05         ✅ SUCCESS
────────────────────────────────────────────────────────
                                Total: 6-15 minutes
```

---

## File Organization After Deployment

```
Ubuntu Server (192.168.1.251)
│
├── /root/
│   ├── app/                              (Git repository)
│   │   ├── backend/
│   │   │   ├── Dockerfile
│   │   │   ├── src/                      (Java source)
│   │   │   └── target/
│   │   │       └── app.jar               (Built JAR)
│   │   │
│   │   ├── frontend/
│   │   │   ├── Dockerfile
│   │   │   ├── src/                      (React source)
│   │   │   └── build/                    (Built React app)
│   │   │
│   │   └── docker-compose.yml            (Orchestration)
│   │
│   └── docker-compose.log                (Logs)
│
└── /data/
    ├── uploads/                          (Volume mounted)
    │   ├── images/
    │   │   ├── uuid1.jpg
    │   │   └── uuid2.jpg
    │   │
    │   └── videos/
    │       ├── uuid1.mp4
    │       └── uuid2.webm
    │
    └── mediadb/                          (Volume mounted)
        ├── mediadb.mv.db                 (Database file)
        └── mediadb.trace.db              (Trace file)

Docker Containers:
├── image-upload-frontend:1.0.0
│   ├── Port: 80 (Nginx)
│   ├── Volumes: nginx.conf
│   └── Status: Running ✅
│
└── image-upload-service:1.0.0
    ├── Port: 8080 (Spring Boot)
    ├── Volumes: /data/uploads, /data/mediadb
    └── Status: Running ✅
```

---

## Expected Output During Deployment

### Docker Build Backend
```
[+] Building 180.3s (16/16) FINISHED
 => [internal] load build definition from Dockerfile
 => [builder 1/6] FROM maven:3.9-eclipse-temurin-17-alpine
 => [builder 2/6] WORKDIR /app
 => [builder 3/6] COPY pom.xml .
 => [builder 4/6] RUN mvn dependency:go-offline -B
 => [builder 5/6] COPY src ./src
 => [builder 6/6] RUN mvn clean package -DskipTests
 => [stage-1 1/4] FROM eclipse-temurin:17-jdk-alpine
 => [stage-1 2/4] WORKDIR /app
 => [stage-1 3/4] COPY --from=builder /app/target/*.jar app.jar
 => [stage-1 4/4] RUN mkdir -p /app/uploads/images /app/uploads/videos
 => exporting to image
 => => writing image sha256:abc123...
 => => naming to docker.io/library/image-upload-service:1.0.0

Successfully tagged image-upload-service:1.0.0
```

### Docker Compose Up
```
Creating network "app_app-network" with driver "bridge"
Creating image-upload-backend  ... done
Creating image-upload-frontend ... done
```

### Docker Compose PS
```
NAME                      STATUS                      PORTS
image-upload-backend      Up 2 minutes (healthy)      0.0.0.0:8080->8080/tcp
image-upload-frontend     Up 1 minute (healthy)       0.0.0.0:80->80/tcp
```

---

## Access After Successful Deployment

### From Ubuntu Server (SSH)
```bash
curl http://localhost/              # Returns HTML
curl http://localhost:8080/api/media # Returns []
curl http://localhost/health.html    # Returns OK
docker-compose logs                 # Shows service logs
```

### From Your Local Browser
```
Frontend:   http://192.168.1.251
Backend:    http://192.168.1.251:8080/api
Health:     http://192.168.1.251/health.html
```

---

## Success Indicators

✅ SSH connected to server
✅ Directories created successfully
✅ Repository cloned
✅ Backend image built (300MB)
✅ Frontend image built (100MB)
✅ Containers running (docker-compose ps shows UP)
✅ Both health checks passing
✅ Frontend loads in browser
✅ API responds with data

---

## What Happens Next

1. ✅ Application is live at http://192.168.1.251
2. ✅ Both services are running
3. ✅ Data persists in /data/ volumes
4. ✅ Services auto-restart if they fail
5. ✅ Can upload/download/manage media
6. ✅ Full API available for integration

---

## Troubleshooting Visual

```
Issue: Frontend not loading
  │
  ├─ Check: curl http://localhost/
  ├─ Check: docker logs image-upload-frontend
  ├─ Check: docker inspect image-upload-frontend
  └─ Fix: docker-compose restart image-upload-frontend

Issue: Backend API not responding
  │
  ├─ Check: curl http://localhost:8080/api/media
  ├─ Check: docker logs image-upload-backend
  ├─ Check: docker exec image-upload-backend ps aux | grep java
  └─ Fix: docker-compose restart image-upload-backend

Issue: Upload fails
  │
  ├─ Check: ls -la /data/uploads/
  ├─ Check: chmod -R 755 /data/
  ├─ Check: docker logs image-upload-backend
  └─ Fix: Check disk space and permissions
```

---

**Ready to deploy? Follow the step-by-step guide in DEPLOYMENT_STEPS.md! 🚀**
