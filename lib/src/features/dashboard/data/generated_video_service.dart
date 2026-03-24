import 'package:dio/dio.dart';
import '../../../shared/constants/api_constants.dart';
import '../domain/generated_video.dart';

class GeneratedVideoService {
  final Dio _dio;

  GeneratedVideoService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  /// Lấy danh sách video đã generate, sort mới nhất trước.
  Future<List<GeneratedVideo>> fetchVideos({int limit = 50}) async {
    final response = await _dio.get(
      ApiConstants.generatedVideos,
      queryParameters: {'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['videos'] as List<dynamic>? ?? [];
    return list
        .map((e) => GeneratedVideo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Xoá một video theo id MongoDB.
  Future<void> deleteVideo(String id) async {
    await _dio.delete('${ApiConstants.generatedVideos}/$id');
  }
}
