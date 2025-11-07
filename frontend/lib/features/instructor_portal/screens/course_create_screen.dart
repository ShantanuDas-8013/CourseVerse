import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/api_provider.dart';
import 'package:frontend/features/instructor_portal/state/course_form_state.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; // For better typography

class CourseCreateScreen extends ConsumerStatefulWidget {
  const CourseCreateScreen({super.key});

  @override
  ConsumerState<CourseCreateScreen> createState() => _CourseCreateScreenState();
}

class _CourseCreateScreenState extends ConsumerState<CourseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String _loadingMessage = '';

  // --- Main Submission Logic ---
  Future<void> _submitCourse() async {
    if (!_formKey.currentState!.validate()) {
      // Optionally show a snackbar if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Starting...';
    });

    final apiService = ref.read(apiServiceProvider);
    // Read the current state once for submission
    final modulesState = ref.read(courseFormProvider);
    final formNotifier = ref.read(courseFormProvider.notifier);

    // Collect module titles from the state (they might have changed via onChanged)
    // NOTE: This assumes TextFormField onChanged updates the state directly.
    // If not, you'd need controllers or other state management for module/lesson titles.

    try {
      // --- Step 0: Upload Thumbnail (if selected) ---
      if (formNotifier.thumbnailFile != null) {
        setState(() {
          _loadingMessage = 'Uploading thumbnail...';
        });

        final thumbUrlResponse = await apiService.getPresignedUploadUrl(
          formNotifier.thumbnailFile!.name,
          formNotifier.thumbnailContentType!,
        );

        await apiService.uploadFileToS3(
          thumbUrlResponse['url'],
          formNotifier
              .thumbnailFile!
              .bytes!, // Assuming web platform gives bytes
          formNotifier.thumbnailContentType!,
        );

        formNotifier.uploadedThumbnailObjectKey = thumbUrlResponse['objectKey'];
      }

      // --- Step 1: Upload all lesson files ---
      for (int m = 0; m < modulesState.length; m++) {
        // Validate module title here if needed
        if (modulesState[m].title.isEmpty) {
          throw Exception('Module ${m + 1} title cannot be empty.');
        }

        for (int l = 0; l < modulesState[m].lessons.length; l++) {
          final lesson = modulesState[m].lessons[l];
          // Validate lesson title here if needed
          if (lesson.title.isEmpty) {
            throw Exception(
              'Lesson ${l + 1} in Module ${m + 1} title cannot be empty.',
            );
          }

          if (lesson.file != null) {
            setState(() {
              _loadingMessage = 'Uploading ${lesson.file!.name}...';
            });

            final urlResponse = await apiService.getPresignedUploadUrl(
              lesson.file!.name,
              lesson.fileContentType!,
            );

            await apiService.uploadFileToS3(
              urlResponse['url'],
              lesson.file!.bytes!, // Assuming web platform gives bytes
              lesson.fileContentType!,
            );

            lesson.uploadedObjectKey = urlResponse['objectKey'];
          }
        }
      }

      // --- Step 2: Build the final JSON payload ---
      setState(() {
        _loadingMessage = 'Saving course...';
      });

      final Map<String, dynamic> courseData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'thumbnailObjectKey': formNotifier.uploadedThumbnailObjectKey,
        'modules': modulesState
            .map(
              (module) => {
                'title': module.title, // Use the title from the state object
                'lessons': module.lessons
                    .map(
                      (lesson) => {
                        'title':
                            lesson.title, // Use the title from the state object
                        'textContent': lesson.textContent,
                        'videoObjectKey': lesson.uploadedObjectKey,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      };

      // --- Step 3: Create the course ---
      await apiService.createCourse(courseData);

      // --- Step 4: Success ---
      if (!mounted) {
        return; // Check if widget is still mounted before proceeding
      }

      ref.read(courseFormProvider.notifier).clear(); // Clear the state
      _titleController.clear(); // Clear local controllers
      _descriptionController.clear();

      ref.invalidate(allCoursesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/instructor'); // Navigate back
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted && _isLoading) {
        // Ensure isLoading is true before setting false
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(courseFormProvider);
    final formNotifier = ref.read(courseFormProvider.notifier);

    if (_isLoading) {
      // Improved Loading Screen
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _loadingMessage,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text('Please wait...', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    // Main Form UI
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB), // Consistent background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/instructor'), // Go back to dashboard
        ),
        title: Text(
          'Create New Course',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_alt, size: 18),
              label: const Text('Save Course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _submitCourse,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          // Use SingleChildScrollView instead of ListView for better form structure
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Course Details Section ---
              _buildSectionCard(
                title: 'Course Information',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Course Title'),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration(
                        'Course Description (optional)',
                      ),
                      maxLines: 4,
                      validator: (v) => v != null && v.length > 500
                          ? 'Description too long (max 500 chars)'
                          : null, // Example validation
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Thumbnail Section ---
              _buildSectionCard(
                title: 'Course Thumbnail',
                child: _buildThumbnailPicker(formNotifier),
              ),

              const SizedBox(height: 24),

              // --- Curriculum Section Title ---
              Text(
                'Course Curriculum',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // --- Dynamic Modules ---
              if (modules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      'Add modules to build your course curriculum.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                ...modules.asMap().entries.map((entry) {
                  int moduleIndex = entry.key;
                  ModuleFormState module = entry.value;
                  // Use unique keys for state preservation if list changes
                  return _buildModuleCard(
                    moduleIndex,
                    module,
                    formNotifier,
                    key: ValueKey('module_$moduleIndex'),
                  );
                }),

              // --- Add Module Button ---
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Module'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    formNotifier.addModule();
                    // Optionally scroll to the new module if needed
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper for Consistent Input Decoration ---
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
    );
  }

  // --- Helper to wrap sections in a styled Card ---
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      shadowColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // --- Helper to build Thumbnail Picker UI ---
  Widget _buildThumbnailPicker(CourseFormStateNotifier notifier) {
    final thumbnailFile = notifier.thumbnailFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text('Course Thumbnail', style: Theme.of(context).textTheme.titleMedium),
        // const SizedBox(height: 8),
        thumbnailFile == null
            ? OutlinedButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Upload Thumbnail Image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.5 * 255),
                  ),
                ),
                onPressed: () async {
                  await notifier.pickThumbnail();
                  if (mounted) setState(() {});
                },
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      thumbnailFile.bytes!,
                      width: 120, // Slightly larger preview
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thumbnailFile.name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(thumbnailFile.size / 1024).toStringAsFixed(1)} KB', // Show size
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                    tooltip: 'Change Thumbnail',
                    onPressed: () async {
                      await notifier.pickThumbnail();
                      if (mounted) setState(() {});
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red.shade400,
                    ),
                    tooltip: 'Remove Thumbnail',
                    onPressed: () {
                      notifier.thumbnailFile = null;
                      notifier.thumbnailContentType = null;
                      notifier.uploadedThumbnailObjectKey =
                          null; // Clear key too
                      setState(() {});
                    },
                  ),
                ],
              ),
      ],
    );
  }

  // --- Helper to build Module UI ---
  Widget _buildModuleCard(
    int moduleIndex,
    ModuleFormState module,
    CourseFormStateNotifier notifier, {
    Key? key, // Add Key
  }) {
    return Card(
      key: key, // Use the key here
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    // Important: Use initialValue only or controller only, not both.
                    // Use onChanged to update the state object directly.
                    initialValue: module.title,
                    decoration:
                        _inputDecoration(
                          'Module ${moduleIndex + 1} Title',
                        ).copyWith(
                          // Make module title slightly larger/bolder if desired
                        ),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Module title is required' : null,
                    onChanged: (value) =>
                        module.title = value.trim(), // Update state on change
                    // Consider adding a controller if more complex interactions are needed
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.red.shade400,
                    ),
                    tooltip: 'Delete Module ${moduleIndex + 1}',
                    onPressed: () {
                      // Optional: Show confirmation dialog before deleting
                      notifier.removeModule(moduleIndex);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(), // Visually separate module title from lessons
            const SizedBox(height: 8),

            // --- Dynamic Lessons ---
            if (module.lessons.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No lessons in this module yet.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ...module.lessons.asMap().entries.map((entry) {
                int lessonIndex = entry.key;
                LessonFormState lesson = entry.value;
                return _buildLessonForm(
                  moduleIndex,
                  lessonIndex,
                  lesson,
                  notifier,
                  key: ValueKey(
                    'module_${moduleIndex}_lesson_$lessonIndex',
                  ), // Unique keys for lessons
                );
              }),

            // --- Add Lesson Button ---
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Lesson'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: () => notifier.addLesson(moduleIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper to build Lesson UI ---
  Widget _buildLessonForm(
    int moduleIndex,
    int lessonIndex,
    LessonFormState lesson,
    CourseFormStateNotifier notifier, {
    Key? key, // Add Key
  }) {
    return Container(
      key: key, // Use key here
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white, // White background for lesson form
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lesson ${lessonIndex + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red.shade400,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete Lesson ${lessonIndex + 1}',
                onPressed: () =>
                    notifier.removeLesson(moduleIndex, lessonIndex),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: lesson.title,
            decoration: _inputDecoration(
              'Lesson Title',
            ).copyWith(isDense: true),
            validator: (v) =>
                v!.trim().isEmpty ? 'Lesson title is required' : null,
            onChanged: (v) => lesson.title = v.trim(), // Update state
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: lesson.textContent,
            decoration: _inputDecoration(
              'Text Content (optional)',
            ).copyWith(isDense: true),
            maxLines: 3,
            onChanged: (v) => lesson.textContent = v,
          ),
          const SizedBox(height: 12),

          // --- File Picker ---
          _buildVideoPicker(
            lesson,
            () => notifier.pickFile(moduleIndex, lessonIndex),
            () {
              setState(() {
                // Use setState to trigger rebuild when clearing file
                lesson.file = null;
                lesson.fileContentType = null;
                lesson.uploadedObjectKey = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // --- Helper for Video Picker UI within Lesson ---
  Widget _buildVideoPicker(
    LessonFormState lesson,
    VoidCallback onPick,
    VoidCallback onClear,
  ) {
    if (lesson.file == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.video_call_outlined, size: 20),
        label: const Text('Add Video (Optional)'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          foregroundColor: Colors.grey.shade700,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        onPressed: onPick,
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.video_file_outlined, color: Colors.green.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.file!.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${(lesson.file!.size / 1024).toStringAsFixed(1)} KB', // Show size
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.clear, size: 18, color: Colors.red.shade400),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Remove Video',
              onPressed: onClear,
            ),
          ],
        ),
      );
    }
  }
}
