package com.courseverse.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class SignedUrlResponse {
    private String url; // The pre-signed URL
    private String objectKey; // The final path/key of the object in S3
}
