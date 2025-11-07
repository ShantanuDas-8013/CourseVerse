package com.courseverse.backend.model;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
public class Module {
    private String moduleId;
    private String title;
    private List<Lesson> lessons;
}
