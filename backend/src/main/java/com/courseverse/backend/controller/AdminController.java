package com.courseverse.backend.controller;

import com.courseverse.backend.model.User;
import com.courseverse.backend.service.AdminService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasAuthority('ROLE_ADMIN')") // Secure the whole controller
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> healthCheck() {
        return ResponseEntity.ok(Map.of("status", "Admin endpoint is running"));
    }

    @GetMapping("/users")
    public ResponseEntity<List<User>> getAllUsers() throws ExecutionException, InterruptedException {
        List<User> users = adminService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    @PutMapping("/users/{uid}/roles")
    public ResponseEntity<Map<String, String>> updateUserRoles(
            @PathVariable String uid,
            @RequestBody List<String> roles) throws ExecutionException, InterruptedException {
        adminService.updateUserRoles(uid, roles);
        return ResponseEntity.ok(Map.of("message", "User roles updated successfully"));
    }

    @DeleteMapping("/courses/{courseId}")
    public ResponseEntity<Map<String, String>> deleteCourse(
            @PathVariable String courseId) throws ExecutionException, InterruptedException {
        adminService.deleteCourse(courseId);
        return ResponseEntity.ok(Map.of("message", "Course deleted successfully"));
    }

    @DeleteMapping("/courses/{courseId}/modules/{moduleId}")
    public ResponseEntity<Map<String, String>> deleteModule(
            @PathVariable String courseId,
            @PathVariable String moduleId) throws ExecutionException, InterruptedException {
        adminService.deleteModule(courseId, moduleId);
        return ResponseEntity.ok(Map.of("message", "Module deleted successfully"));
    }

    @DeleteMapping("/courses/{courseId}/modules/{moduleId}/lessons/{lessonId}")
    public ResponseEntity<Map<String, String>> deleteLesson(
            @PathVariable String courseId,
            @PathVariable String moduleId,
            @PathVariable String lessonId) throws ExecutionException, InterruptedException {
        adminService.deleteLesson(courseId, moduleId, lessonId);
        return ResponseEntity.ok(Map.of("message", "Lesson deleted successfully"));
    }
}
