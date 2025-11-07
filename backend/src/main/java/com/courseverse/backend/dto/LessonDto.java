package com.courseverse.backend.dto;

import lombok.Data;

@Data
public class LessonDto {
    private String title;
    private String textContent;
    // The objectKey from the S3 upload (e.g., "lessons/uuid/video.mp4")
    private String videoObjectKey;
}
