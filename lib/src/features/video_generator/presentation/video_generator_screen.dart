import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../domain/frame_data.dart';
import '../domain/video_template.dart';
import '../data/video_job_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/services/firebase_storage_service.dart';
import '../../dashboard/domain/generated_video.dart';
import '../../dashboard/presentation/video_detail_screen.dart';
import 'video_waiting_screen.dart';

class VideoGeneratorScreen extends ConsumerStatefulWidget {
  final VideoTemplate selectedTemplate;
  final VoidCallback onBack;

  const VideoGeneratorScreen({
    super.key,
    required this.selectedTemplate,
    required this.onBack,
  });

  @override
  ConsumerState<VideoGeneratorScreen> createState() =>
      _VideoGeneratorScreenState();
}

class _VideoGeneratorScreenState extends ConsumerState<VideoGeneratorScreen> {
  final List<FrameData> _frames = [FrameData()];
  final Dio _dio = Dio();
  final LocalUploadService _uploadService = LocalUploadService();
  bool _isLoading = false;
  bool _useMockData = false; // Option to use mock data

  // Map to store selected file info for each frame
  final Map<int, PlatformFile?> _selectedFiles = {};

  // Map to store upload progress for each frame
  final Map<int, double> _uploadProgress = {};

  // Video Player Controller
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = true;
  final bool _isVideoError = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    try {
      setState(() => _isVideoInitializing = true);

      _videoController = VideoPlayerController.asset(
        'assets/videos/template_1_demo.mp4',
      );

      await _videoController!.initialize();

      if (mounted) {
        setState(() => _isVideoInitializing = false);
      }
    } catch (e) {
      print('❌ Error initializing video: $e');
      if (mounted) {
        setState(() => _isVideoInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    for (var frame in _frames) {
      frame.dispose();
    }
    super.dispose();
  }

  void _addFrame() {
    setState(() => _frames.add(FrameData()));
  }

  void _removeFrame(int index) {
    if (_frames.length > 1) {
      setState(() {
        _frames[index].dispose();
        _frames.removeAt(index);
        _selectedFiles.remove(index);
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _pickFile(int frameIndex) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFiles[frameIndex] = file;
          _uploadProgress[frameIndex] = 0.0; // Start progress

          // Update frame type based on file extension
          final extension = file.extension?.toLowerCase();
          if (extension == 'mp4' || extension == 'mov' || extension == 'avi') {
            _frames[frameIndex].type = 'Video-Frame';
          } else {
            _frames[frameIndex].type = 'Image-Frame';
          }
        });

        // Show uploading message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Đang upload ${file.name} lên server...'),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 60), // Longer timeout
            ),
          );
        }

        // Upload to server via backend API
        try {
          final downloadUrl = await _uploadService.uploadFile(file: file);

          // Update URL controller with server URL
          setState(() {
            _frames[frameIndex].urlController.text = downloadUrl;
            _uploadProgress[frameIndex] = 1.0; // Complete
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✅ Upload thành công: ${file.name}'),
                          const SizedBox(height: 4),
                          const Text(
                            'File đã được lưu vào server',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (uploadError) {
          // Upload failed
          setState(() {
            _selectedFiles.remove(frameIndex);
            _uploadProgress.remove(frameIndex);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('❌ Lỗi upload lên server'),
                    const SizedBox(height: 4),
                    Text(
                      uploadError.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 10),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitData() async {
    setState(() => _isLoading = true);

    try {
      // ── Mock mode: bỏ qua API, xem thẳng result screen ──────────────────
      if (_useMockData) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _navigateToResult(null);
        }
        return;
      }

      // ── Bước 1: Tạo job trên backend → nhận jobId ────────────────────────
      final jobService = ref.read(videoJobServiceProvider);
      final jobId = await jobService.createJob(widget.selectedTemplate.id);

      // ── Bước 2: Trigger n8n qua backend proxy (tránh CORS Flutter Web) ───
      final jsonData = _frames.map((frame) => frame.toJson()).toList();

      await _dio.post(
        ApiConstants.videoJobTrigger(jobId),
        data: {
          'templateId':
              widget.selectedTemplate.templateId ?? widget.selectedTemplate.id,
          'video': jsonData,
          'useAiVideo': true,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // ── Bước 3: Navigate sang màn hình chờ — lắng nghe SSE ───────────────
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoWaitingScreen(
              jobId: jobId,
              selectedTemplate: widget.selectedTemplate,
              frames: _frames,
              selectedFiles: Map.from(_selectedFiles),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToResult(String? videoUrl) {
    final generatedVideo = GeneratedVideo(
      id: '',
      jobId: '',
      templateId: widget.selectedTemplate.id,
      videoUrl: videoUrl ?? '',
      meta: {'title': widget.selectedTemplate.title},
      createdAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoDetailScreen(video: generatedVideo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header với template info và back button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: widget.onBack,
                        tooltip: 'Quay lại chọn template',
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.selectedTemplate.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.selectedTemplate.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.selectedTemplate.tag,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.selectedTemplate.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mock Data Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _useMockData
                          ? Colors.orange.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _useMockData
                            ? Colors.orange.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _useMockData ? Icons.science : Icons.cloud_upload,
                          size: 20,
                          color: _useMockData
                              ? Colors.orange.shade700
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _useMockData
                                    ? 'Chế độ Preview'
                                    : 'Chế độ Production',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _useMockData
                                      ? Colors.orange.shade900
                                      : Colors.grey.shade900,
                                ),
                              ),
                              Text(
                                _useMockData
                                    ? 'Xem trước không cần gọi API'
                                    : 'Gửi dữ liệu lên server',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _useMockData
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _useMockData,
                          onChanged: (value) {
                            setState(() => _useMockData = value);
                          },
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content - Chia làm 2 cột
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Form (Flex 2)
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Slides Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Slides (${_frames.length})',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addFrame,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Thêm Slide'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Slides List
                          ...List.generate(_frames.length, (index) {
                            return _buildSlideCard(index);
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Right Column - Video Preview (Flex 1)
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.play_circle_outline,
                                    color: AppTheme.accentBlue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Preview Template',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Video của bạn sẽ tương tự như thế này',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // Video Preview Area
                          Expanded(child: _buildVideoPreview()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${_frames.where((f) => f.captionController.text.isNotEmpty || f.voiceController.text.isNotEmpty || f.urlController.text.isNotEmpty).length} / ${_frames.length} slides có nội dung',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitData,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 20),
                      label: Text(_isLoading ? 'Đang xử lý...' : 'Tạo Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideCard(int index) {
    final frame = _frames[index];
    final hasContent =
        frame.captionController.text.isNotEmpty ||
        frame.voiceController.text.isNotEmpty ||
        frame.urlController.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasContent
              ? AppTheme.accentBlue.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slide Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Slide ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_frames.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.red,
                    onPressed: () => _removeFrame(index),
                    tooltip: 'Xóa slide',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh/Video Upload
                const Text(
                  'Ảnh/Video',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickFile(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedFiles[index] != null
                            ? AppTheme.accentBlue
                            : Colors.grey.shade300,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _selectedFiles[index] != null
                          ? AppTheme.accentBlue.withOpacity(0.05)
                          : Colors.grey.shade50,
                    ),
                    child: Center(
                      child: _selectedFiles[index] != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _frames[index].type == 'Video-Frame'
                                      ? Icons.videocam
                                      : Icons.image,
                                  size: 40,
                                  color: AppTheme.accentBlue,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    _selectedFiles[index]!.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.accentBlue,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFileSize(_selectedFiles[index]!.size),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhấn để chọn file khác',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chọn ảnh hoặc video',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'JPG, PNG, MP4, MOV, AVI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: frame.urlController,
                  decoration: InputDecoration(
                    hintText: frame.type == 'Video-Frame'
                        ? 'hoặc nhập Video URL'
                        : 'hoặc nhập Image URL',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Caption
                const Text(
                  'Caption (Text hiển thị)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: frame.captionController,
                  decoration: InputDecoration(
                    hintText: 'Nhập nội dung caption cho slide này...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Voice
                const Text(
                  'Voice (Giọng nói AI trong frame)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: frame.voiceController,
                  decoration: InputDecoration(
                    hintText:
                        'Nhập nội dung giọng đọc (AI sẽ tự động chuyển thành giọng nói)...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Video Preview Widget
  Widget _buildVideoPreview() {
    final bool isReady =
        !_isVideoInitializing &&
        !_isVideoError &&
        _videoController != null &&
        _videoController!.value.isInitialized;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Video Player Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isVideoInitializing
                    // --- Loading state ---
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Đang tải video...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    : _isVideoError || _videoController == null
                    // --- Error / no video state ---
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_library_outlined,
                              size: 72,
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
                              widget.selectedTemplate.title,
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
                    // --- Video playing state ---
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          // Video
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                          // Overlay tap to play/pause
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
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                decoration: BoxDecoration(
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

          // Progress Bar + Controls
          if (isReady) ...[
            // Progress bar
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

            // Control Row
            Row(
              children: [
                // Play / Pause button
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
                    size: 36,
                    color: AppTheme.accentBlue,
                  ),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),

                // Duration text
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

                // Mute button
                ValueListenableBuilder(
                  valueListenable: _videoController!,
                  builder: (_, VideoPlayerValue value, __) {
                    final isMuted = value.volume == 0;
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _videoController!.setVolume(isMuted ? 1.0 : 0.0);
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

                // Replay button
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
            // Info card (shown when no video)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
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
                      'Demo template "${widget.selectedTemplate.title}"',
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
        ],
      ),
    );
  }
}
