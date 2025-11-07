package com.courseverse.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class CourseCreationRequest {
    private String title;
    private String description;
    private List<ModuleDto> modules;
    private String thumbnailObjectKey; // S3 key for the thumbnail image
}
