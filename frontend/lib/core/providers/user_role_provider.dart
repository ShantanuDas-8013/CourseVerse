import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/auth_provider.dart';

// This provider gives us the current user's roles
final userRolesProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return []; // No user, no roles
  }

  // Get the token. forceRefresh = true ensures we get roles if they just signed up.
  final token = await user.getIdToken(true);
  if (token == null) {
    return [];
  }

  // --- IMPORTANT ---
  // For your Spring Boot setup, the token *doesn't* contain roles.
  // We'll need a new backend endpoint to get the user's profile.
  // For now, let's assign roles based on email addresses.

  // Check for admin users
  if (user.email == 'shantanucool1361@gmail.com') {
    // Admin with instructor privileges
    return ['ROLE_ADMIN'];
  }

  // Check for instructor users
  if (user.email == 'test@example.com') {
    return ['ROLE_INSTRUCTOR', 'ROLE_STUDENT'];
  }

  // Default to student role
  return ['ROLE_STUDENT'];
});

// A simple provider that just checks if the user is an instructor
final isInstructorProvider = Provider<bool>((ref) {
  final roles = ref.watch(userRolesProvider).value;
  return roles?.contains('ROLE_INSTRUCTOR') ?? false;
});

// A simple provider that checks if the user is an admin
final isAdminProvider = Provider<bool>((ref) {
  final roles = ref.watch(userRolesProvider).value;
  return roles?.contains('ROLE_ADMIN') ?? false;
});
