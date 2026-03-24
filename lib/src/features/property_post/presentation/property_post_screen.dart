import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:landsale_flutterwebsite/src/shared/theme/app_theme.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/services/chatgpt_service.dart';

class PropertyPostScreen extends StatefulWidget {
  const PropertyPostScreen({super.key});

  @override
  State<PropertyPostScreen> createState() => _PropertyPostScreenState();
}

class _PropertyPostScreenState extends State<PropertyPostScreen> {
  // Form fields
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _propertyTypeController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();
  final TextEditingController _highlightsController = TextEditingController();
  final TextEditingController _targetAudienceController =
      TextEditingController();

  // ── API Key ────────────────────────────────────────────────────────────────
  final TextEditingController _apiKeyCtrl = TextEditingController();
  bool _showApiKey = false;

  bool _isGenerating = false;
  String _streamingResult = ''; // accumulate streaming tokens
  CancelToken? _cancelToken;
  String? _errorMsg;
  String? _copiedField;

  // parsed results (filled after stream done)
  String? _generatedTitle;
  String? _generatedDescription;
  List<String> _generatedHashtags = [];

  String _selectedPropertyType = '';
  final List<String> _propertyTypes = [
    'Căn hộ',
    'Chung cư',
    'Nhà phố',
    'Biệt thự',
    'Penthouse',
    'Shophouse',
    'Đất nền',
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl.text = ApiConstants.openAiApiKey;
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _projectNameController.dispose();
    _propertyTypeController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _highlightsController.dispose();
    _targetAudienceController.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _generateContent() async {
    final apiKey = _apiKeyCtrl.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _errorMsg = 'Vui lòng nhập Groq API Key');
      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() {
      _isGenerating = true;
      _streamingResult = '';
      _errorMsg = null;
      _generatedTitle = null;
      _generatedDescription = null;
      _generatedHashtags = [];
    });

    final projectName = _projectNameController.text.trim();
    final area = _areaController.text.trim();
    final price = _priceController.text.trim();
    final location = _locationController.text.trim();
    final bedrooms = _bedroomsController.text.trim();
    final bathrooms = _bathroomsController.text.trim();
    final highlights = _highlightsController.text.trim();
    final targetAudience = _targetAudienceController.text.trim();

    final prompt =
        '''
Hãy tạo nội dung marketing bất động sản tiếng Việt gồm 3 phần rõ ràng theo đúng format sau:

===TIÊU ĐỀ===
(Một dòng tiêu đề hấp dẫn, có emoji)

===MÔ TẢ===
(Mô tả chi tiết 5-8 câu, có emoji, thông tin cụ thể, kêu gọi hành động)

===HASHTAG===
(Chỉ liệt kê các hashtag ngăn cách bởi dấu cách, không có # ở đầu, ví dụ: BatDongSan NhaDep HCM)

Thông tin bất động sản:
${projectName.isNotEmpty ? '- Tên dự án: $projectName' : ''}
- Loại: $_selectedPropertyType
${area.isNotEmpty ? '- Diện tích: ${area}m²' : ''}
${price.isNotEmpty ? '- Giá: $price' : ''}
${location.isNotEmpty ? '- Vị trí: $location' : ''}
${bedrooms.isNotEmpty ? '- Phòng ngủ: $bedrooms' : ''}
${bathrooms.isNotEmpty ? '- Phòng tắm: $bathrooms' : ''}
${highlights.isNotEmpty ? '- Đặc điểm: $highlights' : ''}
${targetAudience.isNotEmpty ? '- Đối tượng: $targetAudience' : ''}
''';

