import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../domain/voice_over_frame_data.dart';
import '../domain/video_template.dart';
import '../data/video_job_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/services/firebase_storage_service.dart';
import 'video_waiting_screen.dart';

class VoiceOverGeneratorScreen extends ConsumerStatefulWidget {
  final VideoTemplate selectedTemplate;
  final VoidCallback onBack;

  const VoiceOverGeneratorScreen({
    super.key,
    required this.selectedTemplate,
    required this.onBack,
  });

  @override
  ConsumerState<VoiceOverGeneratorScreen> createState() =>
      _VoiceOverGeneratorScreenState();
}

class _VoiceOverGeneratorScreenState
    extends ConsumerState<VoiceOverGeneratorScreen> {
  final List<VoiceOverFrameData> _frames = [VoiceOverFrameData()];
  final TextEditingController _overallVoiceController = TextEditingController();
  final Dio _dio = Dio();
  final LocalUploadService _uploadService = LocalUploadService();
  bool _isLoading = false;

  // Map to store selected file info for each frame
  final Map<int, PlatformFile?> _selectedFiles = {};

  // Map to store upload progress for each frame
  final Map<int, double> _uploadProgress = {};

  @override
  void dispose() {
    _overallVoiceController.dispose();
    for (var frame in _frames) {
      frame.dispose();
    }
    super.dispose();
  }

  void _addFrame() {
    setState(() => _frames.add(VoiceOverFrameData()));
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
          _uploadProgress[frameIndex] = 0.0;
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
              duration: const Duration(seconds: 60),
            ),
          );
        }

        // Upload to server via backend API
        try {
          final downloadUrl = await _uploadService.uploadFile(file: file);

          // Update URL controller with server URL
          setState(() {
            _frames[frameIndex].urlController.text = downloadUrl;
            _uploadProgress[frameIndex] = 1.0;
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
    // Validate overall voice
    if (_overallVoiceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền nội dung AI Voice Over'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate frames - ít nhất 1 frame phải có URL
    bool hasValidFrame = false;
    for (var frame in _frames) {
      if (frame.urlController.text.trim().isNotEmpty) {
        hasValidFrame = true;
        break;
      }
    }

    if (!hasValidFrame) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng upload hoặc nhập URL cho ít nhất 1 frame'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Bước 1: Tạo job trên backend → nhận jobId
      final jobService = ref.read(videoJobServiceProvider);
      final jobId = await jobService.createJob(widget.selectedTemplate.id);

      // Bước 2: Trigger n8n qua backend proxy
      // Cấu trúc data đặc biệt cho Voice Over template
      final jsonData = _frames.map((frame) => frame.toJson()).toList();

      await _dio.post(
        ApiConstants.videoJobTrigger(jobId),
        data: {
          'templateId':
              widget.selectedTemplate.templateId ?? widget.selectedTemplate.id,
          'video': jsonData,
          'Overall-Voice': {'source': _overallVoiceController.text.trim()},
          'useAiVideo': true,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // Bước 3: Navigate sang màn hình chờ
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoWaitingScreen(
              jobId: jobId,
              selectedTemplate: widget.selectedTemplate,
              frames: [], // Voice over không dùng FrameData
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
              child: Row(
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
                        Text(
                          widget.selectedTemplate.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.selectedTemplate.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Voice Section
                    _buildOverallVoiceSection(),
                    const SizedBox(height: 32),

                    // Frames Section
                    _buildFramesSection(),
                    const SizedBox(height: 24),

                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallVoiceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.record_voice_over,
                  color: AppTheme.accentBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Voice Over (xuyên suốt video)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Điền nội dung bạn muốn AI đọc lên trong toàn bộ video',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _overallVoiceController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'Ví dụ: Căn hộ cao cấp tại trung tâm thành phố với đầy đủ tiện nghi hiện đại...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.accentBlue),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFramesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ảnh/Video cho từng Frame',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addFrame,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm Frame'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _frames.length,
          itemBuilder: (context, index) => _buildFrameCard(index),
        ),
      ],
    );
  }

  Widget _buildFrameCard(int index) {
    final frame = _frames[index];
    final selectedFile = _selectedFiles[index];
    final uploadProgress = _uploadProgress[index] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frame Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frame ${index + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (_frames.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeFrame(index),
                    tooltip: 'Xóa frame',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // File Upload Button
            InkWell(
              onTap: () => _pickFile(index),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedFile != null
                          ? Icons.check_circle
                          : Icons.cloud_upload,
                      color: selectedFile != null
                          ? Colors.green
                          : AppTheme.accentBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedFile?.name ?? 'Tải lên ảnh/video từ máy',
                            style: TextStyle(
                              fontWeight: selectedFile != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (selectedFile != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatFileSize(selectedFile.size),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (uploadProgress > 0 && uploadProgress < 1)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Divider với text "HOẶC"
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'HOẶC',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),

            // URL Input
            TextField(
              controller: frame.urlController,
              decoration: InputDecoration(
                labelText: 'Hoặc nhập URL ảnh/video',
                hintText: 'https://example.com/video.mp4',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link),
                helperText: 'URL trực tiếp đến file ảnh hoặc video',
              ),
              onChanged: (value) {
                // Nếu user nhập URL thì xóa selected file
                if (value.isNotEmpty && _selectedFiles[index] != null) {
                  setState(() {
                    _selectedFiles.remove(index);
                    _uploadProgress.remove(index);
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Caption (optional)
            TextField(
              controller: frame.captionController,
              decoration: InputDecoration(
                labelText: 'Caption (tùy chọn)',
                hintText: 'Mô tả ngắn cho frame này...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.text_fields),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Tạo Video',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
