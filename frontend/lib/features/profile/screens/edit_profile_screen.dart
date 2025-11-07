import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/auth_provider.dart'; // Use your auth provider
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = ref
        .read(authServiceProvider)
        .currentUser; // Get initial user
    _nameController = TextEditingController(
      text: _currentUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- Save Logic ---
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Validation failed
    }
    if (_currentUser == null) return; // Should not happen if logged in

    setState(() => _isLoading = true);

    try {
      // Update Firebase Auth display name
      await _currentUser!.updateDisplayName(_nameController.text.trim());

      // Optional: Refresh the user object to get the latest data
      await _currentUser!.reload();
      _currentUser = FirebaseAuth.instance.currentUser; // Update local copy

      // --- Update Firestore User Document ---
      // If you also store the displayName in your Firestore 'users' collection,
      // you MUST update it there too via an API call to your backend.
      // Example:
      // final apiService = ref.read(apiServiceProvider);
      // await apiService.updateUserProfile({'displayName': _nameController.text.trim()});
      // ---------------------------------------------

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Optionally pop back or refresh state
        context.pop(); // Go back to the previous screen
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-watch the user state in case it changes (e.g., after update)
    final userAsync = ref.watch(authStateProvider);
    _currentUser = userAsync.asData?.value; // Keep local copy updated

    // Normalize photo URL
    String? photoUrl = _currentUser?.photoURL;
    if (photoUrl != null && photoUrl.contains('googleusercontent.com')) {
      final idx = photoUrl.indexOf('=');
      if (idx != -1) photoUrl = photoUrl.substring(0, idx);
    }
    final String initials =
        _currentUser?.displayName?.substring(0, 1) ??
        _currentUser?.email?.substring(0, 1) ??
        'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(), // Go back
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Center(
            // Center the content horizontally
            child: ConstrainedBox(
              // Limit the max width for web
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Profile Picture ---
                  _avatarWidget(url: photoUrl, initials: initials, radius: 50),
                  const SizedBox(height: 24),

                  // --- Email (Read Only) ---
                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Indicate non-editable
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _currentUser?.email ?? 'Loading...',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Name (Editable) ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Display Name',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Your display name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Display name cannot be empty';
                      }
                      if (value.length > 50) {
                        return 'Name too long (max 50 characters)';
                      }
                      return null; // Valid
                    },
                  ),
                  const SizedBox(height: 32),

                  // Optional: Add Save button here if not in AppBar
                  // ElevatedButton(onPressed: _isLoading ? null : _updateProfile, ...)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper for Input Decoration (reuse from create screen or define here) ---
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      errorStyle: const TextStyle(
        color: Colors.redAccent,
      ), // Customize error style
    );
  }

  // --- Avatar Widget (copy from home screen) ---
  Widget _avatarWidget({
    String? url,
    required String initials,
    required double radius,
  }) {
    if (url == null) {
      return CircleAvatar(
        radius: radius,
        child: Text(initials, style: TextStyle(fontSize: radius * 0.9)),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: radius * 2,
          height: radius * 2,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: SizedBox(
            width: radius,
            height: radius,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: radius * 2,
          height: radius * 2,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Text(initials, style: TextStyle(fontSize: radius * 0.9)),
        ),
      ),
    );
  }
}
