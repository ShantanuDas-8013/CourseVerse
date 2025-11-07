import 'package:flutter/foundation.dart';

@immutable // Good practice for provider arguments
class LessonIds {
  final String courseId;
  final String moduleId;
  final String lessonId;

  const LessonIds({
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
  });

  // Override == and hashCode so Riverpod can cache correctly
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonIds &&
          runtimeType == other.runtimeType &&
          courseId == other.courseId &&
          moduleId == other.moduleId &&
          lessonId == other.lessonId;

  @override
  int get hashCode => courseId.hashCode ^ moduleId.hashCode ^ lessonId.hashCode;
}
