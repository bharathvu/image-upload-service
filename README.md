# Media Capture and Upload Service

A full-stack application for capturing photos and recording videos through the web browser, with a Spring Boot backend for storage.

## Project Structure

```
image-upload-service/
├── backend/                 # Spring Boot backend
│   ├── src/
│   │   └── main/
│   │       ├── java/com/mediaupload/
│   │       │   ├── config/
│   │       │   ├── controller/
│   │       │   ├── dto/
│   │       │   ├── entity/
│   │       │   ├── repository/
│   │       │   └── service/
│   │       └── resources/
│   └── pom.xml
├── frontend/                # React frontend
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   ├── services/
│   │   ├── App.js
│   │   └── index.js
│   └── package.json
└── README.md
```

## Features

### Frontend
- 📷 **Photo Capture**: Take photos using your device's camera
- 🎥 **Video Recording**: Record videos with audio
- 📁 **Media Gallery**: View, filter, and manage uploaded media
- 📱 **Responsive Design**: Works on desktop and mobile devices

### Backend
- ☁️ **File Upload API**: RESTful endpoints for uploading images and videos
- 💾 **File Storage**: Local file system storage with organized directories
- 🗃️ **Database**: H2 database for metadata storage
- 🔄 **CORS Support**: Cross-origin requests enabled for frontend communication

## Prerequisites

- **Java 17** or higher
- **Maven 3.6+**
- **Node.js 16+** and **npm**

## Getting Started

### 1. Backend Setup

**Option A: Maven**
```bash
cd backend
mvn spring-boot:run
```

**Option B: Docker**
```bash
cd backend
docker build -t image-upload-service:1.0.0 .
docker run -p 8080:8080 -v $(pwd)/uploads:/app/uploads image-upload-service:1.0.0
```

**Option C: Docker Compose**
```bash
docker-compose up -d
```

Backend runs on: `http://localhost:8080`

### 2. Frontend Setup

```bash
cd frontend
npm install
npm run build
serve -s build -l 3000
```

Frontend runs on: `http://localhost:3000`

## Docker Deployment

### Build Docker Image

```bash
cd backend
docker build -t image-upload-service:1.0.0 .
```

### Run Container

```bash
docker run -d \
  --name image-upload-backend \
  -p 8080:8080 \
  -v $(pwd)/uploads:/app/uploads \
  --restart unless-stopped \
  image-upload-service:1.0.0
```

### Deploy to Remote Server (192.168.1.251)

See [REMOTE_DEPLOYMENT.md](REMOTE_DEPLOYMENT.md) for detailed instructions on deploying to the remote server at 192.168.1.251.

Quick deployment:
```bash
# Build and save image
docker build -t image-upload-service:1.0.0 backend/
docker save image-upload-service:1.0.0 | gzip > image-upload-service-1.0.0.tar.gz

# Transfer to remote server
scp image-upload-service-1.0.0.tar.gz root@192.168.1.251:/tmp/

# SSH into remote and deploy
ssh root@192.168.1.251
docker load < /tmp/image-upload-service-1.0.0.tar.gz
mkdir -p /data/uploads
docker run -d -p 8080:8080 -v /data/uploads:/app/uploads --restart unless-stopped image-upload-service:1.0.0
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/media/upload/image` | Upload an image |
| POST | `/api/media/upload/video` | Upload a video |
| GET | `/api/media` | Get all media files |
| GET | `/api/media/images` | Get all images |
| GET | `/api/media/videos` | Get all videos |
| GET | `/api/media/{id}` | Get media file info |
| GET | `/api/media/{id}/download` | Download/stream media file |
| DELETE | `/api/media/{id}` | Delete a media file |

## Configuration

### Backend (`application.properties`)
- `file.upload-dir`: Directory for storing uploaded files (default: `./uploads`)
- `spring.servlet.multipart.max-file-size`: Maximum upload size (default: 100MB)

### Frontend
- `REACT_APP_API_URL`: Backend API URL (default: `http://localhost:8080/api`)

## Browser Permissions

The application requires camera and microphone permissions to function:
- **Camera**: Required for photo capture and video recording
- **Microphone**: Required for video recording with audio

## Technology Stack

### Backend
- Spring Boot 3.2
- Spring Data JPA
- H2 Database
- Lombok

### Frontend
- React 18
- Axios for HTTP requests
- MediaRecorder API for video recording
- Canvas API for photo capture
