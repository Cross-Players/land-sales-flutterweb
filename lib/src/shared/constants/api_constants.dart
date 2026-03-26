import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Base URL - Development (Sử dụng 127.0.0.1 thay vì localhost cho Flutter Web)
  static String get baseUrl =>
      dotenv.env['BACKEND_API_URL'] ?? 'http://127.0.0.1:3001';

  // Video Templates API
  static String get videoTemplates => '$baseUrl/api/v1/video-templates';

  // Video Jobs API
  static String get videoJobs => '$baseUrl/api/v1/video-jobs';

  // Generated Videos API (lưu trong MongoDB)
  static String get generatedVideos => '$baseUrl/api/v1/generated-videos';

  /// Trigger n8n qua backend proxy — tránh CORS trên Flutter Web
  /// Usage: POST $videoJobTrigger(jobId)
  static String videoJobTrigger(String jobId) =>
      '$baseUrl/api/v1/video-jobs/$jobId/trigger';

  // n8n Webhook — GIỮ LẠI để tham khảo, KHÔNG dùng trực tiếp từ Flutter Web (CORS)
  static String get facebookAutoPost =>
      dotenv.env['N8N_WEBHOOK_URL'] ??
      'https://primary-production-29ad2.up.railway.app/webhook/facebook-auto-post';

  // OpenAI API Key - Load from environment variable
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // Private constructor to prevent instantiation
  ApiConstants._();
}
