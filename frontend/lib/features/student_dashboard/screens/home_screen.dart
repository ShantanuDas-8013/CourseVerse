import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/providers/api_provider.dart';
import 'package:frontend/core/providers/user_role_provider.dart';
import 'package:frontend/core/models/course.dart';

/// Redesigned HomeScreen for CourseVerse
/// - Desktop-first responsive layout
/// - Hero banner with search
/// - Categories strip
/// - Featured carousel
/// - Responsive course grid
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // (Grid helper removed — using simple list view now)

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final isInstructor = ref.watch(isInstructorProvider);
    final isAdmin = ref.watch(isAdminProvider);

    // --- get current Firebase user from the auth state provider
    final user = ref.watch(authStateProvider).asData?.value;

    // --- Get the list of courses for autocomplete ---
    final List<Course> courseList = coursesAsync.asData?.value ?? <Course>[];
    // -------------------------------------------------

    // Normalize Google profile photo URL by stripping any size/query params
    // so CachedNetworkImage requests the base image (better caching, avoids 429s).
    String? photoUrl = user?.photoURL;
    if (photoUrl != null && photoUrl.contains('googleusercontent.com')) {
      final idx = photoUrl.indexOf('=');
      if (idx != -1) photoUrl = photoUrl.substring(0, idx);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          'CourseVerse',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isInstructor)
            IconButton(
              icon: const Icon(Icons.school),
              tooltip: 'Instructor Portal',
              onPressed: () => context.go('/instructor'),
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Dashboard',
              onPressed: () => context.go('/admin'),
            ),
          PopupMenuButton<String>(
            // This is the button itself (the profile pic)
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _avatarWidget(
                url: photoUrl,
                initials:
                    user?.displayName?.substring(0, 1) ??
                    user?.email?.substring(0, 1) ??
                    'U',
                radius: 16,
              ),
            ),

            // This handles what happens when an item is clicked
            onSelected: (value) {
              if (value == 'sign_out') {
                ref.read(authServiceProvider).signOut();
              } else if (value == 'edit_profile') {
                // context.go('/profile');
                // Use debugPrint instead of print for hygiene
                // debugPrint('Navigate to Edit Profile screen');
                context.push('/profile'); // Navigate to Edit Profile
              }
            },

            // This builds the menu
            itemBuilder: (context) => [
              // 1. The custom header (not clickable)
              PopupMenuItem(enabled: false, child: _buildProfileHeader(user)),

              // 2. The divider
              const PopupMenuDivider(),

              // 3. Edit Profile button
              PopupMenuItem(
                value: 'edit_profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.grey[700]),
                  title: const Text('Edit Profile'),
                ),
              ),

              // 4. Sign Out button
              PopupMenuItem(
                value: 'sign_out',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.grey[700]),
                  title: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(context, courseList)),
          // (Categories strip and Featured carousel removed per request)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Courses',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Simple list of courses (plain, cardless items)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final list = coursesAsync.asData?.value ?? <Course>[];
                // Show all courses without filtering
                if (index >= list.length) return null;
                final course = list[index];
                // Card-style course row
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 4.0,
                  ),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: () {
                        // Route based on user role
                        final isAdminUser = ref.read(isAdminProvider);
                        if (isAdminUser) {
                          context.go('/admin/course/manage/${course.uid}');
                        } else {
                          context.go('/course/${course.uid}');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder: (context, bc) {
                            final isWideItem = bc.maxWidth > 600;
                            final lessonCount = course.modules.fold<int>(
                              0,
                              (p, m) => p + m.lessons.length,
                            );
                            if (isWideItem) {
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    height: 96,
                                    child: _courseThumbnailWidget(
                                      course.thumbnailUrl,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          course.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              child: Text(
                                                course.instructorName.isNotEmpty
                                                    ? course.instructorName[0]
                                                    : '?',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              course.instructorName,
                                              style: const TextStyle(
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '$lessonCount lessons',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 160,
                                  width: double.infinity,
                                  child: _courseThumbnailWidget(
                                    course.thumbnailUrl,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  course.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  course.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      child: Text(
                                        course.instructorName.isNotEmpty
                                            ? course.instructorName[0]
                                            : '?',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        course.instructorName,
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$lessonCount lessons',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: (coursesAsync.asData?.value ?? <Course>[]).length),
            ),
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, List<Course> allCourses) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3740FF), Color(0xFF00C2A8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to CourseVerse',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover premium courses taught by industry experts.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Search field fills the available width now that the
                          // "Explore Popular" button has been removed.
                          Expanded(child: _buildAutocomplete(allCourses)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 420,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=800&q=60',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Text(
                  'Welcome to CourseVerse',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAutocomplete(allCourses),
              ],
            ),
    );
  }

  // Categories removed — simplified UI

  // Featured carousel removed — simplified UI

  // Profile header shown at top of the popup menu
  Widget _buildProfileHeader(User? user) {
    // Get user's initial as a fallback
    final String initials =
        user?.displayName?.substring(0, 1) ??
        user?.email?.substring(0, 1) ??
        'U';

    // Normalize Google profile photo URL (strip size/query params) so
    // CachedNetworkImage can reuse a single cached resource and avoid 429s.
    String? photoUrl = user?.photoURL;
    if (photoUrl != null && photoUrl.contains('googleusercontent.com')) {
      final idx = photoUrl.indexOf('=');
      if (idx != -1) photoUrl = photoUrl.substring(0, idx);
    }

    return Row(
      children: [
        _avatarWidget(url: photoUrl, initials: initials, radius: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.displayName ?? 'Your Name',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            Text(
              user?.email ?? 'your.email@example.com',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the Autocomplete search field
  Widget _buildAutocomplete(List<Course> allCourses) {
    return Autocomplete<Course>(
      // Tell the widget how to get the text string from a Course object
      displayStringForOption: (course) => course.title,

      // This builds the list of suggestions
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) {
          // No query? No suggestions.
          return const Iterable<Course>.empty();
        }
        // Filter the full course list based on the title
        return allCourses.where((course) {
          return course.title.toLowerCase().contains(query);
        });
      },

      // This runs when a user CLICKS a suggestion
      onSelected: (course) {
        FocusManager.instance.primaryFocus?.unfocus(); // Hide the keyboard
        context.go('/course/${course.uid}'); // Navigate to the course
      },

      // This builds the dropdown menu UI
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          // Use a Material widget to get the proper shadow
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              // Limit the height of the dropdown
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final course = options.elementAt(index);
                  return ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(course.title),
                    onTap: () {
                      onSelected(course);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },

      // This builds the search bar text field itself
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Use the autocomplete's own controller and focusNode
        // This keeps the autocomplete search separate from the main list
        return _SearchField(controller: controller, focusNode: focusNode);
      },
    );
  }

  // Avatar widget that tries to load a network image and falls back to initials on error or when null.
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
        // show a subtle progress indicator while loading
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
        // on error (including 429) show initials fallback
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

  // Helper widget to display course thumbnail
  Widget _courseThumbnailWidget(String? url) {
    if (url == null || url.isEmpty) {
      // Placeholder if no thumbnail
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode; // <-- ADDED

  const _SearchField({
    required this.controller,
    this.focusNode, // <-- ADDED
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode, // <-- ADDED
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Search courses, topics, instructors',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// Categories, FeaturedCard, and CourseCard implementations removed — simplified list view is used instead.
