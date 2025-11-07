import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/core/models/course.dart';
import 'package:frontend/core/models/lesson_content.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:logging/logging.dart';

class ApiService {
  final Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('ApiService');

  // --- Backend URL Configuration ---
  // Set the backend URL based on build mode and platform
  //
  // For PRODUCTION: Set environment variable API_BASE_URL
  // For LOCAL DEVELOPMENT:
  //   - Android emulator: Use 'http://10.0.2.2:8080/api/v1'
  //   - iOS simulator or Desktop: Use 'http://localhost:8080/api/v1'
  //
  // To set environment variable, add to your build command:
  // flutter build --dart-define=API_BASE_URL=https://your-api.com/api/v1
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    // This interceptor automatically adds the auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _logger.info(
            '🌐 API Request: ${options.method} ${options.baseUrl}${options.path}',
          );
          // Get the current user
          User? user = _auth.currentUser;
          if (user != null) {
            // Get the JWT (ID token)
            String? token = await user.getIdToken();
            // Add the token to the header
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              _logger.info('✅ Auth token added to request');
            } else {
              _logger.warning('⚠️ Warning: Token is null');
            }
          } else {
            _logger.warning('⚠️ Warning: No user logged in');
          }
          return handler.next(options); // Continue the request
        },
        onResponse: (response, handler) {
          _logger.info(
            '✅ API Response: ${response.statusCode} from ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Handle errors globally if needed
          _logger.severe('❌ Dio Error: ${e.type} - ${e.message}');
          if (e.response != null) {
            _logger.severe('   Status: ${e.response?.statusCode}');
            _logger.severe('   Data: ${e.response?.data}');
          }
          return handler.next(e); // Continue the error
        },
      ),
    );
  }

  // --- API Methods ---

  // GET: /api/v1/courses (Public, but our interceptor will add token anyway)
  Future<List<Course>> getAllCourses() async {
    try {
      final response = await _dio.get('/courses');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Course.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load courses');
      }
    } catch (e) {
      throw Exception('Failed to load courses: $e');
    }
  }

  // GET: /api/v1/student/my-courses (Secured)
  Future<List<Course>> getMyEnrolledCourses() async {
    try {
      final response = await _dio.get('/student/my-courses');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Course.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load enrolled courses');
      }
    } catch (e) {
      throw Exception('Failed to load enrolled courses: $e');
    }
  }

  // GET: /api/v1/instructor/my-courses (Secured)
  Future<List<Course>> getMyCreatedCourses() async {
    try {
      final response = await _dio.get('/instructor/my-courses');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Course.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load instructor courses');
      }
    } catch (e) {
      throw Exception('Failed to load instructor courses: $e');
    }
  }

  // GET: /api/v1/courses/{courseId} (Public)
  Future<Course> getCourseById(String courseId) async {
    try {
      final response = await _dio.get('/courses/$courseId');
      if (response.statusCode == 200) {
        return Course.fromJson(response.data);
      } else {
        throw Exception('Failed to load course details');
      }
    } catch (e) {
      throw Exception('Failed to load course details: $e');
    }
  }

  // POST: /api/v1/student/enroll/{courseId} (Secured)
  Future<void> enrollInCourse(String courseId) async {
    try {
      // We just care if it's successful (201) or an error (409)
      await _dio.post('/student/enroll/$courseId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // 409 Conflict - "Already enrolled"
        throw Exception('You are already enrolled in this course.');
      }
      throw Exception('Enrollment failed: ${e.message}');
    } catch (e) {
      throw Exception('Enrollment failed: $e');
    }
  }

  // GET: /api/v1/student/courses/{courseId}/modules/{moduleId}/lessons/{lessonId}/content (Secured)
  Future<LessonContent> getLessonContent(
    String courseId,
    String moduleId,
    String lessonId,
  ) async {
    try {
      final response = await _dio.get(
        '/student/courses/$courseId/modules/$moduleId/lessons/$lessonId/content',
      );
      if (response.statusCode == 200) {
        return LessonContent.fromJson(response.data);
      } else {
        throw Exception('Failed to load lesson content');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('You are not enrolled in this course.');
      }
      throw Exception('Failed to load lesson: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load lesson: $e');
    }
  }

  // --- INSTRUCTOR METHODS ---

  // POST: /api/v1/instructor/courses (Secured)
  Future<Course> createCourse(Map<String, dynamic> courseData) async {
    try {
      final response = await _dio.post('/instructor/courses', data: courseData);
      if (response.statusCode == 201) {
        // 201 Created
        return Course.fromJson(response.data);
      } else {
        throw Exception('Failed to create course');
      }
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  // POST: /api/v1/uploads/presign-url (Secured)
  Future<Map<String, dynamic>> getPresignedUploadUrl(
    String fileName,
    String contentType,
  ) async {
    try {
      final response = await _dio.post(
        '/uploads/presign-url',
        data: {'fileName': fileName, 'contentType': contentType},
      );
      if (response.statusCode == 200) {
        return response.data; // Returns { "url": "...", "objectKey": "..." }
      } else {
        throw Exception('Failed to get presigned URL');
      }
    } catch (e) {
      throw Exception('Failed to get presigned URL: $e');
    }
  }

  // Uploads a file to a pre-signed S3 URL
  Future<void> uploadFileToS3(
    String uploadUrl,
    Uint8List fileBytes,
    String contentType,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(uploadUrl),
        body: fileBytes,
        headers: {'Content-Type': contentType},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'File upload failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  // --- ADMIN METHODS ---

  // GET: /api/v1/admin/users (Secured - Admin only)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => AppUser.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  // PUT: /api/v1/admin/users/{uid}/roles (Secured - Admin only)
  Future<void> updateUserRoles(String uid, List<String> roles) async {
    try {
      await _dio.put('/admin/users/$uid/roles', data: roles);
    } on DioException catch (e) {
      throw Exception('Failed to update user roles: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update user roles: $e');
    }
  }

  // DELETE: /api/v1/admin/courses/{courseId} (Secured - Admin only)
  // Deletes a course and all its associated content (modules, lessons, S3 files)
  Future<void> deleteCourse(String courseId) async {
    try {
      final response = await _dio.delete('/admin/courses/$courseId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete course');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Course not found');
      }
      throw Exception('Failed to delete course: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  // DELETE: /api/v1/admin/courses/{courseId}/modules/{moduleId} (Secured - Admin only)
  // Deletes a module and all its lessons from a course
  Future<void> deleteModule(String courseId, String moduleId) async {
    try {
      final response = await _dio.delete(
        '/admin/courses/$courseId/modules/$moduleId',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete module');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Module not found');
      }
      throw Exception('Failed to delete module: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete module: $e');
    }
  }

  // DELETE: /api/v1/admin/courses/{courseId}/modules/{moduleId}/lessons/{lessonId} (Secured - Admin only)
  // Deletes a specific lesson from a module
  Future<void> deleteLesson(
    String courseId,
    String moduleId,
    String lessonId,
  ) async {
    try {
      final response = await _dio.delete(
        '/admin/courses/$courseId/modules/$moduleId/lessons/$lessonId',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete lesson');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Lesson not found');
      }
      throw Exception('Failed to delete lesson: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete lesson: $e');
    }
  }
}
