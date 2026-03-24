import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../domain/video_template.dart';
import '../domain/frame_data.dart';
import '../domain/video_job.dart';
import '../data/video_job_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../dashboard/domain/generated_video.dart';
import '../../dashboard/presentation/video_detail_screen.dart';

/// Màn hình chờ video được generate.
/// Subscribe SSE stream và tự navigate khi video done.
class VideoWaitingScreen extends ConsumerStatefulWidget {
  final String jobId;
  final VideoTemplate selectedTemplate;
  final List<FrameData> frames;
  final Map<int, PlatformFile?> selectedFiles;

  const VideoWaitingScreen({
    super.key,
    required this.jobId,
    required this.selectedTemplate,
    required this.frames,
    required this.selectedFiles,
  });

  @override
  ConsumerState<VideoWaitingScreen> createState() => _VideoWaitingScreenState();
}

class _VideoWaitingScreenState extends ConsumerState<VideoWaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  VideoJobStatus _status = VideoJobStatus.pending;
  String? _errorMessage;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onJobEvent(VideoJob job) {
    if (!mounted || _navigated) return;

    setState(() => _status = job.status);

    if (job.isDone) {
      _navigated = true;
      _navigateToResult(job.videoUrl);
    } else if (job.isError) {
      setState(() => _errorMessage = job.errorMessage ?? 'Có lỗi xảy ra');
    }
  }

  void _navigateToResult(String? videoUrl) {
    final generatedVideo = GeneratedVideo(
      id: '',
      jobId: widget.jobId,
      templateId: widget.selectedTemplate.id,
      videoUrl: videoUrl ?? '',
      meta: {'title': widget.selectedTemplate.title},
      createdAt: DateTime.now(),
    );

    // Delay nhỏ để animation hoàn thành
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoDetailScreen(video: generatedVideo),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dùng ref.listen để navigate — KHÔNG dùng whenData trong build() vì không
    // đảm bảo gọi callback mỗi lần emit (chỉ chạy khi widget rebuild)
    ref.listen<AsyncValue<VideoJob>>(
      videoJobStreamProvider(widget.jobId),
      (_, next) => next.whenData(_onJobEvent),
    );

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animation ───────────────────────────────────────────
                  _buildStatusAnimation(),
                  const SizedBox(height: 40),

                  // ── Status text ─────────────────────────────────────────
                  _buildStatusText(),
                  const SizedBox(height: 16),

                  // ── Job ID ──────────────────────────────────────────────
                  Text(
                    'Job ID: ${widget.jobId.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.3),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Template info ───────────────────────────────────────
                  _buildTemplateCard(),
                  const SizedBox(height: 48),

                  // ── Error actions ───────────────────────────────────────
                  if (_status == VideoJobStatus.error) _buildErrorActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAnimation() {
    if (_status == VideoJobStatus.error) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.error_outline, size: 52, color: Colors.red),
      );
    }

    if (_status == VideoJobStatus.done) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_outline,
          size: 52,
          color: Colors.green,
        ),
      );
    }

    // Pending / Processing — pulsing animation
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final scale = 0.9 + 0.1 * _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Transform.scale(
              scale: scale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(
                      0.2 + 0.3 * _pulseController.value,
                    ),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Inner circle
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: AppTheme.accentBlue,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusText() {
    String title;
    String subtitle;

    switch (_status) {
      case VideoJobStatus.pending:
        title = 'Đang khởi động...';
        subtitle = 'n8n đang nhận yêu cầu của bạn';
      case VideoJobStatus.processing:
        title = 'Đang tạo video';
        subtitle = 'AI đang xử lý và render video, vui lòng chờ';
      case VideoJobStatus.done:
        title = 'Video đã sẵn sàng!';
        subtitle = 'Đang chuyển sang màn hình kết quả...';
      case VideoJobStatus.error:
        title = 'Có lỗi xảy ra';
        subtitle = _errorMessage ?? 'Vui lòng thử lại';
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.selectedTemplate.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: Colors.white.withOpacity(0.1),
                child: const Icon(Icons.image, color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedTemplate.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.frames.length} slides',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.selectedTemplate.tag,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Quay lại và thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // Fallback: manually check job status
            ref.invalidate(videoJobStreamProvider(widget.jobId));
            setState(() {
              _status = VideoJobStatus.pending;
              _errorMessage = null;
            });
          },
          child: Text(
            'Thử kết nối lại',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ),
      ],
    );
  }
}
