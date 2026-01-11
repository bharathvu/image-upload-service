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

### 1. Start the Backend Server

```bash
cd backend
mvn spring-boot:run
```

The backend will start on `http://localhost:8080`

### 2. Start the Frontend Development Server

```bash
cd frontend
npm install
npm start
```

The frontend will start on `http://localhost:3000`

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
