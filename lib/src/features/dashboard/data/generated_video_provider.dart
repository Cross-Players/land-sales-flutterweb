import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/generated_video.dart';
import 'generated_video_service.dart';

final generatedVideoServiceProvider = Provider<GeneratedVideoService>(
  (_) => GeneratedVideoService(),
);

/// FutureProvider — load danh sách video từ API.
/// Dùng ref.invalidate(generatedVideosProvider) để refresh.
final generatedVideosProvider = FutureProvider<List<GeneratedVideo>>((ref) {
  return ref.watch(generatedVideoServiceProvider).fetchVideos();
});
