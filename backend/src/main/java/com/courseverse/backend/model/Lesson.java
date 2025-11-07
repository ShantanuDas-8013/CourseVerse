package com.courseverse.backend.model;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class Lesson {
    private String lessonId;
    private String title;
    private String videoUrl;
    private String textContent;
    // We can add order, duration, etc. later
}
