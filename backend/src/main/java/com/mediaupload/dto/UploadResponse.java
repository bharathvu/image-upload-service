package com.mediaupload.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UploadResponse {
    
    private boolean success;
    private String message;
    private MediaFileResponse mediaFile;

    public static UploadResponse success(String message, MediaFileResponse mediaFile) {
        return new UploadResponse(true, message, mediaFile);
    }

    public static UploadResponse error(String message) {
        return new UploadResponse(false, message, null);
    }
}
