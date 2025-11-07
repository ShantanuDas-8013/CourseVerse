package com.courseverse.backend.model;

import com.google.cloud.firestore.annotation.DocumentId;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data // Adds getters, setters, toString, etc.
@NoArgsConstructor // Required for Firestore to deserialize
public class User {

    @DocumentId // Maps this field to the Firestore document ID
    private String uid;

    private String email;
    private String displayName;

    // This field is crucial for security
    private List<String> roles; // e.g., ["ROLE_STUDENT", "ROLE_INSTRUCTOR"]
}
