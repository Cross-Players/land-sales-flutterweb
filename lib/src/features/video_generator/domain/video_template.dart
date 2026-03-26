class VideoTemplate {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String tag;
  final bool isPopular;
  final String? category;
  final String? templateId; // UUID thực tế để gửi lên n8n
  final int? duration;
  final List<String>? features;
  final TemplateConfig? templateConfig; // Cấu hình đặc biệt cho mỗi template

  const VideoTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.tag,
    this.isPopular = false,
    this.category,
    this.templateId,
    this.duration,
    this.features,
    this.templateConfig,
  });

  // Factory constructor để parse JSON từ API
  factory VideoTemplate.fromJson(Map<String, dynamic> json) {
    return VideoTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      tag: json['tag'] as String,
      isPopular: json['isPopular'] as bool? ?? false,
      category: json['category'] as String?,
      templateId: json['templateId'] as String?,
      duration: json['duration'] as int?,
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : null,
      templateConfig: json['templateConfig'] != null
          ? TemplateConfig.fromJson(json['templateConfig'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'tag': tag,
      'isPopular': isPopular,
      'category': category,
      'templateId': templateId,
      'duration': duration,
      'features': features,
      'templateConfig': templateConfig?.toJson(),
    };
  }
}

/// Cấu hình đặc biệt cho mỗi template
class TemplateConfig {
  final String? dataStructure; // 'default', 'voice-over', etc.
  final bool? hasOverallVoice; // Template có overall voice không
  final String? aspectRatio; // '16:9', '9:16', '1:1'

  const TemplateConfig({
    this.dataStructure,
    this.hasOverallVoice,
    this.aspectRatio,
  });

  factory TemplateConfig.fromJson(Map<String, dynamic> json) {
    return TemplateConfig(
      dataStructure: json['dataStructure'] as String?,
      hasOverallVoice: json['hasOverallVoice'] as bool?,
      aspectRatio: json['aspectRatio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataStructure': dataStructure,
      'hasOverallVoice': hasOverallVoice,
      'aspectRatio': aspectRatio,
    };
  }
}
