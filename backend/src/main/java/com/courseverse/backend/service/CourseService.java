package com.courseverse.backend.service;

import com.courseverse.backend.dto.CourseCreationRequest;
import com.courseverse.backend.dto.LessonContentResponse;
import com.courseverse.backend.dto.LessonDto;
import com.courseverse.backend.dto.ModuleDto;
import com.courseverse.backend.exception.AccessDeniedException;
import com.courseverse.backend.exception.ResourceNotFoundException;
import com.courseverse.backend.model.Course;
import com.courseverse.backend.model.Lesson;
import com.courseverse.backend.model.Module;
import com.courseverse.backend.model.User;
import com.courseverse.backend.repository.CourseRepository;
import com.courseverse.backend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.security.Principal;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class CourseService {

    private final CourseRepository courseRepository;
    private final UserRepository userRepository;
    private final S3Service s3Service;
    private final EnrollmentService enrollmentService;

    public CourseService(CourseRepository courseRepository, UserRepository userRepository,
            S3Service s3Service, EnrollmentService enrollmentService) {
        this.courseRepository = courseRepository;
        this.userRepository = userRepository;
        this.s3Service = s3Service;
        this.enrollmentService = enrollmentService;
    }

    public List<Course> getAllCourses() {
        try {
            List<Course> courses = courseRepository.findAll();
            // Regenerate presigned URLs for thumbnails since they expire
            courses.forEach(course -> {
                // Handle both new courses (with thumbnailObjectKey) and legacy courses (URL
                // only)
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
                        course.setThumbnailObjectKey(objectKey); // Save for next time
                    }
                }
            });
            return courses;
        } catch (ExecutionException | InterruptedException e) {
            // Handle exception properly, maybe log it
            throw new RuntimeException("Error fetching courses", e);
        }
    }

    public Course getCourseById(String courseId) {
        try {
            Course course = courseRepository.findById(courseId)
                    .orElseThrow(() -> new ResourceNotFoundException("Course not found with id: " + courseId));

            // Regenerate presigned URL for thumbnail if it exists
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

            return course;
        } catch (ExecutionException | InterruptedException e) {
            throw new RuntimeException("Error fetching course: " + courseId, e);
        }
    }

    public Course createCourse(CourseCreationRequest request, Principal principal) {
        try {
            // 1. Get instructor details
            String instructorUid = principal.getName();
            User instructor = userRepository.findById(instructorUid)
                    .orElseThrow(() -> new ResourceNotFoundException("Instructor not found"));

            // 2. Map DTOs to Models
            Course course = new Course();
            course.setTitle(request.getTitle());
            course.setDescription(request.getDescription());
            course.setInstructorId(instructorUid);
            course.setInstructorName(instructor.getDisplayName()); // Denormalize name

            // Handle thumbnail if provided
            if (request.getThumbnailObjectKey() != null && !request.getThumbnailObjectKey().isBlank()) {
                // Store the S3 object key
                course.setThumbnailObjectKey(request.getThumbnailObjectKey());
                // Generate a read URL for the thumbnail and store it
                String thumbnailUrl = s3Service.generatePresignedReadUrl(request.getThumbnailObjectKey());
                course.setThumbnailUrl(thumbnailUrl);
            }

            List<Module> modules = request.getModules().stream()
                    .map(this::mapModuleDtoToModel)
                    .collect(Collectors.toList());
            course.setModules(modules);

            // 3. Save to repository
            return courseRepository.save(course);

        } catch (ExecutionException | InterruptedException e) {
            throw new RuntimeException("Error creating course", e);
        }
    }

    private Module mapModuleDtoToModel(ModuleDto moduleDto) {
        Module module = new Module();
        module.setModuleId(UUID.randomUUID().toString()); // Generate unique ID
        module.setTitle(moduleDto.getTitle());

        List<Lesson> lessons = moduleDto.getLessons().stream()
                .map(this::mapLessonDtoToModel)
                .collect(Collectors.toList());
        module.setLessons(lessons);
        return module;
    }

    private Lesson mapLessonDtoToModel(LessonDto lessonDto) {
        Lesson lesson = new Lesson();
        lesson.setLessonId(UUID.randomUUID().toString()); // Generate unique ID
        lesson.setTitle(lessonDto.getTitle());
        lesson.setTextContent(lessonDto.getTextContent());

        // Here, we just save the S3 key. We'll generate a signed *view* URL later.
        lesson.setVideoUrl(lessonDto.getVideoObjectKey()); // Storing the S3 key

        return lesson;
    }

    public LessonContentResponse getLessonContent(String courseId, String moduleId, String lessonId,
            Principal principal) {
        String userId = principal.getName();

        // 1. Check if student is enrolled
        if (!enrollmentService.isStudentEnrolled(userId, courseId)) {
            throw new AccessDeniedException("You are not enrolled in this course.");
        }

        // 2. Get the course
        Course course = this.getCourseById(courseId); // Re-use existing method

        // 3. Find the specific lesson
        Lesson lesson = course.getModules().stream()
                .filter(module -> module.getModuleId().equals(moduleId))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Module not found"))
                .getLessons().stream()
                .filter(l -> l.getLessonId().equals(lessonId))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Lesson not found"));

        // 4. Generate the pre-signed URL for the video
        String videoUrl = s3Service.generatePresignedReadUrl(lesson.getVideoUrl());

        // 5. Return the URL and the text content
        return new LessonContentResponse(videoUrl, lesson.getTextContent());
    }

    public List<Course> getCoursesByInstructor(Principal principal) {
        try {
            String instructorUid = principal.getName();
            List<Course> courses = courseRepository.findByInstructorId(instructorUid);

            // Regenerate presigned URLs for thumbnails since they expire
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
            throw new RuntimeException("Error fetching instructor courses", e);
        }
    }

    /**
     * Helper method to extract S3 object key from a presigned URL
     * Example URL:
     * https://bucket.s3.region.amazonaws.com/path/to/file.png?X-Amz-Algorithm=...
     * Returns: path/to/file.png
     */
    private String extractS3KeyFromUrl(String url) {
        try {
            if (url == null || url.isBlank()) {
                return null;
            }
            // Find the start of the object key (after the bucket name)
            // URL format: https://bucket.s3.region.amazonaws.com/OBJECT_KEY?query-params
            int bucketEndIndex = url.indexOf(".amazonaws.com/");
            if (bucketEndIndex == -1) {
                return null;
            }
            int keyStartIndex = bucketEndIndex + ".amazonaws.com/".length();

            // Find the end of the object key (before query parameters)
            int queryStartIndex = url.indexOf("?", keyStartIndex);
            if (queryStartIndex == -1) {
                // No query parameters, key goes to end of URL
                return url.substring(keyStartIndex);
            }
            return url.substring(keyStartIndex, queryStartIndex);
        } catch (Exception e) {
            System.err.println("Error extracting S3 key from URL: " + url);
            return null;
        }
    }
}
