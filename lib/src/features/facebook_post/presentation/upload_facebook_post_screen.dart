import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/services/chatgpt_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _Fanpage {
  final String id;
  final String name;
  const _Fanpage({required this.id, required this.name});
}

class _MediaItem {
  final String url;
  final String type; // 'image' | 'video'
  _MediaItem({required this.url, required this.type});
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class UploadFacebookPostScreen extends StatefulWidget {
  /// URL video đã generate — được pre-fill vào phần media
  final String? prefilledVideoUrl;
  final String? videoDisplayName;

  const UploadFacebookPostScreen({
    super.key,
    this.prefilledVideoUrl,
    this.videoDisplayName,
  });

  @override
  State<UploadFacebookPostScreen> createState() =>
      _UploadFacebookPostScreenState();
}

class _UploadFacebookPostScreenState extends State<UploadFacebookPostScreen> {
  // ── Fanpages ───────────────────────────────────────────────────────────────
  final List<_Fanpage> _fanpages = const [
    _Fanpage(id: 'page_1', name: 'LandSales Chính thức'),
    _Fanpage(id: 'page_2', name: 'Bất động sản miền Nam'),
    _Fanpage(id: 'page_3', name: 'Đất nền dự án HCM'),
  ];
  _Fanpage? _selectedPage;

  // ── Caption ────────────────────────────────────────────────────────────────
  final TextEditingController _captionCtrl = TextEditingController();

  // ── Media list ─────────────────────────────────────────────────────────────
  late final List<_MediaItem> _mediaItems;

  // ── Submit ─────────────────────────────────────────────────────────────────
  bool _isSubmitting = false;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _selectedPage = _fanpages.first;
    _mediaItems = [];
    if (widget.prefilledVideoUrl != null &&
        widget.prefilledVideoUrl!.isNotEmpty) {
      _mediaItems.add(
        _MediaItem(url: widget.prefilledVideoUrl!, type: 'video'),
      );
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  // ── Add media ──────────────────────────────────────────────────────────────

  Future<void> _addMedia(String type) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Thêm ${type == 'image' ? 'ảnh' : 'video'}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập URL ${type == 'image' ? 'ảnh' : 'video'}',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    if (confirmed == true && ctrl.text.trim().isNotEmpty) {
      setState(() {
        _mediaItems.add(_MediaItem(url: ctrl.text.trim(), type: type));
      });
    }
    ctrl.dispose();
  }

  void _removeMedia(int index) => setState(() => _mediaItems.removeAt(index));

  // ── AI Caption ────────────────────────────────────────────────────────────

