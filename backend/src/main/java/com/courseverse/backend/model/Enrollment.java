package com.courseverse.backend.model;

import com.google.cloud.firestore.annotation.DocumentId;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Enrollment {
    @DocumentId
    private String uid; // The auto-generated document ID

    private String userId; // UID of the student
    private String courseId; // UID of the course
    private Date enrolledAt;
    private double progress; // e.g., 0.0 to 1.0
}
