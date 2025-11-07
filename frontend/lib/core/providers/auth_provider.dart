import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/auth_service.dart';

// 1. Provider for the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 2. StreamProvider to listen to the user's auth state
final authStateProvider = StreamProvider<User?>((ref) {
  // Watch the authService provider and get the authStateChanges stream
  return ref.watch(authServiceProvider).authStateChanges;
});
