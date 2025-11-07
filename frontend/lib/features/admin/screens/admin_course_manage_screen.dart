import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/providers/api_provider.dart';
import 'package:frontend/core/models/course.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// AdminCourseManageScreen
/// Displays course details and management options for admins
/// Allows editing, deleting modules, lessons, and managing course content
class AdminCourseManageScreen extends ConsumerStatefulWidget {
  final String courseId;

  const AdminCourseManageScreen({required this.courseId, super.key});

  @override
  ConsumerState<AdminCourseManageScreen> createState() =>
      _AdminCourseManageScreenState();
}

class _AdminCourseManageScreenState
    extends ConsumerState<AdminCourseManageScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Course',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          // Delete course button
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Delete Course',
            onPressed: _isLoading
                ? null
                : () {
                    courseAsync.whenData((course) {
                      _showConfirmationDialog(
                        context: context,
                        title: 'Delete Course?',
                        content:
                            'Are you sure you want to delete "${course.title}"? This action cannot be undone. All modules, lessons, and associated files will be permanently deleted.',
                        onConfirm: () => _deleteCourse(course),
                      );
                    });
                  },
          ),
        ],
      ),
      body: courseAsync.when(
        data: (course) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header
              _buildCourseHeader(course),
              const Divider(thickness: 2),
              // Course Details
              _buildCourseDetails(course),
              const Divider(thickness: 2),
              // Modules Section
              _buildModulesSection(course),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading course',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the course header with thumbnail and title
  Widget _buildCourseHeader(Course course) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          SizedBox(
            height: 200,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            course.title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            course.description,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  /// Builds course details section
  Widget _buildCourseDetails(Course course) {
    final moduleCount = course.modules.length;
    final lessonCount = course.modules.fold<int>(
      0,
      (total, module) => total + module.lessons.length,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _detailRow('Instructor', course.instructorName),
          _detailRow('Modules', '$moduleCount'),
          _detailRow('Lessons', '$lessonCount'),
          _detailRow('Students', '${course.enrollmentCount}'),
          _detailRow('Status', course.publishStatus),
        ],
      ),
    );
  }

  /// Helper widget for detail row
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Builds modules and lessons section
  Widget _buildModulesSection(Course course) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modules & Lessons',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Add module button - placeholder for future functionality
              ElevatedButton.icon(
                onPressed: () {
                  // Implement add module functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add module - Coming soon')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Module'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (course.modules.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'No modules yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: course.modules.length,
              itemBuilder: (context, moduleIndex) {
                final module = course.modules[moduleIndex];
                return _buildModuleCard(
                  course: course,
                  module: module,
                  moduleIndex: moduleIndex,
                );
              },
            ),
        ],
      ),
    );
  }

  /// Builds individual module card with lessons
  Widget _buildModuleCard({
    required Course course,
    required dynamic module,
    required int moduleIndex,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          module.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${module.lessons.length} lessons',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit module button
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                // Implement edit module
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit module - Coming soon')),
                );
              },
            ),
            // Delete module button
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _showDeleteModuleDialog(course, module),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (module.lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No lessons yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: module.lessons.length,
              itemBuilder: (context, lessonIndex) {
                final lesson = module.lessons[lessonIndex];
                return _buildLessonTile(
                  course: course,
                  module: module,
                  lesson: lesson,
                  lessonIndex: lessonIndex,
                );
              },
            ),
          // Add lesson button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Implement add lesson
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add lesson - Coming soon')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Lesson'),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds individual lesson tile
  Widget _buildLessonTile({
    required Course course,
    required dynamic module,
    required dynamic lesson,
    required int lessonIndex,
  }) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(lesson.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasVideo)
            Row(
              children: [
                const Icon(Icons.video_library, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                const Text('Video', style: TextStyle(fontSize: 12)),
              ],
            ),
          if (lesson.textContent != null && lesson.textContent!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.description, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                const Text('Text Content', style: TextStyle(fontSize: 12)),
              ],
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              // Implement edit lesson
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit lesson - Coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _showDeleteLessonDialog(course, module, lesson),
          ),
        ],
      ),
    );
  }

  /// Reusable confirmation dialog helper
  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Deletes an entire course
  Future<void> _deleteCourse(Course course) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting course...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Call the delete provider
      await ref.read(deleteCourseProvider(course.uid).future);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      setState(() => _isLoading = false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course deleted successfully')),
      );

      // Navigate back to home page immediately
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting course: $e')));
    }
  }

  /// Deletes a module from the course
  Future<void> _deleteModule(Course course, dynamic module) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting module...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Call the delete provider
      await ref.read(
        deleteModuleProvider({
          'courseId': course.uid,
          'moduleId': module.moduleId,
        }).future,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Module deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting module: $e')));
    }
  }

  /// Deletes a lesson from a module
  Future<void> _deleteLesson(
    Course course,
    dynamic module,
    dynamic lesson,
  ) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting lesson...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Call the delete provider
      await ref.read(
        deleteLessonProvider({
          'courseId': course.uid,
          'moduleId': module.moduleId,
          'lessonId': lesson.lessonId,
        }).future,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting lesson: $e')));
    }
  }

  /// Shows confirmation dialog before deleting module
  void _showDeleteModuleDialog(dynamic course, dynamic module) {
    _showConfirmationDialog(
      context: context,
      title: 'Delete Module?',
      content:
          'Are you sure you want to delete "${module.title}"? This will also delete all lessons in this module.',
      onConfirm: () => _deleteModule(course, module),
    );
  }

  /// Shows confirmation dialog before deleting lesson
  void _showDeleteLessonDialog(dynamic course, dynamic module, dynamic lesson) {
    _showConfirmationDialog(
      context: context,
      title: 'Delete Lesson?',
      content: 'Are you sure you want to delete "${lesson.title}"?',
      onConfirm: () => _deleteLesson(course, module, lesson),
    );
  }
}
