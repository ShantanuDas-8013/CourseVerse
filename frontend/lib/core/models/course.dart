// We can define all related models in one file for simplicity
class Course {
  final String uid;
  final String title;
  final String description;
  final String instructorName;
  final List<Module> modules;
  final String? thumbnailUrl; // URL for the course thumbnail image
  final String? instructorImageUrl; // URL for the instructor's profile picture
  final int enrollmentCount; // Number of students enrolled
  final String publishStatus; // "Published" or "Draft"

  Course({
    required this.uid,
    required this.title,
    required this.description,
    required this.instructorName,
    required this.modules,
    this.thumbnailUrl,
    this.instructorImageUrl,
    this.enrollmentCount = 0,
    this.publishStatus = 'Draft',
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    var modulesList = json['modules'] as List? ?? [];
    List<Module> modules = modulesList.map((i) => Module.fromJson(i)).toList();

    return Course(
      uid: json['uid'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructorName: json['instructorName'] ?? '',
      modules: modules,
      thumbnailUrl: json['thumbnailUrl'],
      instructorImageUrl: json['instructorImageUrl'],
      enrollmentCount: json['enrollmentCount'] ?? 0,
      publishStatus: json['publishStatus'] ?? 'Draft',
    );
  }

  /// Calculate total duration of all video lessons in seconds
  int getTotalDurationInSeconds() {
    int totalSeconds = 0;
    for (var module in modules) {
      for (var lesson in module.lessons) {
        if (lesson.durationInSeconds != null) {
          totalSeconds += lesson.durationInSeconds!;
        }
      }
    }
    return totalSeconds;
  }

  /// Get formatted total duration string (e.g., "2h 30m", "45m", "1h 5m")
  String getFormattedTotalDuration() {
    final totalSeconds = getTotalDurationInSeconds();
    if (totalSeconds == 0) return '0m';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
}

class Module {
  final String moduleId;
  final String title;
  final List<Lesson> lessons;

  Module({required this.moduleId, required this.title, required this.lessons});

  factory Module.fromJson(Map<String, dynamic> json) {
    var lessonsList = json['lessons'] as List? ?? [];
    List<Lesson> lessons = lessonsList.map((i) => Lesson.fromJson(i)).toList();

    return Module(
      moduleId: json['moduleId'] ?? '',
      title: json['title'] ?? '',
      lessons: lessons,
    );
  }
}

class Lesson {
  final String lessonId;
  final String title;
  final String? textContent;
  final String? videoUrl; // This will be the S3 object key
  final int? durationInSeconds; // Duration of the video in seconds

  Lesson({
    required this.lessonId,
    required this.title,
    this.textContent,
    this.videoUrl,
    this.durationInSeconds,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      lessonId: json['lessonId'] ?? '',
      title: json['title'] ?? '',
      textContent: json['textContent'],
      videoUrl: json['videoUrl'], // It's ok if this is null
      durationInSeconds: json['durationInSeconds'] as int?,
    );
  }

  /// Get formatted duration string for a single lesson (e.g., "5m", "1h 5m", "45s")
  String getFormattedDuration() {
    if (durationInSeconds == null || durationInSeconds == 0) return 'N/A';

    final seconds = durationInSeconds!;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${remainingSeconds}s';
    }
  }
}
