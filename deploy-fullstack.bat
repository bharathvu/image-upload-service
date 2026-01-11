@echo off
REM Full Stack Docker Deployment Script for Windows
REM Builds and deploys both frontend and backend to 192.168.1.251

setlocal enabledelayedexpansion

set PROJECT_DIR=C:\Users\bhara\Downloads\prog-space\java\image-upload-service
set BACKEND_VERSION=1.0.0
set FRONTEND_VERSION=1.0.0
set REMOTE_HOST=192.168.1.251
set REMOTE_USER=root
set REMOTE_TMP=/tmp
set REMOTE_APP=/root/app

echo.
echo ==========================================
echo Image Upload Service - Full Stack Deploy
echo ==========================================
echo.

REM Colors for output (Windows 10+)
if "%OS%" == "Windows_NT" (
    for /F %%A in ('copy /Z "%~f0" nul') do set "ESC=%%A"
)

echo.
echo [1/6] Building Backend Docker Image...
cd /d "%PROJECT_DIR%\backend"
docker build -t image-upload-service:%BACKEND_VERSION% .
if errorlevel 1 (
    echo ERROR: Failed to build backend image
    goto :error
)
echo DONE: Backend image built successfully
echo.

echo [2/6] Building Frontend Docker Image...
cd /d "%PROJECT_DIR%\frontend"
docker build -t image-upload-frontend:%FRONTEND_VERSION% .
if errorlevel 1 (
    echo ERROR: Failed to build frontend image
    goto :error
)
echo DONE: Frontend image built successfully
echo.

echo [3/6] Exporting Docker Images...
cd /d "%PROJECT_DIR%"

echo   - Exporting backend image...
docker save image-upload-service:%BACKEND_VERSION% | gzip > image-upload-service-%BACKEND_VERSION%.tar.gz
if errorlevel 1 (
    echo ERROR: Failed to export backend image
    goto :error
)
for %%F in (image-upload-service-%BACKEND_VERSION%.tar.gz) do (
    echo   DONE: Backend exported (!CD!\%%F)
)
echo.

echo   - Exporting frontend image...
docker save image-upload-frontend:%FRONTEND_VERSION% | gzip > image-upload-frontend-%FRONTEND_VERSION%.tar.gz
if errorlevel 1 (
    echo ERROR: Failed to export frontend image
    goto :error
)
for %%F in (image-upload-frontend-%FRONTEND_VERSION%.tar.gz) do (
    echo   DONE: Frontend exported (!CD!\%%F)
)
echo.

echo [4/6] Transferring Images to Remote Server...
echo   - Requires SSH/SCP configured for %REMOTE_USER%@%REMOTE_HOST%
echo.
echo   - Transferring backend image...
scp image-upload-service-%BACKEND_VERSION%.tar.gz %REMOTE_USER%@%REMOTE_HOST%:%REMOTE_TMP%/
if errorlevel 1 (
    echo ERROR: Failed to transfer backend image
    goto :error
)
echo   DONE
echo.

echo   - Transferring frontend image...
scp image-upload-frontend-%FRONTEND_VERSION%.tar.gz %REMOTE_USER%@%REMOTE_HOST%:%REMOTE_TMP%/
if errorlevel 1 (
    echo ERROR: Failed to transfer frontend image
    goto :error
)
echo   DONE
echo.

echo [5/6] Loading Images on Remote Server...
ssh %REMOTE_USER%@%REMOTE_HOST% ^
    "docker load ^< %REMOTE_TMP%/image-upload-service-%BACKEND_VERSION%.tar.gz && echo DONE: Backend loaded"
if errorlevel 1 (
    echo ERROR: Failed to load backend image
    goto :error
)

ssh %REMOTE_USER%@%REMOTE_HOST% ^
    "docker load ^< %REMOTE_TMP%/image-upload-frontend-%FRONTEND_VERSION%.tar.gz && echo DONE: Frontend loaded"
if errorlevel 1 (
    echo ERROR: Failed to load frontend image
    goto :error
)

ssh %REMOTE_USER%@%REMOTE_HOST% ^
    "rm %REMOTE_TMP%/image-upload-*.tar.gz && mkdir -p /data/uploads /data/mediadb && chmod -R 755 /data && echo DONE: Cleanup complete"
if errorlevel 1 (
    echo WARNING: Cleanup had issues but continuing...
)
echo.

echo [6/6] Starting Containers...
ssh %REMOTE_USER%@%REMOTE_HOST% ^
    "mkdir -p %REMOTE_APP% && cd %REMOTE_APP% && docker-compose up -d"
if errorlevel 1 (
    echo.
    echo NOTE: If docker-compose.yml doesn't exist on remote, you need to:
    echo   1. Copy docker-compose.yml to %REMOTE_USER%@%REMOTE_HOST%:%REMOTE_APP%/
    echo   2. Run: ssh %REMOTE_USER%@%REMOTE_HOST% "cd %REMOTE_APP% && docker-compose up -d"
    echo.
)

echo.
echo Verifying deployment...
ssh %REMOTE_USER%@%REMOTE_HOST% "cd %REMOTE_APP% && docker-compose ps"
echo.

echo ==========================================
echo DEPLOYMENT COMPLETE!
echo ==========================================
echo.
echo Frontend URL: http://%REMOTE_HOST%
echo Backend API: http://%REMOTE_HOST%:8080/api
echo Health Check: http://%REMOTE_HOST%/health.html
echo.
echo Next Steps:
echo   1. Copy docker-compose.yml if not already there:
echo      scp docker-compose.yml root@%REMOTE_HOST%:%REMOTE_APP%/
echo.
echo   2. View logs:
echo      ssh root@%REMOTE_HOST% "cd %REMOTE_APP% && docker-compose logs -f"
echo.
echo   3. Test the API:
echo      curl http://%REMOTE_HOST%:8080/api/media
echo.
echo   4. Test frontend:
echo      Open http://%REMOTE_HOST% in your browser
echo.
goto :end

:error
echo.
echo ERROR: Deployment failed!
echo.
pause
exit /b 1

:end
echo.
pause
