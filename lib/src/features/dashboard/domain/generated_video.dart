/// Model đại diện cho một video đã được generate và lưu vào DB.
class GeneratedVideo {
  final String id;
  final String jobId;
  final String? templateId;
  final String videoUrl;
  final Map<String, dynamic> meta;
  final DateTime createdAt;

  const GeneratedVideo({
    required this.id,
    required this.jobId,
    this.templateId,
    required this.videoUrl,
    required this.meta,
    required this.createdAt,
  });

  factory GeneratedVideo.fromJson(Map<String, dynamic> json) {
    return GeneratedVideo(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      templateId: json['templateId'] as String?,
      videoUrl: json['videoUrl'] as String? ?? '',
      meta: (json['meta'] as Map<String, dynamic>?) ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Tên hiển thị: lấy từ meta nếu có, fallback về jobId ngắn
  String get displayName {
    final title = meta['title'] as String?;
    if (title != null && title.isNotEmpty) return title;
    return 'Video ${jobId.length >= 8 ? jobId.substring(0, 8) : jobId}';
  }
}
