package com.courseverse.backend.repository;

import com.courseverse.backend.model.Enrollment;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Repository
public class EnrollmentRepository {

    private final CollectionReference enrollmentCollection;
    private static final String COLLECTION_NAME = "enrollments";

    public EnrollmentRepository(Firestore firestore) {
        this.enrollmentCollection = firestore.collection(COLLECTION_NAME);
    }

    public Enrollment save(Enrollment enrollment) throws ExecutionException, InterruptedException {
        DocumentReference docRef = enrollmentCollection.document(); // Auto-gen ID
        enrollment.setUid(docRef.getId());
        docRef.set(enrollment).get(); // .get() waits for completion
        return enrollment;
    }

    // Check if a user is already enrolled in a specific course
    public Optional<Enrollment> findByUserIdAndCourseId(String userId, String courseId)
            throws ExecutionException, InterruptedException {

        Query query = enrollmentCollection
                .whereEqualTo("userId", userId)
                .whereEqualTo("courseId", courseId)
                .limit(1);

        ApiFuture<QuerySnapshot> future = query.get();
        QuerySnapshot querySnapshot = future.get();

        if (!querySnapshot.isEmpty()) {
            return Optional.of(querySnapshot.getDocuments().get(0).toObject(Enrollment.class));
        }
        return Optional.empty();
    }

    // Get all enrollments for a specific user
    public List<Enrollment> findByUserId(String userId) throws ExecutionException, InterruptedException {
        Query query = enrollmentCollection.whereEqualTo("userId", userId);
        ApiFuture<QuerySnapshot> future = query.get();

        return future.get().getDocuments().stream()
                .map(doc -> doc.toObject(Enrollment.class))
                .collect(Collectors.toList());
    }
}
