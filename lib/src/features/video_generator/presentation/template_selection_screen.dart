
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../domain/video_template.dart';
import '../data/video_template_provider.dart';
import '../../../shared/theme/app_theme.dart';

class TemplateSelectionScreen extends ConsumerStatefulWidget {
  final Function(VideoTemplate) onTemplateSelected;

  const TemplateSelectionScreen({super.key, required this.onTemplateSelected});

  @override
  ConsumerState<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState
    extends ConsumerState<TemplateSelectionScreen> {
  // ─── Video Preview State ───────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;
  bool _isVideoError = false;
  VideoTemplate? _previewingTemplate;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // ─── Video Helpers ─────────────────────────────────────────────────────────
  Future<void> _openPreview(VideoTemplate template) async {
    if (_previewingTemplate?.id == template.id) return;

    await _videoController?.dispose();

    setState(() {
      _previewingTemplate = template;
      _isVideoInitializing = true;
      _isVideoError = false;
      _videoController = null;
    });

    try {
      final controller = VideoPlayerController.asset(
        'assets/videos/template_1_demo.mp4',
      );
      await controller.initialize();
      controller.setLooping(true);
      controller.play();

      if (mounted) {
        setState(() {
          _videoController = controller;
          _isVideoInitializing = false;
        });
      } else {
        controller.dispose();
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

  void _closePreview() {
    _videoController?.dispose();
    setState(() {
      _previewingTemplate = null;
      _videoController = null;
      _isVideoInitializing = false;
      _isVideoError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(videoTemplatesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left panel: Template grid ───────────────────────────────────
            Expanded(
              flex: _previewingTemplate != null ? 3 : 1,
              child: _buildGridPanel(templatesAsync),
            ),

            // ── Right panel: Video preview ──────────────────────────────────
            if (_previewingTemplate != null)
              Expanded(
                flex: 2,
                child: _buildVideoPreviewPanel(_previewingTemplate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridPanel(AsyncValue<List<VideoTemplate>> templatesAsync) {
    return templatesAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang tải templates...',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),

      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải templates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(videoTemplatesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      data: (templates) {
        if (templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có template nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo Video Bất Động Sản Chuyên Nghiệp',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chọn template phù hợp, upload ảnh/video, thêm caption và voice - AI sẽ tự động ghép thành video hoàn chỉnh trong vài giây',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(videoTemplatesProvider),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Làm mới',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Grid header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn Template',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${templates.length} mẫu có sẵn',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Templates Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  mainAxisExtent: 330,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) =>
                    _buildTemplateCard(context, templates[index]),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Template Card ─────────────────────────────────────────────────────────
  Widget _buildTemplateCard(BuildContext context, VideoTemplate template) {
    final bool isPreviewing = _previewingTemplate?.id == template.id;

    return InkWell(
      onTap: () => widget.onTemplateSelected(template),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPreviewing
              ? Border.all(color: AppTheme.accentBlue, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with tag ─────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Image.network(
                      template.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Tag badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      template.tag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                // Popular badge
                if (template.isPopular)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            // ── Content ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // ── Action buttons ─────────────────────────────────────
                  Row(
                    children: [
                      // Xem trước
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => isPreviewing
                              ? _closePreview()
                              : _openPreview(template),
                          icon: Icon(
                            isPreviewing
                                ? Icons.close
                                : Icons.play_circle_outline,
                            size: 16,
                          ),
                          label: Text(
                            isPreviewing ? 'Đóng' : 'Xem trước',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isPreviewing
                                ? Colors.red.shade400
                                : AppTheme.accentBlue,
                            side: BorderSide(
                              color: isPreviewing
                                  ? Colors.red.shade300
                                  : AppTheme.accentBlue,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sử dụng
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => widget.onTemplateSelected(template),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Sử dụng',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Video Preview Panel ───────────────────────────────────────────────────
  Widget _buildVideoPreviewPanel(VideoTemplate template) {
    final bool isReady =
        !_isVideoInitializing &&
        !_isVideoError &&
        _videoController != null &&
        _videoController!.value.isInitialized;

    return Container(
      color: AppTheme.primaryDark,
      child: Column(
        children: [
          // ── Panel header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  size: 18,
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _closePreview,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white70,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Đóng xem trước',
                ),
              ],
            ),
          ),

          // ── Video area ────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Video player container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _isVideoInitializing
                            // Loading
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Đang tải video...',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              )
                            : _isVideoError || _videoController == null
                            // Error / no file
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.video_library_outlined,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Template Preview',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      template.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Thêm file template_1_demo.mp4\nvào assets/videos/ để xem demo',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.4),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            // Playing
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio:
                                        _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _videoController!.value.isPlaying
                                            ? _videoController!.pause()
                                            : _videoController!.play();
                                      });
                                    },
                                    child: AnimatedOpacity(
                                      opacity: _videoController!.value.isPlaying
                                          ? 0.0
                                          : 1.0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Controls ──────────────────────────────────────────────
                  if (isReady) ...[
                    VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      padding: EdgeInsets.zero,
                      colors: const VideoProgressColors(
                        playedColor: AppTheme.accentBlue,
                        bufferedColor: Color(0x401E88E5),
                        backgroundColor: Color(0x1A000000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Play / Pause
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _videoController!.value.isPlaying
                                  ? _videoController!.pause()
                                  : _videoController!.play();
                            });
                          },
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 32,
                            color: AppTheme.accentBlue,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 4),
                        // Duration
                        ValueListenableBuilder(
                          valueListenable: _videoController!,
                          builder: (_, VideoPlayerValue value, __) {
                            final pos = value.position;
                            final dur = value.duration;
                            String fmt(Duration d) =>
                                '${d.inMinutes.toString().padLeft(2, '0')}:'
                                '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
                            return Text(
                              '${fmt(pos)} / ${fmt(dur)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        // Mute
                        ValueListenableBuilder(
                          valueListenable: _videoController!,
                          builder: (_, VideoPlayerValue value, __) {
                            final isMuted = value.volume == 0;
                            return IconButton(
                              onPressed: () {
                                setState(() {
                                  _videoController!.setVolume(
                                    isMuted ? 1.0 : 0.0,
                                  );
                                });
                              },
                              icon: Icon(
                                isMuted ? Icons.volume_off : Icons.volume_up,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                              padding: EdgeInsets.zero,
                            );
                          },
                        ),
                        // Replay
                        IconButton(
                          onPressed: () {
                            _videoController!.seekTo(Duration.zero);
                            _videoController!.play();
                          },
                          icon: const Icon(
                            Icons.replay,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppTheme.accentBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo template "${template.title}"',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Use template button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _closePreview();
                        widget.onTemplateSelected(template);
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Sử dụng template này'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
