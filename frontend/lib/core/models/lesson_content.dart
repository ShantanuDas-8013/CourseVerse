class LessonContent {
  final String? videoUrl; // The pre-signed S3 URL (nullable)
  final String? textContent; // The text content (nullable)

  LessonContent({this.videoUrl, this.textContent});

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      videoUrl: json['videoUrl'],
      textContent: json['textContent'],
    );
  }
}
