package com.courseverse.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LessonContentResponse {
    private String videoUrl; // The pre-signed S3 URL
    private String textContent; // The text content of the lesson
}
