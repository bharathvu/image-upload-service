package com.mediaupload.controller;

import com.mediaupload.dto.MediaFileResponse;
import com.mediaupload.dto.UploadResponse;
import com.mediaupload.entity.MediaFile;
import com.mediaupload.service.FileStorageService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/media")
public class MediaController {

    private final FileStorageService fileStorageService;

    public MediaController(FileStorageService fileStorageService) {
        this.fileStorageService = fileStorageService;
    }

    @PostMapping("/upload/image")
    public ResponseEntity<UploadResponse> uploadImage(
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request) {
        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(UploadResponse.error("Please select a file to upload"));
            }

            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return ResponseEntity.badRequest()
                        .body(UploadResponse.error("Only image files are allowed"));
            }

            MediaFile savedFile = fileStorageService.storeFile(file, "IMAGE");
            String baseUrl = getBaseUrl(request);
            MediaFileResponse response = MediaFileResponse.fromEntity(savedFile, baseUrl);

            return ResponseEntity.ok(UploadResponse.success("Image uploaded successfully", response));
        } catch (IOException e) {
            return ResponseEntity.internalServerError()
                    .body(UploadResponse.error("Failed to upload image: " + e.getMessage()));
        }
    }

    @PostMapping("/upload/video")
    public ResponseEntity<UploadResponse> uploadVideo(
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request) {
        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(UploadResponse.error("Please select a file to upload"));
            }

            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("video/")) {
                return ResponseEntity.badRequest()
                        .body(UploadResponse.error("Only video files are allowed"));
            }

            MediaFile savedFile = fileStorageService.storeFile(file, "VIDEO");
            String baseUrl = getBaseUrl(request);
            MediaFileResponse response = MediaFileResponse.fromEntity(savedFile, baseUrl);

            return ResponseEntity.ok(UploadResponse.success("Video uploaded successfully", response));
        } catch (IOException e) {
            return ResponseEntity.internalServerError()
                    .body(UploadResponse.error("Failed to upload video: " + e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<List<MediaFileResponse>> getAllMedia(HttpServletRequest request) {
        String baseUrl = getBaseUrl(request);
        List<MediaFileResponse> files = fileStorageService.getAllMediaFiles(baseUrl);
        return ResponseEntity.ok(files);
    }

    @GetMapping("/images")
    public ResponseEntity<List<MediaFileResponse>> getAllImages(HttpServletRequest request) {
        String baseUrl = getBaseUrl(request);
        List<MediaFileResponse> files = fileStorageService.getMediaFilesByType("IMAGE", baseUrl);
        return ResponseEntity.ok(files);
    }

    @GetMapping("/videos")
    public ResponseEntity<List<MediaFileResponse>> getAllVideos(HttpServletRequest request) {
        String baseUrl = getBaseUrl(request);
        List<MediaFileResponse> files = fileStorageService.getMediaFilesByType("VIDEO", baseUrl);
        return ResponseEntity.ok(files);
    }

    @GetMapping("/{id}")
    public ResponseEntity<MediaFileResponse> getMediaById(
            @PathVariable Long id,
            HttpServletRequest request) {
        try {
            MediaFile mediaFile = fileStorageService.getMediaFile(id);
            String baseUrl = getBaseUrl(request);
            return ResponseEntity.ok(MediaFileResponse.fromEntity(mediaFile, baseUrl));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/{id}/download")
    public ResponseEntity<Resource> downloadFile(@PathVariable Long id) {
        try {
            Resource resource = fileStorageService.loadFileAsResource(id);
            MediaFile mediaFile = fileStorageService.getMediaFile(id);

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(mediaFile.getContentType()))
                    .header(HttpHeaders.CONTENT_DISPOSITION,
                            "inline; filename=\"" + mediaFile.getOriginalFileName() + "\"")
                    .body(resource);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<UploadResponse> deleteFile(@PathVariable Long id) {
        try {
            fileStorageService.deleteFile(id);
            return ResponseEntity.ok(UploadResponse.success("File deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(UploadResponse.error("Failed to delete file: " + e.getMessage()));
        }
    }

    private String getBaseUrl(HttpServletRequest request) {
        String scheme = request.getScheme();
        String serverName = request.getServerName();
        int serverPort = request.getServerPort();

        if ((scheme.equals("http") && serverPort == 80) ||
                (scheme.equals("https") && serverPort == 443)) {
            return scheme + "://" + serverName;
        }
        return scheme + "://" + serverName + ":" + serverPort;
    }
}
