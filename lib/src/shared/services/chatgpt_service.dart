import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

/// Service giao tiếp với Groq API (tương thích OpenAI).
/// Hỗ trợ streaming (Server-Sent Events) — mỗi token mới sẽ gọi [onToken].
/// Đăng ký API key miễn phí tại: https://console.groq.com
class ChatGptService {
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile'; // free, nhanh, thông minh

  final String apiKey;
  ChatGptService({required this.apiKey});

  /// Stream từng token về qua [onToken].
  /// Trả về toàn bộ caption khi hoàn thành.
  /// Throws [ChatGptException] nếu có lỗi.
  Future<String> generateCaption({
    required String prompt,
    void Function(String token)? onToken,
    CancelToken? cancelToken,
  }) async {
    final dio = Dio();
    final buffer = StringBuffer();

    try {
      final response = await dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
        data: {
          'model': _model,
          'stream': true,
          'temperature': 0.8,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Bạn là chuyên gia marketing bất động sản Việt Nam. '
                  'Hãy viết caption hấp dẫn, có emoji phù hợp, hashtag ở cuối. '
                  'Viết bằng tiếng Việt, giọng văn tự nhiên, không sáo rỗng.',
            },
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      final stream = response.data.stream as Stream<List<int>>;
      final completer = Completer<String>();
      String remainder = '';

      stream.listen(
        (chunk) {
          final decoded = utf8.decode(chunk);
          final lines = (remainder + decoded).split('\n');
          remainder = lines.removeLast(); // giữ dòng chưa hoàn chỉnh

          for (final line in lines) {
            if (!line.startsWith('data: ')) continue;
            final data = line.substring(6).trim();
            if (data == '[DONE]') continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List?;
              if (choices == null || choices.isEmpty) continue;

              final delta =
                  (choices[0] as Map<String, dynamic>)['delta']
                      as Map<String, dynamic>?;
              final token = delta?['content'] as String?;
              if (token != null && token.isNotEmpty) {
                buffer.write(token);
                onToken?.call(token);
              }
            } catch (_) {
              // bỏ qua dòng parse lỗi
            }
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.completeError(ChatGptException(_friendlyError(e)));
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(buffer.toString());
          }
        },
        cancelOnError: true,
      );

      return completer.future;
    } on DioException catch (e) {
      throw ChatGptException(_friendlyError(e));
    }
  }

  String _friendlyError(dynamic e) {  
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 401) {
        return 'API Key không hợp lệ. Kiểm tra lại key tại console.groq.com';
      }
      if (status == 429) {
        return 'Đã vượt giới hạn free tier. Thử lại sau ít phút.';
      }
      if (status == 500) return 'Groq đang có sự cố. Thử lại sau ít phút.';
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến Groq. Kiểm tra mạng.';
      }
    }
    return 'Lỗi: $e';
  }
}

class ChatGptException implements Exception {
  final String message;
  ChatGptException(this.message);
  @override
  String toString() => message;
}

/// Tạo prompt từ thông tin dự án bất động sản
String buildRealEstatePrompt({
  required String projectName,
  required String location,
  required String price,
  required String area,
  required String highlights,
  required String contact,
  required String tone,
  required String pageName,
}) {
  final toneDesc =
      {
        'Chuyên nghiệp': 'chuyên nghiệp, đáng tin cậy',
        'Thân thiện': 'thân thiện, gần gũi',
        'Thu hút': 'cuốn hút, kêu gọi hành động mạnh',
        'Khẩn cấp': 'tạo sự khan hiếm và cấp bách',
        'Sang trọng': 'sang trọng, đẳng cấp, premium',
      }[tone] ??
      tone;

  return '''
Viết caption Facebook đăng bài cho dự án bất động sản với giọng văn $toneDesc.

Thông tin dự án:
- Tên dự án: $projectName
${location.isNotEmpty ? '- Vị trí: $location' : ''}
${price.isNotEmpty ? '- Giá: $price' : ''}
${area.isNotEmpty ? '- Diện tích: $area' : ''}
${highlights.isNotEmpty ? '- Điểm nổi bật:\n$highlights' : ''}
${contact.isNotEmpty ? '- Liên hệ: $contact' : ''}
${pageName.isNotEmpty ? '- Fanpage: $pageName' : ''}

Yêu cầu:
1. Caption hấp dẫn, có cảm xúc, kêu gọi hành động
2. Dùng emoji phù hợp
3. Có hashtag liên quan ở cuối (6-10 hashtag)
4. Độ dài vừa phải (không quá dài)
5. Viết thuần tiếng Việt
''';
}
