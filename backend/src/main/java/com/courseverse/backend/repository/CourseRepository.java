package com.courseverse.backend.repository;

import com.courseverse.backend.model.Course;
import com.courseverse.backend.model.Module;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Repository
public class CourseRepository {

    private final CollectionReference courseCollection;
    private static final String COLLECTION_NAME = "courses";

    public CourseRepository(Firestore firestore) {
        this.courseCollection = firestore.collection(COLLECTION_NAME);
    }

    public List<Course> findAll() throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> future = courseCollection.get();
        QuerySnapshot querySnapshot = future.get();

        return querySnapshot.getDocuments().stream()
                .map(doc -> doc.toObject(Course.class))
                .collect(Collectors.toList());
    }

    public Optional<Course> findById(String courseId) throws ExecutionException, InterruptedException {
        DocumentReference docRef = courseCollection.document(courseId);
        ApiFuture<DocumentSnapshot> future = docRef.get();
        DocumentSnapshot document = future.get();

        if (document.exists()) {
            return Optional.ofNullable(document.toObject(Course.class));
        } else {
            return Optional.empty();
        }
    }

    public Course save(Course course) throws ExecutionException, InterruptedException {
        // Let Firestore auto-generate the document ID
        DocumentReference docRef = courseCollection.document();

        // Set the auto-generated ID back onto the object
        course.setUid(docRef.getId());

        // Write the new course to Firestore
        docRef.set(course).get(); // .get() waits for the operation to complete

        return course;
    }

    public void update(Course course) throws ExecutionException, InterruptedException {
        // Update existing course document
        DocumentReference docRef = courseCollection.document(course.getUid());
        docRef.set(course).get(); // .get() waits for the operation to complete
    }

    public List<Course> findByInstructorId(String instructorId) throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> future = courseCollection.whereEqualTo("instructorId", instructorId).get();
        QuerySnapshot querySnapshot = future.get();

        return querySnapshot.getDocuments().stream()
                .map(doc -> doc.toObject(Course.class))
                .collect(Collectors.toList());
    }

    public void deleteById(String courseId) throws ExecutionException, InterruptedException {
        DocumentReference docRef = courseCollection.document(courseId);
        docRef.delete().get(); // .get() waits for the operation to complete
    }

    public void deleteModule(String courseId, String moduleId) throws ExecutionException, InterruptedException {
        DocumentReference docRef = courseCollection.document(courseId);
        ApiFuture<DocumentSnapshot> future = docRef.get();
        DocumentSnapshot document = future.get();

        if (document.exists()) {
            Course course = document.toObject(Course.class);
            if (course != null && course.getModules() != null) {
                // Remove the module with the matching ID
                course.setModules(course.getModules().stream()
                        .filter(module -> !module.getModuleId().equals(moduleId))
                        .collect(Collectors.toList()));
                docRef.set(course).get();
            }
        }
    }

    public void deleteLesson(String courseId, String moduleId, String lessonId)
            throws ExecutionException, InterruptedException {
        DocumentReference docRef = courseCollection.document(courseId);
        ApiFuture<DocumentSnapshot> future = docRef.get();
        DocumentSnapshot document = future.get();

        if (document.exists()) {
            Course course = document.toObject(Course.class);
            if (course != null && course.getModules() != null) {
                // Find the module and remove the lesson
                for (Module module : course.getModules()) {
                    if (module.getModuleId().equals(moduleId) && module.getLessons() != null) {
                        module.setLessons(module.getLessons().stream()
                                .filter(lesson -> !lesson.getLessonId().equals(lessonId))
                                .collect(Collectors.toList()));
                        break;
                    }
                }
                docRef.set(course).get();
            }
        }
    }
}
