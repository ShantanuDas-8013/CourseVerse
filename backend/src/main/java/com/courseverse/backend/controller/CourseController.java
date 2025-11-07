package com.courseverse.backend.controller;

import com.courseverse.backend.model.Course;
import com.courseverse.backend.service.CourseService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/courses") // --- UPDATED BASE PATH ---
public class CourseController {

    private final CourseService courseService;

    public CourseController(CourseService courseService) {
        this.courseService = courseService;
    }

    // --- NEW PUBLIC ENDPOINT ---
    @GetMapping
    public ResponseEntity<List<Course>> getAllCourses() {
        return ResponseEntity.ok(courseService.getAllCourses());
    }

    // --- NEW PUBLIC ENDPOINT ---
    @GetMapping("/{courseId}")
    public ResponseEntity<Course> getCourseById(@PathVariable String courseId) {
        return ResponseEntity.ok(courseService.getCourseById(courseId));
    }

    // --- We can keep these test endpoints for now, but move them ---
    // --- Note their new paths: /api/v1/courses/health ---

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> healthCheck() {
        return ResponseEntity.ok(Map.of("status", "Backend is running"));
    }

    @GetMapping("/secure-test")
    public ResponseEntity<Map<String, String>> securedEndpoint(Principal principal) {
        return ResponseEntity.ok(Map.of(
                "message", "Hello, authenticated user!",
                "your-uid", principal.getName()));
    }

    @GetMapping("/instructor-only")
    @PreAuthorize("hasAuthority('ROLE_INSTRUCTOR')")
    public ResponseEntity<Map<String, String>> instructorEndpoint(Principal principal) {
        return ResponseEntity.ok(Map.of(
                "message", "Welcome, Instructor!",
                "your-uid", principal.getName()));
    }
}
