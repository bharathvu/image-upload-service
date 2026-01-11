package com.mediaupload.service;

import com.mediaupload.dto.MediaFileResponse;
import com.mediaupload.entity.MediaFile;
import com.mediaupload.repository.MediaFileRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class FileStorageService {

    private final Path uploadPath;
    private final MediaFileRepository mediaFileRepository;

    public FileStorageService(@Value("${file.upload-dir}") String uploadDir,
                              MediaFileRepository mediaFileRepository) {
        this.uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
        this.mediaFileRepository = mediaFileRepository;
    }

    public MediaFile storeFile(MultipartFile file, String fileType) throws IOException {
        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());
        String fileExtension = getFileExtension(originalFileName);
        String uniqueFileName = UUID.randomUUID().toString() + fileExtension;

        String subDirectory = fileType.equalsIgnoreCase("IMAGE") ? "images" : "videos";
        Path targetLocation = this.uploadPath.resolve(subDirectory).resolve(uniqueFileName);

        Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

        MediaFile mediaFile = new MediaFile();
        mediaFile.setFileName(uniqueFileName);
        mediaFile.setOriginalFileName(originalFileName);
        mediaFile.setFilePath(targetLocation.toString());
        mediaFile.setFileType(fileType.toUpperCase());
        mediaFile.setContentType(file.getContentType());
        mediaFile.setFileSize(file.getSize());

        return mediaFileRepository.save(mediaFile);
    }

    public Resource loadFileAsResource(Long fileId) throws MalformedURLException {
        MediaFile mediaFile = mediaFileRepository.findById(fileId)
                .orElseThrow(() -> new RuntimeException("File not found with id: " + fileId));

        Path filePath = Paths.get(mediaFile.getFilePath());
        Resource resource = new UrlResource(filePath.toUri());

        if (resource.exists() && resource.isReadable()) {
            return resource;
        } else {
            throw new RuntimeException("File not found or not readable: " + mediaFile.getFileName());
        }
    }

    public MediaFile getMediaFile(Long fileId) {
        return mediaFileRepository.findById(fileId)
                .orElseThrow(() -> new RuntimeException("File not found with id: " + fileId));
    }

    public List<MediaFileResponse> getAllMediaFiles(String baseUrl) {
        return mediaFileRepository.findAllByOrderByUploadedAtDesc()
                .stream()
                .map(file -> MediaFileResponse.fromEntity(file, baseUrl))
                .collect(Collectors.toList());
    }

    public List<MediaFileResponse> getMediaFilesByType(String fileType, String baseUrl) {
        return mediaFileRepository.findByFileTypeOrderByUploadedAtDesc(fileType.toUpperCase())
                .stream()
                .map(file -> MediaFileResponse.fromEntity(file, baseUrl))
                .collect(Collectors.toList());
    }

    public void deleteFile(Long fileId) throws IOException {
        MediaFile mediaFile = mediaFileRepository.findById(fileId)
                .orElseThrow(() -> new RuntimeException("File not found with id: " + fileId));

        Path filePath = Paths.get(mediaFile.getFilePath());
        Files.deleteIfExists(filePath);
        mediaFileRepository.delete(mediaFile);
    }

    private String getFileExtension(String fileName) {
        if (fileName == null || fileName.lastIndexOf(".") == -1) {
            return "";
        }
        return fileName.substring(fileName.lastIndexOf("."));
    }
}
