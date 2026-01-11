package com.mediaupload.repository;

import com.mediaupload.entity.MediaFile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MediaFileRepository extends JpaRepository<MediaFile, Long> {
    
    List<MediaFile> findByFileType(String fileType);
    
    List<MediaFile> findAllByOrderByUploadedAtDesc();
    
    List<MediaFile> findByFileTypeOrderByUploadedAtDesc(String fileType);
}
