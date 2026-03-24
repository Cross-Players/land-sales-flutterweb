import 'package:file_picker/file_picker.dart';
import 'video_template.dart';

class VideoResultData {
  final VideoTemplate template;
  final List<MediaItem> mediaItems;

  /// URL video đã được generate (null nếu chưa có)
  final String? videoUrl;

  VideoResultData({
    required this.template,
    required this.mediaItems,
    this.videoUrl,
  });

  int get totalSlides => mediaItems.length;
  int get estimatedDuration => totalSlides * 5; // 5 seconds per slide
}

class MediaItem {
  final PlatformFile? file;
  final String fileUrl;
  final String fileType; // 'image' or 'video'
  final String caption;
  final String voiceText;

  MediaItem({
    this.file,
    required this.fileUrl,
    required this.fileType,
    required this.caption,
    required this.voiceText,
  });

  bool get hasContent =>
      fileUrl.isNotEmpty || caption.isNotEmpty || voiceText.isNotEmpty;
}
