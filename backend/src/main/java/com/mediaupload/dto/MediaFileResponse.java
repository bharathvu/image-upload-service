package com.mediaupload.dto;

import com.mediaupload.entity.MediaFile;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MediaFileResponse {
    
    private Long id;
    private String fileName;
    private String originalFileName;
    private String fileType;
    private String contentType;
    private Long fileSize;
    private LocalDateTime uploadedAt;
    private String downloadUrl;

    public static MediaFileResponse fromEntity(MediaFile mediaFile, String baseUrl) {
        MediaFileResponse response = new MediaFileResponse();
        response.setId(mediaFile.getId());
        response.setFileName(mediaFile.getFileName());
        response.setOriginalFileName(mediaFile.getOriginalFileName());
        response.setFileType(mediaFile.getFileType());
        response.setContentType(mediaFile.getContentType());
        response.setFileSize(mediaFile.getFileSize());
        response.setUploadedAt(mediaFile.getUploadedAt());
        response.setDownloadUrl(baseUrl + "/api/media/" + mediaFile.getId() + "/download");
        return response;
    }
}
