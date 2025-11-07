package com.courseverse.backend.service;

import com.courseverse.backend.exception.ResourceNotFoundException;
import com.courseverse.backend.model.Course;
import com.courseverse.backend.model.Lesson;
import com.courseverse.backend.model.Module;
import com.courseverse.backend.model.User;
import com.courseverse.backend.repository.CourseRepository;
import com.courseverse.backend.repository.UserRepository;
import com.courseverse.backend.security.SecurityRoles;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.ExecutionException;

@Service
public class AdminService {

    private final UserRepository userRepository;
    private final CourseRepository courseRepository;
    private final S3Service s3Service;

    public AdminService(UserRepository userRepository, CourseRepository courseRepository, S3Service s3Service) {
        this.userRepository = userRepository;
        this.courseRepository = courseRepository;
        this.s3Service = s3Service;
    }

    public List<User> getAllUsers() throws ExecutionException, InterruptedException {
        return userRepository.findAll();
    }

    public void updateUserRoles(String uid, List<String> roles) throws ExecutionException, InterruptedException {
        // Validate that all roles are valid enum values
        for (String role : roles) {
            try {
                SecurityRoles.valueOf(role);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Invalid role: " + role);
            }
        }

        userRepository.updateRoles(uid, roles);
    }

    public void deleteCourse(String courseId) throws ExecutionException, InterruptedException {
        // Fetch the course to get S3 object keys for cleanup
        Optional<Course> courseOptional = courseRepository.findById(courseId);
        if (courseOptional.isEmpty()) {
            throw new ResourceNotFoundException("Course not found with id: " + courseId);
        }

        Course course = courseOptional.get();

        // Delete all S3 objects associated with this course
        // 1. Delete course thumbnail if it exists
        if (course.getThumbnailObjectKey() != null && !course.getThumbnailObjectKey().isBlank()) {
            s3Service.deleteObject(course.getThumbnailObjectKey());
        }

        // 2. Delete all lesson videos
        if (course.getModules() != null) {
            for (Module module : course.getModules()) {
                if (module.getLessons() != null) {
                    for (Lesson lesson : module.getLessons()) {
                        // Extract object key from videoUrl or use a stored objectKey
                        // For now, we'll assume videoUrl contains the S3 path
                        if (lesson.getVideoUrl() != null && !lesson.getVideoUrl().isBlank()) {
                            try {
                                // Extract the object key from the S3 URL
                                String objectKey = extractObjectKeyFromUrl(lesson.getVideoUrl());
                                if (objectKey != null) {
                                    s3Service.deleteObject(objectKey);
                                }
                            } catch (Exception e) {
                                System.err.println("Error extracting object key from video URL: " + e.getMessage());
                                // Continue with other deletions
                            }
                        }
                    }
                }
            }
        }

        // 3. Delete the course document from Firestore
        courseRepository.deleteById(courseId);
    }

    public void deleteModule(String courseId, String moduleId) throws ExecutionException, InterruptedException {
        // Fetch the course first to validate it exists
        Optional<Course> courseOptional = courseRepository.findById(courseId);
        if (courseOptional.isEmpty()) {
            throw new ResourceNotFoundException("Course not found with id: " + courseId);
        }

        Course course = courseOptional.get();
        if (course.getModules() == null) {
            throw new ResourceNotFoundException("Module not found");
        }

        // Find the module and delete its S3 objects
        Optional<Module> moduleOptional = course.getModules().stream()
                .filter(m -> m.getModuleId().equals(moduleId))
                .findFirst();

        if (moduleOptional.isEmpty()) {
            throw new ResourceNotFoundException("Module not found with id: " + moduleId);
        }

        Module module = moduleOptional.get();

        // Delete all lesson videos in this module
        if (module.getLessons() != null) {
            for (Lesson lesson : module.getLessons()) {
                if (lesson.getVideoUrl() != null && !lesson.getVideoUrl().isBlank()) {
                    try {
                        String objectKey = extractObjectKeyFromUrl(lesson.getVideoUrl());
                        if (objectKey != null) {
                            s3Service.deleteObject(objectKey);
                        }
                    } catch (Exception e) {
                        System.err.println("Error extracting object key from video URL: " + e.getMessage());
                    }
                }
            }
        }

        // Delete the module from Firestore
        courseRepository.deleteModule(courseId, moduleId);
    }

    public void deleteLesson(String courseId, String moduleId, String lessonId)
            throws ExecutionException, InterruptedException {
        // Fetch the course first to validate it exists
        Optional<Course> courseOptional = courseRepository.findById(courseId);
        if (courseOptional.isEmpty()) {
            throw new ResourceNotFoundException("Course not found with id: " + courseId);
        }

        Course course = courseOptional.get();
        if (course.getModules() == null) {
            throw new ResourceNotFoundException("Module not found");
        }

        // Find the module
        Optional<Module> moduleOptional = course.getModules().stream()
                .filter(m -> m.getModuleId().equals(moduleId))
                .findFirst();

        if (moduleOptional.isEmpty()) {
            throw new ResourceNotFoundException("Module not found with id: " + moduleId);
        }

        Module module = moduleOptional.get();
        if (module.getLessons() == null) {
            throw new ResourceNotFoundException("Lesson not found");
        }

        // Find the lesson and delete its S3 video
        Optional<Lesson> lessonOptional = module.getLessons().stream()
                .filter(l -> l.getLessonId().equals(lessonId))
                .findFirst();

        if (lessonOptional.isEmpty()) {
            throw new ResourceNotFoundException("Lesson not found with id: " + lessonId);
        }

        Lesson lesson = lessonOptional.get();

        // Delete lesson video from S3
        if (lesson.getVideoUrl() != null && !lesson.getVideoUrl().isBlank()) {
            try {
                String objectKey = extractObjectKeyFromUrl(lesson.getVideoUrl());
                if (objectKey != null) {
                    s3Service.deleteObject(objectKey);
                }
            } catch (Exception e) {
                System.err.println("Error extracting object key from video URL: " + e.getMessage());
            }
        }

        // Delete the lesson from Firestore
        courseRepository.deleteLesson(courseId, moduleId, lessonId);
    }

    /**
     * Extract the S3 object key from a signed URL or direct S3 URL
     * This method handles various URL formats
     */
    private String extractObjectKeyFromUrl(String videoUrl) {
        if (videoUrl == null || videoUrl.isBlank()) {
            return null;
        }

        try {
            // Handle presigned URLs (contains query parameters)
            if (videoUrl.contains("?")) {
                videoUrl = videoUrl.substring(0, videoUrl.indexOf("?"));
            }

            // Extract the part after the bucket name
            // Format: https://bucket-name.s3.region.amazonaws.com/object-key
            // or: https://bucket-name.s3.amazonaws.com/object-key
            if (videoUrl.contains(".s3")) {
                int startIndex = videoUrl.indexOf(".s3");
                int slashIndex = videoUrl.indexOf("/", startIndex);
                if (slashIndex != -1 && slashIndex < videoUrl.length() - 1) {
                    return videoUrl.substring(slashIndex + 1);
                }
            }

            return null;
        } catch (Exception e) {
            System.err.println("Error extracting object key: " + e.getMessage());
            return null;
        }
    }
}
