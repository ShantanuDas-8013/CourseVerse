package com.courseverse.backend.dto;

import lombok.Data;

@Data
public class SignedUrlRequest {
    private String fileName;
    // We can add contentType later if needed
}
