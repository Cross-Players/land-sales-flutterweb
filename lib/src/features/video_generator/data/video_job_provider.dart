import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/video_job_service.dart';
import '../domain/video_job.dart';

// ─── Service provider ──────────────────────────────────────────────────────

final videoJobServiceProvider = Provider<VideoJobService>((ref) {
  return VideoJobService();
});

// ─── StreamProvider.family — lắng nghe SSE của 1 jobId ────────────────────

/// Dùng: ref.watch(videoJobStreamProvider('job-uuid'))
/// Phát VideoJob mỗi khi server push event qua SSE.
final videoJobStreamProvider = StreamProvider.family<VideoJob, String>((
  ref,
  jobId,
) {
  final service = ref.watch(videoJobServiceProvider);
  return service.watchJob(jobId);
});

// ─── StateNotifier — quản lý toàn bộ flow tạo video ──────────────────────

/// State cho quá trình submit + chờ video
class VideoSubmitState {
  final bool isSubmitting; // Đang gọi API tạo job + trigger n8n
  final String? jobId; // Đã có jobId, đang chờ SSE
  final VideoJob? latestJobEvent; // Event SSE mới nhất
  final String? errorMessage;

  const VideoSubmitState({
    this.isSubmitting = false,
    this.jobId,
    this.latestJobEvent,
    this.errorMessage,
  });

  bool get isWaitingForVideo => jobId != null && latestJobEvent?.isDone != true;
  bool get isVideoReady => latestJobEvent?.isDone == true;

  VideoSubmitState copyWith({
    bool? isSubmitting,
    String? jobId,
    VideoJob? latestJobEvent,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VideoSubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      jobId: jobId ?? this.jobId,
      latestJobEvent: latestJobEvent ?? this.latestJobEvent,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  VideoSubmitState reset() => const VideoSubmitState();
}

class VideoSubmitNotifier extends StateNotifier<VideoSubmitState> {
  // ignore: unused_field
  final VideoJobService _jobService;
  // ignore: unused_field
  final Ref _ref;

  VideoSubmitNotifier(this._jobService, this._ref)
    : super(const VideoSubmitState());

  /// Cập nhật state khi có SSE event mới.
  /// Được gọi từ UI khi watch(videoJobStreamProvider) có data.
  void onJobEvent(VideoJob job) {
    state = state.copyWith(latestJobEvent: job);
  }

  void onJobError(Object error) {
    state = state.copyWith(isSubmitting: false, errorMessage: error.toString());
  }

  /// Set jobId sau khi tạo job thành công — bắt đầu SSE watch.
  void setJobId(String jobId) {
    state = state.copyWith(jobId: jobId, isSubmitting: false);
  }

  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value, clearError: true);
  }

  void setError(String message) {
    state = state.copyWith(isSubmitting: false, errorMessage: message);
  }

  void reset() {
    state = state.reset();
  }
}

final videoSubmitProvider =
    StateNotifierProvider<VideoSubmitNotifier, VideoSubmitState>((ref) {
      final service = ref.watch(videoJobServiceProvider);
      return VideoSubmitNotifier(service, ref);
    });
