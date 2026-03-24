class ApiConstants {
  // Base URL - Development (Sử dụng 127.0.0.1 thay vì localhost cho Flutter Web)
  static const String baseUrl = 'http://127.0.0.1:3001';

  // Video Templates API
  static const String videoTemplates = '$baseUrl/api/v1/video-templates';

  // Video Jobs API
  static const String videoJobs = '$baseUrl/api/v1/video-jobs';

  // Generated Videos API (lưu trong MongoDB)
  static const String generatedVideos = '$baseUrl/api/v1/generated-videos';

  /// Trigger n8n qua backend proxy — tránh CORS trên Flutter Web
  /// Usage: POST $videoJobTrigger(jobId)
  static String videoJobTrigger(String jobId) =>
      '$baseUrl/api/v1/video-jobs/$jobId/trigger';

  // n8n Webhook — GIỮ LẠI để tham khảo, KHÔNG dùng trực tiếp từ Flutter Web (CORS)
  static const String facebookAutoPost =
      'https://primary-production-29ad2.up.railway.app/webhook/facebook-auto-post';

  static const String openAiApiKey =
      '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';

  // Private constructor to prevent instantiation
  ApiConstants._();
}
