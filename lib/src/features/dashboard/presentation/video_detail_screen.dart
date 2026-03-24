import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../domain/generated_video.dart';
import '../../../shared/theme/app_theme.dart';
import '../../facebook_post/presentation/upload_facebook_post_screen.dart';

class VideoDetailScreen extends StatefulWidget {
  final GeneratedVideo video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = true;
  bool _isVideoError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    setState(() {
      _isVideoInitializing = true;
      _isVideoError = false;
    });
    try {
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );
      await ctrl.initialize();
      if (mounted) {
        setState(() {
          _videoController = ctrl;
          _isVideoInitializing = false;
        });
      } else {
        ctrl.dispose();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isVideoInitializing = false;
          _isVideoError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVideoCard(),
                        const SizedBox(height: 24),
                        _buildMetaCard(),
                        const SizedBox(height: 24),
                        _buildActionsCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentBlue, Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Chi tiết video',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Breadcrumb badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 14,
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Dashboard / Chi tiết',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Video Player Card ─────────────────────────────────────────────────────

  Widget _buildVideoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player area
          AspectRatio(aspectRatio: 16 / 9, child: _buildVideoPlayerContent()),

          // Controls
          if (_videoController != null && _videoController!.value.isInitialized)
            _buildVideoControls(),

          // Title & URL row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 13,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.video.videoUrl,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.video.videoUrl),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã copy URL vào clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.copy_outlined,
                                size: 14,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Hoàn thành',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerContent() {
    if (_isVideoInitializing) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Đang tải video...',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_isVideoError) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                color: Colors.white38,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Không thể tải video',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _initVideo,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text(
                  'Thử lại',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_videoController != null && _videoController!.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _videoController!.value.isPlaying
                ? _videoController!.pause()
                : _videoController!.play();
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(_videoController!),
            // Play/pause overlay
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _videoController!,
              builder: (_, value, __) {
                if (value.isPlaying) return const SizedBox.shrink();
                return Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF1A1A2E),
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white24),
      ),
    );
  }

  Widget _buildVideoControls() {
    final ctrl = _videoController!;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: ctrl,
      builder: (_, value, __) {
        final position = value.position;
        final duration = value.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        String fmt(Duration d) {
          final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
          final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
          return '$m:$s';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF111827),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  value.isPlaying ? ctrl.pause() : ctrl.play();
                }),
                icon: Icon(
                  value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
              Text(
                fmt(position),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: AppTheme.accentBlue,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppTheme.accentBlue,
                    overlayColor: AppTheme.accentBlue.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (v) => ctrl.seekTo(
                      Duration(
                        milliseconds: (v * duration.inMilliseconds).round(),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                fmt(duration),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => setState(() {
                  ctrl.setVolume(value.volume > 0 ? 0 : 1);
                }),
                icon: Icon(
                  value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white54,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: () {
                  ctrl.seekTo(Duration.zero);
                  ctrl.play();
                },
                icon: const Icon(Icons.replay, color: Colors.white54, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Meta Info Card ────────────────────────────────────────────────────────

  Widget _buildMetaCard() {
    final dateStr = DateFormat(
      'HH:mm • dd/MM/yyyy',
    ).format(widget.video.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.calendar_today_outlined, 'Ngày tạo', dateStr),
          _buildDivider(),
          _buildInfoRow(
            Icons.movie_filter_outlined,
            'Template',
            widget.video.templateId ?? '–',
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.tag_outlined,
            'Job ID',
            widget.video.jobId.isNotEmpty ? widget.video.jobId : '–',
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.fingerprint_outlined,
            'Video ID',
            widget.video.id.isNotEmpty ? widget.video.id : '–',
          ),
          // Extra meta fields nếu có
          if (widget.video.meta.isNotEmpty) ...[
            _buildDivider(),
            ...widget.video.meta.entries
                .where(
                  (e) =>
                      e.value != null &&
                      e.value.toString().isNotEmpty &&
                      e.key != 'title',
                )
                .map(
                  (e) => Column(
                    children: [
                      _buildInfoRow(
                        Icons.info_outline,
                        e.key,
                        e.value.toString(),
                      ),
                      _buildDivider(),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.shade100);

  // ── Actions Card ──────────────────────────────────────────────────────────

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thao tác',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Download
              Expanded(
                child: _buildActionButton(
                  icon: Icons.download_outlined,
                  label: 'Tải xuống',
                  color: AppTheme.accentBlue,
                  filled: true,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang tải xuống...')),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Facebook
              Expanded(
                child: _buildActionButton(
                  icon: Icons.facebook_outlined,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UploadFacebookPostScreen(
                        prefilledVideoUrl: widget.video.videoUrl,
                        videoDisplayName: widget.video.displayName,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Copy URL
              Expanded(
                child: _buildActionButton(
                  icon: Icons.copy_outlined,
                  label: 'Copy URL',
                  color: Colors.grey.shade700,
                  filled: false,
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: widget.video.videoUrl),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã copy URL vào clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: filled
              ? null
              : BoxDecoration(
                  border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
