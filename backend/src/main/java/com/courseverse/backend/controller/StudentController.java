package com.courseverse.backend.controller;

import com.courseverse.backend.dto.LessonContentResponse;
import com.courseverse.backend.exception.AccessDeniedException;
import com.courseverse.backend.model.Course;
import com.courseverse.backend.model.Enrollment;
import com.courseverse.backend.service.CourseService;
import com.courseverse.backend.service.EnrollmentService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/student")
public class StudentController {

    private final EnrollmentService enrollmentService;
    private final CourseService courseService;

    public StudentController(EnrollmentService enrollmentService, CourseService courseService) {
        this.enrollmentService = enrollmentService;
        this.courseService = courseService;
    }

    @PostMapping("/enroll/{courseId}")
    @PreAuthorize("hasAuthority('ROLE_STUDENT')")
    public ResponseEntity<Enrollment> enrollInCourse(
            @PathVariable String courseId, Principal principal) {

        Enrollment enrollment = enrollmentService.enrollStudent(courseId, principal);
        return new ResponseEntity<>(enrollment, HttpStatus.CREATED);
    }

    @GetMapping("/my-courses")
    @PreAuthorize("hasAuthority('ROLE_STUDENT')")
    public ResponseEntity<List<Course>> getMyCourses(Principal principal) {
        List<Course> courses = enrollmentService.getMyEnrolledCourses(principal);
        return ResponseEntity.ok(courses);
    }

    @GetMapping("/courses/{courseId}/modules/{moduleId}/lessons/{lessonId}/content")
    @PreAuthorize("hasAuthority('ROLE_STUDENT')")
    public ResponseEntity<LessonContentResponse> getLessonContent(
            @PathVariable String courseId,
            @PathVariable String moduleId,
            @PathVariable String lessonId,
            Principal principal) {

        LessonContentResponse content = courseService.getLessonContent(courseId, moduleId, lessonId, principal);
        return ResponseEntity.ok(content);
    }

    // --- Add a custom exception handler for the "already enrolled" case ---
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, String>> handleIllegalState(IllegalStateException ex) {
        return new ResponseEntity<>(Map.of("error", ex.getMessage()), HttpStatus.CONFLICT); // 409 Conflict
    }

    // --- Add custom exception handler for access denied ---
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, String>> handleAccessDenied(AccessDeniedException ex) {
        // This will catch the "You are not enrolled..." exception
        // and return a 403 with our custom JSON message.
        return new ResponseEntity<>(Map.of("error", ex.getMessage()), HttpStatus.FORBIDDEN);
    }
}
