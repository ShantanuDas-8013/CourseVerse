import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/providers/api_provider.dart';
import 'package:frontend/core/models/course.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  bool _isEnrolling = false;

  Future<void> _enrollInCourse() async {
    setState(() => _isEnrolling = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.enrollInCourse(widget.courseId);

      // Success! Show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully enrolled!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh the 'myCoursesProvider' to update the UI
      ref.invalidate(myCoursesProvider);
      // Also refresh the course detail to ensure consistency
      ref.invalidate(courseDetailProvider(widget.courseId));
    } catch (e) {
      // Handle the "already enrolled" case gracefully
      final errorMessage = e.toString();
      if (errorMessage.contains('already enrolled') || errorMessage.contains('409')) {
        // User is already enrolled, just refresh the UI
        ref.invalidate(myCoursesProvider);
        ref.invalidate(courseDetailProvider(widget.courseId));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already enrolled in this course!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Show other errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for this specific course
    final courseDetailAsync = ref.watch(courseDetailProvider(widget.courseId));
    // Watch the provider for all enrolled courses
    final myCoursesAsync = ref.watch(myCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Course Details'),
      ),
      body: courseDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (course) {
          return myCoursesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (myCourses) {
              final bool isEnrolled = myCourses.any(
                (c) => c.uid == widget.courseId,
              );
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;
                  return isWide
                      ? _buildWideLayout(course, isEnrolled)
                      : _buildNarrowLayout(course, isEnrolled);
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- Helper widget for the button ---
  Widget _buildEnrollButton(bool isEnrolled) {
    if (isEnrolled) {
      return ElevatedButton(
        onPressed: () {
          // Navigate to the first lesson of the first module
          final firstModule = ref
              .read(courseDetailProvider(widget.courseId))
              .value
              ?.modules
              .first;
          final firstLesson = firstModule?.lessons.first;

          if (firstModule != null && firstLesson != null) {
            context.go(
              '/player/${widget.courseId}/${firstModule.moduleId}/${firstLesson.lessonId}',
              // Pass the full course object
              extra: ref.read(courseDetailProvider(widget.courseId)).value,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Go to Course'),
      );
    }

    // "Enroll" button
    return ElevatedButton(
      onPressed: _isEnrolling ? null : _enrollInCourse,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isEnrolling
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Enroll Now'),
    );
  }

  Widget _buildWideLayout(Course course, bool isEnrolled) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeroSection(course, isWide: true),
                  _buildLearningOutcomes(course),
                  _buildDescription(course),
                  _buildCurriculum(course, isEnrolled),
                  _buildInstructorBio(course),
                ]),
              ),
            ],
          ),
        ),
        SizedBox(width: 350, child: _buildStickySidebar(course, isEnrolled)),
      ],
    );
  }

  Widget _buildNarrowLayout(Course course, bool isEnrolled) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeroSection(course, isWide: false),
                  _buildLearningOutcomes(course),
                  _buildDescription(course),
                  _buildCurriculum(course, isEnrolled),
                  _buildInstructorBio(course),
                ]),
              ),
            ],
          ),
        ),
        _buildBottomCTA(course, isEnrolled),
      ],
    );
  }

  Widget _buildHeroSection(Course course, {required bool isWide}) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Master the fundamentals and advance your skills',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundImage: course.instructorImageUrl != null
                    ? NetworkImage(course.instructorImageUrl!)
                    : null,
                radius: 20,
                child: course.instructorImageUrl == null
                    ? Text(
                        course.instructorName.isNotEmpty
                            ? course.instructorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'By ${course.instructorName}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < 4
                        ? Icons.star
                        : Icons.star_border, // Placeholder rating
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '4.5 (120 reviews)', // Placeholder
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '500 students enrolled', // Placeholder
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearningOutcomes(Course course) {
    // Placeholder learning outcomes
    final outcomes = [
      'Understand core concepts',
      'Apply knowledge in practice',
      'Build real-world projects',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you\'ll learn',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...outcomes.map(
            (outcome) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text(outcome)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Course course) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Description',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(course.description),
        ],
      ),
    );
  }

  Widget _buildCurriculum(Course course, bool isEnrolled) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Curriculum', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...course.modules.map(
            (module) => Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ExpansionTile(
                title: Text(
                  module.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${module.lessons.length} lessons'),
                initiallyExpanded: module == course.modules.first,
                children: module.lessons
                    .map(
                      (lesson) => ListTile(
                        leading: Icon(
                          lesson.videoUrl != null
                              ? Icons.play_circle_fill
                              : Icons.article,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(lesson.title),
                        subtitle: Text(lesson.getFormattedDuration()),
                        onTap: () {
                          if (isEnrolled) {
                            // If enrolled, navigate to player
                            context.go(
                              '/player/${course.uid}/${module.moduleId}/${lesson.lessonId}',
                              extra: course,
                            );
                          } else {
                            // If not enrolled, show dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Enrollment Required'),
                                  content: const Text(
                                    'You must enroll in this course to view the lessons.',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('OK'),
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pop(); // Close the dialog
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorBio(Course course) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About the Instructor',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: course.instructorImageUrl != null
                        ? NetworkImage(course.instructorImageUrl!)
                        : null,
                    radius: 30,
                    child: course.instructorImageUrl == null
                        ? Text(
                            course.instructorName.isNotEmpty
                                ? course.instructorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.instructorName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Experienced instructor with years of expertise.',
                        ), // Placeholder
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickySidebar(Course course, bool isEnrolled) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Text(
            '\$99',
            style: Theme.of(context).textTheme.headlineMedium,
          ), // Placeholder
          const SizedBox(height: 16),
          _buildEnrollButton(isEnrolled),
          const SizedBox(height: 16),
          _buildStatRow(Icons.play_circle, '${course.modules.length} modules'),
          _buildStatRow(
            Icons.access_time,
            '${course.getFormattedTotalDuration()} total',
          ),
          _buildStatRow(Icons.language, 'English'),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(text)],
      ),
    );
  }

  Widget _buildBottomCTA(Course course, bool isEnrolled) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildEnrollButton(isEnrolled),
    );
  }
}
