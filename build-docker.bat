@echo off
REM Docker build script for Image Upload Service

echo Building Docker image...
cd /d C:\Users\bhara\Downloads\prog-space\java\image-upload-service\backend

docker build -t image-upload-service:1.0.0 .

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Image built successfully!
    echo.
    echo Run the container with:
    echo   docker run -p 8080:8080 -v %%cd%%\uploads:/app/uploads image-upload-service:1.0.0
    echo.
    echo Or use docker-compose:
    echo   cd ..
    echo   docker-compose up -d
) else (
    echo.
    echo Error building image. Make sure Docker is running.
    exit /b 1
)
