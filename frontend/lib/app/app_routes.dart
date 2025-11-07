import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/student_dashboard/screens/home_screen.dart';
import 'package:frontend/features/student_dashboard/screens/course_detail_screen.dart';
import 'package:frontend/features/course_player/screens/course_player_screen.dart';
import 'package:frontend/features/instructor_portal/screens/instructor_dashboard.dart';
import 'package:frontend/features/instructor_portal/screens/course_create_screen.dart';
import 'package:frontend/features/profile/screens/edit_profile_screen.dart';
import 'package:frontend/features/splash/screens/splash_screen.dart';
import 'package:frontend/features/admin/screens/admin_dashboard_screen.dart';
import 'package:frontend/features/admin/screens/admin_course_manage_screen.dart';
import 'package:frontend/core/models/course.dart';
import 'package:frontend/core/providers/auth_provider.dart';

class AppRoutes {
  // Create a provider for the router
  static final routerProvider = Provider<GoRouter>((ref) {
    // Watch the auth state
    final authState = ref.watch(authStateProvider);

    return GoRouter(
      initialLocation: '/splash',

      // The redirect logic
      redirect: (context, state) {
        final bool loggedIn = authState.asData?.value != null;
        final bool loggingIn = state.matchedLocation == '/login';
        final bool onSplash = state.matchedLocation == '/splash';

        // Allow splash screen to load
        if (onSplash) {
          return null;
        }

        // If user is not logged in and not on login, redirect to login
        if (!loggedIn && !loggingIn) {
          return '/login';
        }

        // If user is logged in and on the login page, redirect to home
        if (loggedIn && loggingIn) {
          return '/home';
        }

        // No redirect needed
        return null;
      },

      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/course/:courseId', // Use : to denote a path parameter
          builder: (context, state) {
            // Extract the courseId from the path
            final courseId = state.pathParameters['courseId']!;
            return CourseDetailScreen(courseId: courseId);
          },
        ),
        GoRoute(
          path: '/player/:courseId/:moduleId/:lessonId',
          builder: (context, state) {
            // Get all IDs from the path
            final moduleId = state.pathParameters['moduleId']!;
            final lessonId = state.pathParameters['lessonId']!;

            // Get the full course object we passed as an 'extra'
            final course = state.extra as Course;

            return CoursePlayerScreen(
              course: course,
              initialModuleId: moduleId,
              initialLessonId: lessonId,
            );
          },
        ),
        // Instructor Portal routes
        GoRoute(
          path: '/instructor',
          builder: (context, state) => const InstructorDashboard(),
        ),
        GoRoute(
          path: '/instructor/create',
          builder: (context, state) => const CourseCreateScreen(),
        ),
        // --- ADD PROFILE ROUTE ---
        GoRoute(
          path: '/profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        // Admin Dashboard route
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        // Admin Course Management route
        GoRoute(
          path: '/admin/course/manage/:courseId',
          builder: (context, state) {
            final courseId = state.pathParameters['courseId']!;
            return AdminCourseManageScreen(courseId: courseId);
          },
        ),
      ],
    );
  });
}
