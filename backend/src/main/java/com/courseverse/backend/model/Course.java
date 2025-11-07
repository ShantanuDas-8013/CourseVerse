package com.courseverse.backend.model;

import com.google.cloud.firestore.annotation.DocumentId;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
public class Course {
    @DocumentId
    private String uid; // Will be the Firestore Document ID

    private String title;
    private String description;
    private String instructorId; // UID of the instructor
    private String instructorName; // Denormalized for easy display
    private List<Module> modules;
    private String thumbnailUrl; // URL for the course thumbnail image
    private String thumbnailObjectKey; // S3 object key for the thumbnail
    private int enrollmentCount = 0; // Number of students enrolled
    private String publishStatus = "Draft"; // "Published" or "Draft"
}
