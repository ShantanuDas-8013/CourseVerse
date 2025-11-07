package com.courseverse.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class ModuleDto {
    private String title;
    private List<LessonDto> lessons;
}