  Future<void> _openAiCaptionDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AiCaptionDialog(
        pageName: _selectedPage?.name ?? '',
        videoName: widget.videoDisplayName ?? '',
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _captionCtrl.text = result);
    }
  }

  // ── Submit post ───────────────────────────────────────────────────────────

  Future<void> _submitPost() async {
    if (_selectedPage == null) {
      _showSnack('Vui lòng chọn Fanpage', Colors.orange);
      return;
    }
    if (_captionCtrl.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập caption', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'caption': _captionCtrl.text.trim(),
        'images': _mediaItems
            .where((m) => m.type == 'image')
            .map((m) => m.url)
            .toList(),
        'videos': _mediaItems
            .where((m) => m.type == 'video')
            .map((m) => m.url)
            .toList(),
        'useManualFacebookPost': true,
      };

      final resp = await _dio.post(
        ApiConstants.facebookAutoPost,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (mounted) {
        if (resp.statusCode != null && resp.statusCode! < 300) {
          _showSnack('✅ Đăng bài thành công!', Colors.green);
          Future.delayed(
            const Duration(seconds: 1),
            () => Navigator.of(context).pop(),
          );
        } else {
          _showSnack('Lỗi ${resp.statusCode}: ${resp.data}', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('❌ Lỗi kết nối: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

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
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFanpageSelector(),
                        const SizedBox(height: 20),
                        _buildCaptionCard(),
                        const SizedBox(height: 20),
                        _buildMediaCard(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 32),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1877F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.facebook, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đăng bài Facebook',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  widget.videoDisplayName ?? 'Bài đăng mới',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1877F2).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1877F2).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.facebook, size: 14, color: Color(0xFF1877F2)),
                const SizedBox(width: 6),
                Text(
                  'Dashboard / Chi tiết / Đăng bài',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF1877F2),
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

  // ── Fanpage Selector ──────────────────────────────────────────────────────

  Widget _buildFanpageSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              const Icon(
                Icons.pages_outlined,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Chọn Fanpage',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Bắt buộc',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _fanpages.map((page) {
              final selected = _selectedPage?.id == page.id;
              return InkWell(
                onTap: () => setState(() => _selectedPage = page),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1877F2).withOpacity(0.08)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1877F2)
                          : Colors.grey.shade200,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: selected
                            ? const Color(0xFF1877F2)
                            : Colors.grey.shade300,
                        child: Text(
                          page.name[0],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        page.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? const Color(0xFF1877F2)
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF1877F2),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Caption Card ──────────────────────────────────────────────────────────

  Widget _buildCaptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Caption',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // AI Generate button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openAiCaptionDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'AI Viết Caption',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _captionCtrl,
            maxLines: 6,
            style: const TextStyle(fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText:
                  'Nhập nội dung caption cho bài đăng...\n\nHoặc nhấn "AI Viết Caption" để AI tạo tự động.',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppTheme.accentBlue,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  // ── Media Card ────────────────────────────────────────────────────────────

  Widget _buildMediaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              const Icon(
                Icons.perm_media_outlined,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Media',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_mediaItems.length} file',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Media list
          if (_mediaItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.shade200,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 36,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có media nào',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _mediaItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isVideo = item.type == 'video';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isVideo
                          ? Colors.purple.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isVideo
                            ? Colors.purple.shade100
                            : Colors.blue.shade100,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isVideo
                                ? Colors.purple.shade100
                                : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isVideo ? Icons.videocam : Icons.image,
                            size: 18,
                            color: isVideo
                                ? Colors.purple.shade600
                                : Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVideo ? 'Video' : 'Ảnh',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isVideo
                                      ? Colors.purple.shade600
                                      : Colors.blue.shade600,
                                ),
                              ),
                              Text(
                                item.url,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: () => _removeMedia(i),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          tooltip: 'Xoá',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // Add buttons
          Row(
            children: [
              _buildAddMediaButton(
                icon: Icons.add_photo_alternate_outlined,
                label: 'Thêm ảnh',
                color: Colors.blue.shade600,
                onTap: () => _addMedia('image'),
              ),
              const SizedBox(width: 10),
              _buildAddMediaButton(
                icon: Icons.video_call_outlined,
                label: 'Thêm video',
                color: Colors.purple.shade600,
                onTap: () => _addMedia('video'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isSubmitting ? null : _submitPost,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1877F2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_outlined, size: 18),
        label: Text(
          _isSubmitting ? 'Đang đăng bài...' : 'Đăng bài lên Facebook',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Caption Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _AiCaptionDialog extends StatefulWidget {
  final String pageName;
  final String videoName;

  const _AiCaptionDialog({required this.pageName, required this.videoName});

  @override
  State<_AiCaptionDialog> createState() => _AiCaptionDialogState();
}

class _AiCaptionDialogState extends State<_AiCaptionDialog> {
  // ── API Key ────────────────────────────────────────────────────────────────
  final _apiKeyCtrl = TextEditingController();
  bool _showApiKey = false;

  // ── Form fields ────────────────────────────────────────────────────────────
  final _projectNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _highlightsCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _selectedTone = 'Chuyên nghiệp';

  final List<String> _tones = [
    'Chuyên nghiệp',
    'Thân thiện',
    'Thu hút',
    'Khẩn cấp',
    'Sang trọng',
  ];

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isGenerating = false;
  String _streamingCaption = ''; // tích luỹ token từ stream
  String? _errorMsg;
  CancelToken? _cancelToken;

  @override
  void initState() {
    _apiKeyCtrl.text = ApiConstants.openAiApiKey;
    super.initState();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _apiKeyCtrl.dispose();
    _projectNameCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _highlightsCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  // ── Generate ───────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    final apiKey = _apiKeyCtrl.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _errorMsg = 'Vui lòng nhập Groq API Key');
      return;
    }
    if (_projectNameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Vui lòng nhập tên dự án');
      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() {
      _isGenerating = true;
      _errorMsg = null;
      _streamingCaption = '';
    });

    try {
      final service = ChatGptService(apiKey: apiKey);
      final prompt = buildRealEstatePrompt(
        projectName: _projectNameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        price: _priceCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        highlights: _highlightsCtrl.text.trim(),
        contact: _contactCtrl.text.trim(),
        tone: _selectedTone,
        pageName: widget.pageName,
      );

      await service.generateCaption(
        prompt: prompt,
        cancelToken: _cancelToken,
        onToken: (token) {
          if (mounted) {
            setState(() => _streamingCaption += token);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    } on ChatGptException catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMsg = e.message;
        });
      }
    } catch (e) {
      if (mounted && !(_cancelToken?.isCancelled ?? false)) {
        setState(() {
          _isGenerating = false;
          _errorMsg = 'Lỗi không xác định: $e';
        });
      }
    }
  }

  void _stopGenerate() {
    _cancelToken?.cancel();
    setState(() {
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenW * 0.04,
        vertical: screenH * 0.04,
      ),
      child: Container(
        width: screenW * 0.92,
        height: screenH * 0.88,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDialogHeader(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LEFT: Form ────────────────────────────────────────────
                  Expanded(flex: 5, child: _buildFormPanel()),
                  // Divider
                  VerticalDivider(width: 1, color: Colors.grey.shade200),
                  // ── RIGHT: Result ─────────────────────────────────────────
                  Expanded(flex: 5, child: _buildResultPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Viết Caption',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Nhập thông tin dự án để AI tạo caption tối ưu',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.grey.shade500),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ── Form Panel ────────────────────────────────────────────────────────────

  Widget _buildFormPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── API Key Section ──────────────────────────────────────────────
          _sectionLabel('Groq API Key'),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: !_showApiKey,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'gsk_...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              prefixIcon: Icon(
                Icons.key_outlined,
                size: 16,
                color: Colors.grey.shade400,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _showApiKey
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () => setState(() => _showApiKey = !_showApiKey),
                    tooltip: _showApiKey ? 'Ẩn key' : 'Hiện key',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF6C63FF),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.info_outline, size: 11, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                'Key chỉ lưu trong phiên này, không được ghi ra ngoài.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Project Info ─────────────────────────────────────────────────
          _sectionLabel('Thông tin cơ bản'),
          const SizedBox(height: 12),
          _buildField(
            controller: _projectNameCtrl,
            label: 'Tên dự án *',
            hint: 'VD: Vinhomes Grand Park',
            icon: Icons.apartment_outlined,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _locationCtrl,
            label: 'Vị trí / Địa chỉ',
            hint: 'VD: Quận 9, TP. HCM',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _priceCtrl,
                  label: 'Giá',
                  hint: 'VD: 2.5 tỷ',
                  icon: Icons.monetization_on_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _areaCtrl,
                  label: 'Diện tích',
                  hint: 'VD: 100m²',
                  icon: Icons.square_foot_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('Điểm nổi bật'),
          const SizedBox(height: 12),
          _buildField(
            controller: _highlightsCtrl,
            label: 'Điểm nổi bật (mỗi dòng 1 ý)',
            hint:
                'VD:\nGần trường học quốc tế\nPháp lý rõ ràng\nTiện ích đầy đủ',
            icon: Icons.star_outline,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _contactCtrl,
            label: 'Thông tin liên hệ',
            hint: 'VD: 0901 234 567 - Anh Nam',
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 20),
          _sectionLabel('Phong cách viết'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tones.map((tone) {
              final selected = _selectedTone == tone;
              return ChoiceChip(
                label: Text(tone),
                selected: selected,
                onSelected: (_) => setState(() => _selectedTone = tone),
                selectedColor: const Color(0xFF6C63FF).withOpacity(0.15),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? const Color(0xFF6C63FF)
                      : Colors.grey.shade600,
                ),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF6C63FF)
                      : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          if (_errorMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 15,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isGenerating ? _stopGenerate : _generate,
              style: FilledButton.styleFrom(
                backgroundColor: _isGenerating
                    ? Colors.red.shade400
                    : const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isGenerating
                  ? const Icon(Icons.stop_circle_outlined, size: 16)
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                _isGenerating ? 'Dừng lại' : 'Tạo Caption với AI',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result Panel ──────────────────────────────────────────────────────────

  Widget _buildResultPanel() {
    final hasContent = _streamingCaption.isNotEmpty;
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.preview_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                'Kết quả',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_isGenerating) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Đang viết...',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF6C63FF),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Content
        Expanded(
          child: !hasContent && !_isGenerating
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 48,
                        color: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Caption sẽ hiển thị ở đây',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Điền thông tin bên trái và nhấn "Tạo Caption"',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          _streamingCaption,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        // Blinking cursor khi đang stream
                        if (_isGenerating) const _BlinkingCursor(),
                      ],
                    ),
                  ),
                ),
        ),

        // Action buttons — chỉ show khi có kết quả & không đang generate
        if (hasContent && !_isGenerating)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Thử lại
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Thử lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Dùng caption này
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_streamingCaption),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Dùng caption này'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, size: 16, color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Blinking cursor widget — hiển thị khi stream đang chạy
// ─────────────────────────────────────────────────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 16,
        margin: const EdgeInsets.only(left: 1, top: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
