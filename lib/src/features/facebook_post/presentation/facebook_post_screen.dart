import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/constants/api_constants.dart';

class FacebookPostScreen extends StatefulWidget {
  const FacebookPostScreen({super.key});

  @override
  State<FacebookPostScreen> createState() => _FacebookPostScreenState();
}

class _FacebookPostScreenState extends State<FacebookPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final List<TextEditingController> _imageControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _videoControllers = [
    TextEditingController(),
  ];
  final Dio _dio = Dio();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _captionController.dispose();
    for (var c in _imageControllers) {
      c.dispose();
    }
    for (var c in _videoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addImage() =>
      setState(() => _imageControllers.add(TextEditingController()));
  void _removeImage(int i) {
    if (_imageControllers.length <= 1) return;
    setState(() {
      _imageControllers[i].dispose();
      _imageControllers.removeAt(i);
    });
  }

  void _addVideo() =>
      setState(() => _videoControllers.add(TextEditingController()));
  void _removeVideo(int i) {
    if (_videoControllers.length <= 1) return;
    setState(() {
      _videoControllers[i].dispose();
      _videoControllers.removeAt(i);
    });
  }

  Future<void> _submitFbPost() async {
    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'caption': _captionController.text.trim(),
        'images': _imageControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'videos': _videoControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'useManualFacebookPost': true,
      };

      print('📤 Sending request to: ${ApiConstants.facebookAutoPost}');
      print('📦 Payload: $payload');

      final resp = await _dio.post(
        ApiConstants.facebookAutoPost,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('✅ Response status: ${resp.statusCode}');
      print('📥 Response data: ${resp.data}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi thành công: ${resp.statusCode}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Log chi tiết để debug
      print('❌ Facebook Post Error:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      String errorMessage = 'Lỗi: $e';

      if (e is DioException) {
        print('Status code: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
        print('Request data: ${e.requestOptions.data}');

        // Custom error messages
        if (e.type == DioExceptionType.connectionError) {
          errorMessage =
              '🌐 Lỗi kết nối:\n'
              '• Kiểm tra URL: ${ApiConstants.facebookAutoPost}\n'
              '• Server có đang chạy không?\n'
              '• Có vấn đề CORS (nếu chạy web)?\n'
              '• Thử test với Postman/curl';
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = '⏱️ Timeout: Server không phản hồi sau 30s';
        } else if (e.type == DioExceptionType.badResponse) {
          errorMessage =
              '❌ Server trả về lỗi:\n'
              'Status: ${e.response?.statusCode}\n'
              'Data: ${e.response?.data}';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'Images',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._imageControllers.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: e.value,
                                decoration: InputDecoration(
                                  labelText: 'Image URL ${e.key + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeImage(e.key),
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addImage,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Image'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Videos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._videoControllers.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: e.value,
                                decoration: InputDecoration(
                                  labelText: 'Video URL ${e.key + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeVideo(e.key),
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addVideo,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Video'),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFbPost,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
