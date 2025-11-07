package com.courseverse.backend.service;

import com.courseverse.backend.dto.SignedUrlResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;
import java.util.UUID;

@Service
public class S3Service {

    private final S3Presigner s3Presigner;
    private final S3Client s3Client;
    private final String bucketName;

    public S3Service(S3Presigner s3Presigner,
            S3Client s3Client,
            @Value("${app.aws.s3.bucket-name}") String bucketName) {
        this.s3Presigner = s3Presigner;
        this.s3Client = s3Client;
        this.bucketName = bucketName;
    }

    public SignedUrlResponse generatePresignedUploadUrl(String originalFileName) {
        // Create a unique object key (path) to prevent overwrites
        // e.g., "lessons/123e4567-e89b-12d3-a456-426614174000/my-video.mp4"
        String uniqueId = UUID.randomUUID().toString();
        String objectKey = "lessons/" + uniqueId + "/" + originalFileName;

        // 1. Create the PutObjectRequest
        PutObjectRequest objectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                // You could also set contentType here if passed from client
                // .contentType("video/mp4")
                .build();

        // 2. Create the PresignRequest
        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(15)) // URL valid for 15 mins
                .putObjectRequest(objectRequest)
                .build();

        // 3. Generate the pre-signed URL
        PresignedPutObjectRequest presignedPutObjectRequest = s3Presigner.presignPutObject(presignRequest);
        String url = presignedPutObjectRequest.url().toString();

        return new SignedUrlResponse(url, objectKey);
    }

    public String generatePresignedReadUrl(String objectKey) {
        if (objectKey == null || objectKey.isBlank()) {
            return null; // No video for this lesson
        }

        try {
            // 1. Create the GetObjectRequest
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(objectKey)
                    .build();

            // 2. Create the PresignRequest
            GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofHours(1)) // URL valid for 1 hour
                    .getObjectRequest(getObjectRequest)
                    .build();

            // 3. Generate the pre-signed URL
            PresignedGetObjectRequest presignedGetObjectRequest = s3Presigner.presignGetObject(presignRequest);
            return presignedGetObjectRequest.url().toString();

        } catch (Exception e) {
            // Log the error
            System.err.println("Error generating read URL for key " + objectKey + ": " + e.getMessage());
            return null;
        }
    }

    public void deleteObject(String objectKey) {
        if (objectKey == null || objectKey.isBlank()) {
            return; // Nothing to delete
        }

        try {
            DeleteObjectRequest deleteRequest = DeleteObjectRequest.builder()
                    .bucket(bucketName)
                    .key(objectKey)
                    .build();

            s3Client.deleteObject(deleteRequest);
            System.out.println("Successfully deleted object: " + objectKey);
        } catch (Exception e) {
            System.err.println("Error deleting object " + objectKey + " from S3: " + e.getMessage());
            // We don't throw here - log but continue, as deletion failures shouldn't block
            // course deletion
        }
    }
}
