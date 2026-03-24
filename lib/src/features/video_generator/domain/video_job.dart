/// Trạng thái của một video generation job.
enum VideoJobStatus { pending, processing, done, error }

/// Model đại diện cho một video job từ API.
class VideoJob {
  final String jobId;
  final VideoJobStatus status;
  final String? videoUrl;
  final String? errorMessage;

  const VideoJob({
    required this.jobId,
    required this.status,
    this.videoUrl,
    this.errorMessage,
  });

  factory VideoJob.fromJson(Map<String, dynamic> json) {
    return VideoJob(
      jobId: json['jobId'] as String,
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      videoUrl: json['videoUrl'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  static VideoJobStatus _parseStatus(String raw) {
    switch (raw) {
      case 'processing':
        return VideoJobStatus.processing;
      case 'done':
        return VideoJobStatus.done;
      case 'error':
        return VideoJobStatus.error;
      default:
        return VideoJobStatus.pending;
    }
  }

  bool get isDone => status == VideoJobStatus.done;
  bool get isError => status == VideoJobStatus.error;
  bool get isFinished => isDone || isError;

  VideoJob copyWith({
    VideoJobStatus? status,
    String? videoUrl,
    String? errorMessage,
  }) {
    return VideoJob(
      jobId: jobId,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
