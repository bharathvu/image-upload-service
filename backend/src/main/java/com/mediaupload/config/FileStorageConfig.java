package com.mediaupload.config;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
public class FileStorageConfig {

    @Value("${file.upload-dir}")
    private String uploadDir;

    @PostConstruct
    public void init() {
        try {
            Path uploadPath = Paths.get(uploadDir);
            Path imagesPath = uploadPath.resolve("images");
            Path videosPath = uploadPath.resolve("videos");

            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }
            if (!Files.exists(imagesPath)) {
                Files.createDirectories(imagesPath);
            }
            if (!Files.exists(videosPath)) {
                Files.createDirectories(videosPath);
            }
        } catch (IOException e) {
            throw new RuntimeException("Could not create upload directories!", e);
        }
    }
}
