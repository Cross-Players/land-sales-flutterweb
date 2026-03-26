import 'package:flutter/material.dart';
import '../domain/video_template.dart';
import 'template_selection_screen.dart';
import 'video_generator_screen.dart';
import 'voice_over_generator_screen.dart';

class VideoGeneratorWrapper extends StatefulWidget {
  const VideoGeneratorWrapper({super.key});

  @override
  State<VideoGeneratorWrapper> createState() => _VideoGeneratorWrapperState();
}

class _VideoGeneratorWrapperState extends State<VideoGeneratorWrapper> {
  VideoTemplate? _selectedTemplate;

  void _onTemplateSelected(VideoTemplate template) {
    setState(() {
      _selectedTemplate = template;
    });
  }

  void _onBackToTemplates() {
    setState(() {
      _selectedTemplate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTemplate == null) {
      return TemplateSelectionScreen(onTemplateSelected: _onTemplateSelected);
    }

    // Kiểm tra cấu trúc data của template để chọn màn hình phù hợp
    final dataStructure =
        _selectedTemplate!.templateConfig?.dataStructure ?? 'default';

    if (dataStructure == 'voice-over') {
      // Template Voice Over - sử dụng màn hình riêng
      return VoiceOverGeneratorScreen(
        selectedTemplate: _selectedTemplate!,
        onBack: _onBackToTemplates,
      );
    }

    // Template mặc định
    return VideoGeneratorScreen(
      selectedTemplate: _selectedTemplate!,
      onBack: _onBackToTemplates,
    );
  }
}
