package com.courseverse.backend.controller;

import com.courseverse.backend.dto.CourseCreationRequest;
import com.courseverse.backend.model.Course;
import com.courseverse.backend.service.CourseService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/v1/instructor")
public class InstructorController {

    private final CourseService courseService;

    public InstructorController(CourseService courseService) {
        this.courseService = courseService;
    }

    @PostMapping("/courses")
    @PreAuthorize("hasAuthority('ROLE_INSTRUCTOR')")
    public ResponseEntity<Course> createCourse(
            @RequestBody CourseCreationRequest request, Principal principal) {

        Course newCourse = courseService.createCourse(request, principal);

        // Return 201 Created status with the new course object
        return new ResponseEntity<>(newCourse, HttpStatus.CREATED);
    }

    @GetMapping("/my-courses")
    @PreAuthorize("hasAuthority('ROLE_INSTRUCTOR')")
    public ResponseEntity<List<Course>> getMyCourses(Principal principal) {
        List<Course> courses = courseService.getCoursesByInstructor(principal);
        return ResponseEntity.ok(courses);
    }
}
