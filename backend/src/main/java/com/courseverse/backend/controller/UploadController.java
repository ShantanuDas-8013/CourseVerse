package com.courseverse.backend.controller;

import com.courseverse.backend.dto.SignedUrlRequest;
import com.courseverse.backend.dto.SignedUrlResponse;
import com.courseverse.backend.service.S3Service;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/uploads")
public class UploadController {

    private final S3Service s3Service;

    public UploadController(S3Service s3Service) {
        this.s3Service = s3Service;
    }

    @PostMapping("/presign-url")
    @PreAuthorize("hasAuthority('ROLE_INSTRUCTOR')")
    public ResponseEntity<SignedUrlResponse> getPresignedUrl(
            @RequestBody SignedUrlRequest request) {

        SignedUrlResponse response = s3Service.generatePresignedUploadUrl(request.getFileName());
        return ResponseEntity.ok(response);
    }
}
