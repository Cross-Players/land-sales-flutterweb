import 'package:flutter/material.dart';

/// Frame data cho template Voice Over
/// Chỉ có Video-Frame, URL và Caption, không có voice riêng cho từng frame
class VoiceOverFrameData {
  final String type = 'Video-Frame'; // Chỉ có Video-Frame
  TextEditingController captionController;
  TextEditingController urlController;

  VoiceOverFrameData()
    : captionController = TextEditingController(),
      urlController = TextEditingController();

  void dispose() {
    captionController.dispose();
    urlController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'copy': type,
      'V-Caption': captionController.text,
      'V-Src': urlController.text,
    };
  }
}
