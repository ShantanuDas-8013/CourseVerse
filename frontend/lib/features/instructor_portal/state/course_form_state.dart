import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Local Models ---

class LessonFormState {
  String title;
  String? textContent;

  // For file handling
  PlatformFile? file; // The selected file
  String? fileContentType;
  String? uploadedObjectKey; // The S3 key after upload

  LessonFormState({this.title = '', this.textContent});
}

class ModuleFormState {
  String title;
  List<LessonFormState> lessons = [];
  ModuleFormState({this.title = ''});
}

// --- State Notifier ---

class CourseFormStateNotifier extends StateNotifier<List<ModuleFormState>> {
  CourseFormStateNotifier() : super([]);

  // Thumbnail state
  PlatformFile? thumbnailFile;
  String? thumbnailContentType;
  String? uploadedThumbnailObjectKey;

  // Add a new empty module
  void addModule() {
    state = [...state, ModuleFormState()];
  }

  // Remove a module
  void removeModule(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }

  // Add a new empty lesson to a module
  void addLesson(int moduleIndex) {
    state[moduleIndex].lessons.add(LessonFormState());
    state = [...state]; // Notify listeners
  }

  // Remove a lesson from a module
  void removeLesson(int moduleIndex, int lessonIndex) {
    state[moduleIndex].lessons.removeAt(lessonIndex);
    state = [...state]; // Notify listeners
  }

  // Update a file for a lesson
  void pickFile(int moduleIndex, int lessonIndex) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      state[moduleIndex].lessons[lessonIndex].file = result.files.first;
      state[moduleIndex].lessons[lessonIndex].fileContentType =
          result.files.first.extension == 'mp4'
          ? 'video/mp4'
          : 'video/quicktime';
      state = [...state];
    }
  }

  // Pick thumbnail image
  Future<void> pickThumbnail() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      thumbnailFile = result.files.first;
      // Basic content type detection based on extension
      String extension = thumbnailFile!.extension?.toLowerCase() ?? '';
      if (extension == 'jpg' || extension == 'jpeg') {
        thumbnailContentType = 'image/jpeg';
      } else if (extension == 'png') {
        thumbnailContentType = 'image/png';
      } else {
        thumbnailContentType = null;
      }
    }
  }

  // Clear the whole form
  void clear() {
    state = [];
    thumbnailFile = null;
    thumbnailContentType = null;
    uploadedThumbnailObjectKey = null;
  }
}

// --- Provider ---
final courseFormProvider =
    StateNotifierProvider<CourseFormStateNotifier, List<ModuleFormState>>(
      (ref) => CourseFormStateNotifier(),
    );
