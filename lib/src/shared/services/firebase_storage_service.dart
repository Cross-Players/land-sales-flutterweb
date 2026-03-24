import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/api_constants.dart';

class LocalUploadService {
  final Dio _dio = Dio();

  /// Upload file to local server storage and return public URL
  ///
  /// [file] - PlatformFile from file_picker
  ///
  /// Returns: Download URL of uploaded file
  Future<String> uploadFile({required PlatformFile file}) async {
    try {
      // Validate file has bytes
      if (file.bytes == null) {
        throw Exception('File bytes not available');
      }

      print('📤 Uploading ${file.name} (${_formatFileSize(file.size)})...');

      // Create FormData
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      // Upload to backend API
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.data['success'] == true) {
        final url = response.data['data']['url'] as String;
        print('✅ Upload successful: $url');
        return url;
      } else {
        throw Exception('Upload failed: ${response.data['error']}');
      }
    } on DioException catch (e) {
      print('❌ Dio error uploading file: ${e.message}');
      if (e.response != null) {
        throw Exception(
          'Upload failed: ${e.response?.data['error'] ?? e.message}',
        );
      }
      rethrow;
    } catch (e) {
      print('❌ Error uploading file to server: $e');
      rethrow;
    }
  }

  /// Delete file from server storage
  Future<void> deleteFile(String fileId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/api/v1/upload/$fileId');
      print('✅ File deleted successfully');
    } catch (e) {
      print('❌ Error deleting file: $e');
      rethrow;
    }
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
