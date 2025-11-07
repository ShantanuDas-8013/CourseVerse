package com.courseverse.backend.service;

import com.courseverse.backend.exception.ResourceNotFoundException;
import com.courseverse.backend.model.Course;
import com.courseverse.backend.model.Enrollment;
import com.courseverse.backend.repository.CourseRepository;
import com.courseverse.backend.repository.EnrollmentRepository;
import org.springframework.stereotype.Service;

import java.security.Principal;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class EnrollmentService {

    private final EnrollmentRepository enrollmentRepository;
    private final CourseRepository courseRepository; // To get course details
    private final S3Service s3Service; // To regenerate presigned URLs

    public EnrollmentService(EnrollmentRepository enrollmentRepository, CourseRepository courseRepository,
            S3Service s3Service) {
        this.enrollmentRepository = enrollmentRepository;
        this.courseRepository = courseRepository;
        this.s3Service = s3Service;
    }

    public Enrollment enrollStudent(String courseId, Principal principal) {
        String userId = principal.getName();

        try {
            // 1. Check if course exists
            Course course = courseRepository.findById(courseId)
                    .orElseThrow(() -> new ResourceNotFoundException("Course not found with id: " + courseId));

            // 2. Check if already enrolled
            Optional<Enrollment> existingEnrollment = enrollmentRepository.findByUserIdAndCourseId(userId, courseId);
            if (existingEnrollment.isPresent()) {
                // You can throw an exception or just return the existing enrollment
                throw new IllegalStateException("Student is already enrolled in this course.");
            }

            // 3. Create new enrollment
            Enrollment newEnrollment = new Enrollment(null, userId, courseId, new Date(), 0.0);
            Enrollment savedEnrollment = enrollmentRepository.save(newEnrollment);

            // 4. Increment the course enrollment count
            course.setEnrollmentCount(course.getEnrollmentCount() + 1);
            courseRepository.update(course);

            return savedEnrollment;

        } catch (ExecutionException | InterruptedException e) {
            throw new RuntimeException("Error during enrollment", e);
        }
    }

    public List<Course> getMyEnrolledCourses(Principal principal) {
        String userId = principal.getName();
        try {
            // 1. Get all enrollment records for the user
            List<Enrollment> enrollments = enrollmentRepository.findByUserId(userId);

            // 2. Extract the course IDs
            List<String> courseIds = enrollments.stream()
                    .map(Enrollment::getCourseId)
                    .collect(Collectors.toList());

            if (courseIds.isEmpty()) {
                return List.of(); // Return empty list
            }

            // 3. Fetch all course details for those IDs
            // Note: This is simplified. For >10 IDs, Firestore 'IN' queries are limited.
            // A better approach for scale is to fetch one by one or denormalize data.
            // But for this project, we'll fetch all courses and filter in memory.
            List<Course> courses = courseRepository.findAll().stream()
                    .filter(course -> courseIds.contains(course.getUid()))
                    .collect(Collectors.toList());

            // 4. Regenerate presigned URLs for thumbnails since they expire
            courses.forEach(course -> {
                if (course.getThumbnailObjectKey() != null && !course.getThumbnailObjectKey().isBlank()) {
                    // New courses: regenerate from object key
                    String freshUrl = s3Service.generatePresignedReadUrl(course.getThumbnailObjectKey());
                    course.setThumbnailUrl(freshUrl);
                } else if (course.getThumbnailUrl() != null && !course.getThumbnailUrl().isBlank()) {
                    // Legacy courses: extract object key from existing URL and regenerate
                    String objectKey = extractS3KeyFromUrl(course.getThumbnailUrl());
                    if (objectKey != null) {
                        String freshUrl = s3Service.generatePresignedReadUrl(objectKey);
                        course.setThumbnailUrl(freshUrl);
                        course.setThumbnailObjectKey(objectKey);
                    }
                }
            });

            return courses;

        } catch (ExecutionException | InterruptedException e) {
            throw new RuntimeException("Error fetching enrolled courses", e);
        }
    }

    public boolean isStudentEnrolled(String userId, String courseId) {
        try {
            // Use the method we already built in Phase 8
            return enrollmentRepository.findByUserIdAndCourseId(userId, courseId).isPresent();
        } catch (ExecutionException | InterruptedException e) {
            // Log this, but for security, assume not enrolled if an error occurs
            System.err.println("Error checking enrollment: " + e.getMessage());
            return false;
        }
    }

    /**
     * Helper method to extract S3 object key from a presigned URL
     */
    private String extractS3KeyFromUrl(String url) {
        try {
            if (url == null || url.isBlank()) {
                return null;
            }
            int bucketEndIndex = url.indexOf(".amazonaws.com/");
            if (bucketEndIndex == -1) {
                return null;
            }
            int keyStartIndex = bucketEndIndex + ".amazonaws.com/".length();
            int queryStartIndex = url.indexOf("?", keyStartIndex);
            if (queryStartIndex == -1) {
                return url.substring(keyStartIndex);
            }
            return url.substring(keyStartIndex, queryStartIndex);
        } catch (Exception e) {
            System.err.println("Error extracting S3 key from URL: " + url);
            return null;
        }
    }
}
