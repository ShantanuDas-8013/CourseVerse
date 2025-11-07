import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/models/course.dart';
import 'package:frontend/core/models/lesson_ids.dart';
import 'package:frontend/core/providers/api_provider.dart';

class CoursePlayerScreen extends ConsumerStatefulWidget {
  final Course course;
  final String initialModuleId;
  final String initialLessonId;

  const CoursePlayerScreen({
    super.key,
    required this.course,
    required this.initialModuleId,
    required this.initialLessonId,
  });

  @override
  ConsumerState<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends ConsumerState<CoursePlayerScreen> {
  late String currentModuleId;
  late String currentLessonId;

  @override
  void initState() {
    super.initState();
    currentModuleId = widget.initialModuleId;
    currentLessonId = widget.initialLessonId;
  }

  // Helper to change the lesson
  void _selectLesson(String moduleId, String lessonId) {
    setState(() {
      currentModuleId = moduleId;
      currentLessonId = lessonId;
    });
  }

  // Helper to get current lesson title
  String _getCurrentLessonTitle() {
    try {
      final currentModule = widget.course.modules.firstWhere(
        (m) => m.moduleId == currentModuleId,
      );
      final currentLesson = currentModule.lessons.firstWhere(
        (l) => l.lessonId == currentLessonId,
      );
      return currentLesson.title;
    } catch (e) {
      return 'Loading...';
    }
  }

  // Helper to navigate to previous lesson
  void _goToPreviousLesson() {
    // Find current module and lesson indices
    int moduleIndex = widget.course.modules.indexWhere(
      (m) => m.moduleId == currentModuleId,
    );
    if (moduleIndex == -1) return;

    int lessonIndex = widget.course.modules[moduleIndex].lessons.indexWhere(
      (l) => l.lessonId == currentLessonId,
    );
    if (lessonIndex == -1) return;

    // Check if there's a previous lesson in current module
    if (lessonIndex > 0) {
      final prevLesson =
          widget.course.modules[moduleIndex].lessons[lessonIndex - 1];
      _selectLesson(currentModuleId, prevLesson.lessonId);
    } else if (moduleIndex > 0) {
      // Go to last lesson of previous module
      final prevModule = widget.course.modules[moduleIndex - 1];
      final lastLesson = prevModule.lessons.last;
      _selectLesson(prevModule.moduleId, lastLesson.lessonId);
    }
  }

  // Helper to navigate to next lesson
  void _goToNextLesson() {
    // Find current module and lesson indices
    int moduleIndex = widget.course.modules.indexWhere(
      (m) => m.moduleId == currentModuleId,
    );
    if (moduleIndex == -1) return;

    int lessonIndex = widget.course.modules[moduleIndex].lessons.indexWhere(
      (l) => l.lessonId == currentLessonId,
    );
    if (lessonIndex == -1) return;

    // Check if there's a next lesson in current module
    if (lessonIndex < widget.course.modules[moduleIndex].lessons.length - 1) {
      final nextLesson =
          widget.course.modules[moduleIndex].lessons[lessonIndex + 1];
      _selectLesson(currentModuleId, nextLesson.lessonId);
    } else if (moduleIndex < widget.course.modules.length - 1) {
      // Go to first lesson of next module
      final nextModule = widget.course.modules[moduleIndex + 1];
      final firstLesson = nextModule.lessons.first;
      _selectLesson(nextModule.moduleId, firstLesson.lessonId);
    }
  }

  // Helper to check if there's a previous lesson
  bool _hasPreviousLesson() {
    int moduleIndex = widget.course.modules.indexWhere(
      (m) => m.moduleId == currentModuleId,
    );
    if (moduleIndex == -1) return false;

    int lessonIndex = widget.course.modules[moduleIndex].lessons.indexWhere(
      (l) => l.lessonId == currentLessonId,
    );
    if (lessonIndex == -1) return false;

    return lessonIndex > 0 || moduleIndex > 0;
  }

  // Helper to check if there's a next lesson
  bool _hasNextLesson() {
    int moduleIndex = widget.course.modules.indexWhere(
      (m) => m.moduleId == currentModuleId,
    );
    if (moduleIndex == -1) return false;

    int lessonIndex = widget.course.modules[moduleIndex].lessons.indexWhere(
      (l) => l.lessonId == currentLessonId,
    );
    if (lessonIndex == -1) return false;

    return lessonIndex <
            widget.course.modules[moduleIndex].lessons.length - 1 ||
        moduleIndex < widget.course.modules.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final lessonIds = LessonIds(
      courseId: widget.course.uid,
      moduleId: currentModuleId,
      lessonId: currentLessonId,
    );

    final currentLessonTitle = _getCurrentLessonTitle();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/course/${widget.course.uid}'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.course.title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Lesson: $currentLessonTitle',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Main Content Area ---
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
              child: ref
                  .watch(lessonContentProvider(lessonIds))
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading lesson: $err',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    data: (content) {
                      return ListView(
                        children: [
                          // --- Video Player Widget ---
                          if (content.videoUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: VideoPlayerWidget(
                                  videoUrl: content.videoUrl!,
                                ),
                              ),
                            )
                          else
                            Container(
                              height: MediaQuery.of(context).size.height * 0.4,
                              margin: const EdgeInsets.only(bottom: 24.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'No video for this lesson.\nCheck the text content below.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),

                          // --- Action Buttons ---
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Previous Button
                                OutlinedButton.icon(
                                  onPressed: _hasPreviousLesson()
                                      ? _goToPreviousLesson
                                      : null,
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    size: 16,
                                  ),
                                  label: const Text('Previous'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                // Mark Complete Button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Mark as complete feature coming soon!',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Mark as Complete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                // Next Button
                                OutlinedButton.icon(
                                  onPressed: _hasNextLesson()
                                      ? _goToNextLesson
                                      : null,
                                  label: const Text('Next'),
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- Text Content ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              content.textContent ??
                                  'No additional text content for this lesson.',
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      );
                    },
                  ),
            ),
          ),

          // --- Curriculum Sidebar ---
          Container(
            width: 320,
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Text(
                    'Course Content',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                // Modules List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.course.modules.length,
                    itemBuilder: (context, moduleIndex) {
                      final module = widget.course.modules[moduleIndex];
                      return Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: ValueKey(module.moduleId),
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          title: Text(
                            module.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${module.lessons.length} lesson${module.lessons.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          initiallyExpanded: module.moduleId == currentModuleId,
                          childrenPadding: const EdgeInsets.only(left: 8),
                          children: module.lessons.map((lesson) {
                            final bool isSelected =
                                lesson.lessonId == currentLessonId;
                            return Material(
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _selectLesson(
                                    module.moduleId,
                                    lesson.lessonId,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 10.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        lesson.videoUrl != null
                                            ? Icons.play_circle_outline
                                            : Icons.article_outlined,
                                        size: 18,
                                        color: isSelected
                                            ? Colors.blue.shade700
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          lesson.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.blue.shade700
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '5 min',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- A separate widget to manage the VideoPlayerController state ---
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      // Await initialization before creating ChewieController
      await _videoPlayerController.initialize();

      // Ensure widget is still mounted before setting state
      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: false, // Start paused, let user click play
            looping: false, // Typically don't loop course videos
            allowFullScreen: true,
            aspectRatio: _videoPlayerController.value.aspectRatio,
            placeholder: Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            errorBuilder: (context, errorMessage) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error loading video: $errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              );
            },
          );
        });
      }
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        setState(() {
          // ChewieController remains null, error will be shown in build
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the video URL changes (user clicks a new lesson)
    if (oldWidget.videoUrl != widget.videoUrl) {
      // Dispose old controllers *before* creating new ones
      _chewieController?.dispose();
      _videoPlayerController.dispose();

      // Reset Chewie controller to null to show loading state
      setState(() {
        _chewieController = null;
      });
      // Initialize new player
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    // IMPORTANT: Dispose of both controllers
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator until Chewie is ready
    if (_chewieController == null ||
        !_videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9, // Default aspect ratio while loading
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    // Return Chewie only when initialized
    return AspectRatio(
      aspectRatio: _chewieController!.videoPlayerController.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}
