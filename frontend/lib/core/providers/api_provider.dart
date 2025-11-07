import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/models/course.dart';
import 'package:frontend/core/models/lesson_content.dart';
import 'package:frontend/core/models/lesson_ids.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/services/api_service.dart';

// 1. Provider for the ApiService instance
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// 2. A FutureProvider to fetch all courses
// This provider will be watched by our UI.
// It automatically handles loading/error states.
final allCoursesProvider = FutureProvider<List<Course>>((ref) {
  // Watch the apiServiceProvider and call the method
  return ref.watch(apiServiceProvider).getAllCourses();
});

// 2b. A FutureProvider.family to fetch one course by its ID
final courseDetailProvider = FutureProvider.family<Course, String>((
  ref,
  courseId,
) {
  return ref.watch(apiServiceProvider).getCourseById(courseId);
});

// 3. A FutureProvider to fetch just the user's enrolled courses
final myCoursesProvider = FutureProvider<List<Course>>((ref) {
  return ref.watch(apiServiceProvider).getMyEnrolledCourses();
});

// 3b. A FutureProvider to fetch instructor's created courses
final instructorCoursesProvider = FutureProvider<List<Course>>((ref) {
  return ref.watch(apiServiceProvider).getMyCreatedCourses();
});

// 4. A FutureProvider.family to fetch specific lesson content
final lessonContentProvider = FutureProvider.family<LessonContent, LessonIds>((
  ref,
  ids,
) {
  return ref
      .watch(apiServiceProvider)
      .getLessonContent(ids.courseId, ids.moduleId, ids.lessonId);
});

// 5. A FutureProvider to fetch all users (admin only)
final allUsersProvider = FutureProvider<List<AppUser>>((ref) {
  return ref.watch(apiServiceProvider).getAllUsers();
});

// 6. Deletion providers - These handle course/module/lesson deletion operations
// Using StateNotifierProvider to manage deletion state and provide actions

// Provider to invalidate course list after deletion
final courseListInvalidationProvider = StateProvider<int>((ref) {
  return 0; // Simple counter to trigger invalidation
});

// Family provider to delete a course by ID
final deleteCourseProvider = FutureProvider.family<void, String>((
  ref,
  courseId,
) async {
  await ref.watch(apiServiceProvider).deleteCourse(courseId);
  // After successful deletion, invalidate the courses provider
  ref.invalidate(allCoursesProvider);
});

// Family provider to delete a module
// The parameter is a Map with courseId and moduleId
final deleteModuleProvider = FutureProvider.family<void, Map<String, String>>((
  ref,
  params,
) async {
  final courseId = params['courseId']!;
  final moduleId = params['moduleId']!;
  await ref.watch(apiServiceProvider).deleteModule(courseId, moduleId);
  // After successful deletion, invalidate the course detail provider
  ref.invalidate(courseDetailProvider(courseId));
});

// Family provider to delete a lesson
// The parameter is a Map with courseId, moduleId, and lessonId
final deleteLessonProvider = FutureProvider.family<void, Map<String, String>>((
  ref,
  params,
) async {
  final courseId = params['courseId']!;
  final moduleId = params['moduleId']!;
  final lessonId = params['lessonId']!;
  await ref
      .watch(apiServiceProvider)
      .deleteLesson(courseId, moduleId, lessonId);
  // After successful deletion, invalidate the course detail provider
  ref.invalidate(courseDetailProvider(courseId));
});
