import 'package:flutter/material.dart';

class FrameData {
  String type;
  TextEditingController captionController;
  TextEditingController voiceController;
  TextEditingController urlController;

  FrameData({this.type = 'Video-Frame'})
    : captionController = TextEditingController(),
      voiceController = TextEditingController(),
      urlController = TextEditingController();

  void dispose() {
    captionController.dispose();
    voiceController.dispose();
    urlController.dispose();
  }

  Map<String, dynamic> toJson() {
    if (type == 'Video-Frame') {
      return {
        'copy': type,
        'V-Caption': captionController.text,
        'V-Voice': voiceController.text,
        'V-Src': urlController.text,
      };
    } else {
      return {
        'copy': type,
        'I-Caption': captionController.text,
        'I-Voice': voiceController.text,
        'I-Src': urlController.text,
      };
    }
  }
}