    try {
      final service = ChatGptService(apiKey: apiKey);
      await service.generateCaption(
        prompt: prompt,
        cancelToken: _cancelToken,
        onToken: (token) {
          if (mounted) setState(() => _streamingResult += token);
        },
      );

      // Parse kết quả sau khi stream xong
      if (mounted) {
        _parseResult(_streamingResult);
        setState(() => _isGenerating = false);
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

  void _parseResult(String raw) {
    // Parse ===TIÊU ĐỀ=== / ===MÔ TẢ=== / ===HASHTAG===
    final titleMatch = RegExp(
      r'===TIÊU ĐỀ===([\s\S]*?)(?:===|$)',
      caseSensitive: false,
    ).firstMatch(raw);
    final descMatch = RegExp(
      r'===MÔ TẢ===([\s\S]*?)(?:===|$)',
      caseSensitive: false,
    ).firstMatch(raw);
    final hashMatch = RegExp(
      r'===HASHTAG===([\s\S]*?)(?:===|$)',
      caseSensitive: false,
    ).firstMatch(raw);

    _generatedTitle = titleMatch?.group(1)?.trim();
    _generatedDescription = descMatch?.group(1)?.trim();

    final hashRaw = hashMatch?.group(1)?.trim() ?? '';
    _generatedHashtags = hashRaw
        .split(RegExp(r'[\s,]+'))
        .map((h) => h.replaceAll('#', '').trim())
        .where((h) => h.isNotEmpty)
        .toList();
  }

  void _stopGenerate() {
    _cancelToken?.cancel();
    if (mounted) {
      _parseResult(_streamingResult);
      setState(() => _isGenerating = false);
    }
  }

  void _copyToClipboard(String text, String field) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedField = field);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedField = null);
    });
  }

  bool get _isFormValid =>
      _selectedPropertyType.isNotEmpty &&
      _areaController.text.isNotEmpty &&
      _priceController.text.isNotEmpty &&
      _locationController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Row(
          children: [
            // Left Column - Input Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderBanner(),
                    const SizedBox(height: 24),
                    _buildInputForm(),
                  ],
                ),
              ),
            ),

            // Right Column - Results
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: _buildResultsSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Copywriting Tool',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập thông tin bất động sản, AI sẽ tự động tạo tiêu đề, mô tả và hashtag chuyên nghiệp',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông Tin Bất Động Sản',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),

          // Project Name
          _buildLabel('Tên dự án'),
          const SizedBox(height: 8),
          TextField(
            controller: _projectNameController,
            decoration: _buildInputDecoration(
              'VD: Vinhomes Grand Park, Masteri Thảo Điền',
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Property Type Dropdown
          _buildLabel('Loại Bất Động Sản *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPropertyType.isEmpty ? null : _selectedPropertyType,
            decoration: _buildInputDecoration('-- Chọn loại --'),
            items: _propertyTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedPropertyType = value ?? '');
            },
          ),
          const SizedBox(height: 16),

          // Area and Price Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Diện tích (m²) *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _areaController,
                      decoration: _buildInputDecoration('VD: 80'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Giá *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      decoration: _buildInputDecoration('VD: 3.5 tỷ'),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location
          _buildLabel('Vị trí *'),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            decoration: _buildInputDecoration('VD: Quận 2, TP.HCM'),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Bedrooms and Bathrooms Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Số phòng ngủ'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bedroomsController,
                      decoration: _buildInputDecoration('VD: 3'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Số phòng tắm'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bathroomsController,
                      decoration: _buildInputDecoration('VD: 2'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Highlights
          _buildLabel('Đặc điểm nổi bật'),
          const SizedBox(height: 8),
          TextField(
            controller: _highlightsController,
            decoration: _buildInputDecoration(
              'VD: View sông đẹp, nội thất cao cấp, gần trường học...',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          // Target Audience
          _buildLabel('Đối tượng khách hàng'),
          const SizedBox(height: 8),
          TextField(
            controller: _targetAudienceController,
            decoration: _buildInputDecoration(
              'VD: Gia đình trẻ, Nhà đầu tư...',
            ),
          ),
          const SizedBox(height: 24),

          // ── Groq API Key ──────────────────────────────────────────────────
          _buildLabel('Groq API Key'),
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
              suffixIcon: IconButton(
                icon: Icon(
                  _showApiKey
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                onPressed: () => setState(() => _showApiKey = !_showApiKey),
              ),
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
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đăng ký miễn phí tại console.groq.com',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Generate / Stop Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isFormValid && !_isGenerating
                      ? _generateContent
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isGenerating)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.auto_awesome, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _isGenerating ? 'Đang tạo...' : 'Tạo Nội Dung AI',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isGenerating) ...[
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _stopGenerate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.stop_rounded, size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    // Đang stream — show live text ngay cả khi chưa parse xong
    if (_isGenerating && _streamingResult.isNotEmpty) {
      return _buildStreamingState();
    }
    if (_isGenerating) {
      return _buildGeneratingState();
    }
    if (_generatedTitle != null) {
      return _buildGeneratedResults();
    }
    return _buildEmptyState();
  }

  Widget _buildStreamingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI đang viết...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _streamingResult,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,

            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI Đang Sáng Tạo...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đang tạo nội dung tối ưu cho bạn',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.grey.shade400,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sẵn Sàng Tạo Nội Dung',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Điền thông tin bất động sản bên trái và nhấn "Tạo Nội Dung AI" để bắt đầu',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedResults() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Title Card
          _buildResultCard(
            title: '📝 Tiêu Đề',
            content: _generatedTitle!,
            fieldName: 'title',
          ),
          const SizedBox(height: 16),

          // Description Card
          _buildResultCard(
            title: '📄 Mô Tả Chi Tiết',
            content: _generatedDescription!,
            fieldName: 'description',
          ),
          const SizedBox(height: 16),

          // Hashtags Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '# Hashtags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    _buildCopyButton(
                      _generatedHashtags.map((tag) => '#$tag').join(' '),
                      'hashtags',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _generatedHashtags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentBlue.withOpacity(0.1),
                            AppTheme.primaryLight.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Regenerate Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _generateContent,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.accentBlue, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: AppTheme.accentBlue),
                  SizedBox(width: 8),
                  Text(
                    'Tạo Lại Nội Dung',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
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

  Widget _buildResultCard({
    required String title,
    required String content,
    required String fieldName,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              _buildCopyButton(content, fieldName),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(String text, String fieldName) {
    final isCopied = _copiedField == fieldName;
    return ElevatedButton.icon(
      onPressed: () => _copyToClipboard(text, fieldName),
      icon: Icon(isCopied ? Icons.check_circle : Icons.content_copy, size: 16),
      label: Text(isCopied ? 'Đã copy' : 'Copy'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
        foregroundColor: AppTheme.accentBlue,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
