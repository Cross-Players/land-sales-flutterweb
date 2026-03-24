import 'package:dio/dio.dart';
import '../domain/video_template.dart';
import '../../../shared/constants/api_constants.dart';

/// Service class để gọi API Video Templates
class VideoTemplateService {
  final Dio _dio;

  VideoTemplateService(this._dio);

  /// Lấy tất cả video templates
  ///
  /// Tham số:
  /// - [tag]: Lọc theo tag (VD: "Hiện đại", "Cao cấp")
  /// - [isPopular]: Chỉ lấy templates phổ biến
  /// - [search]: Tìm kiếm theo từ khóa
  Future<List<VideoTemplate>> getAllTemplates({
    String? tag,
    bool? isPopular,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tag != null) queryParams['tag'] = tag;
      if (isPopular != null) queryParams['isPopular'] = isPopular.toString();
      if (search != null) queryParams['search'] = search;

      final response = await _dio.get(
        ApiConstants.videoTemplates,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        final List data = response.data['data'] as List;
        return data.map((json) => VideoTemplate.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ DioException in getAllTemplates: ${e.message}');
      throw Exception('Không thể kết nối đến server: ${e.message}');
    } catch (e) {
      print('❌ Error in getAllTemplates: $e');
      throw Exception('Lỗi khi tải danh sách templates: $e');
    }
  }

  /// Lấy template theo ID
  Future<VideoTemplate?> getTemplateById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.videoTemplates}/$id');

      if (response.data['success'] == true) {
        return VideoTemplate.fromJson(response.data['data']);
      }

      return null;
    } on DioException catch (e) {
      print('❌ DioException in getTemplateById: ${e.message}');
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Không thể kết nối đến server: ${e.message}');
    } catch (e) {
      print('❌ Error in getTemplateById: $e');
      return null;
    }
  }

  /// Lấy danh sách templates phổ biến
  Future<List<VideoTemplate>> getPopularTemplates() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.videoTemplates}/popular/list',
      );

      if (response.data['success'] == true) {
        final List data = response.data['data'] as List;
        return data.map((json) => VideoTemplate.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ DioException in getPopularTemplates: ${e.message}');
      throw Exception('Không thể kết nối đến server: ${e.message}');
    } catch (e) {
      print('❌ Error in getPopularTemplates: $e');
      throw Exception('Lỗi khi tải templates phổ biến: $e');
    }
  }

  /// Lấy templates theo category
  Future<List<VideoTemplate>> getTemplatesByCategory(String category) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.videoTemplates}/category/$category',
      );

      if (response.data['success'] == true) {
        final List data = response.data['data'] as List;
        return data.map((json) => VideoTemplate.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ DioException in getTemplatesByCategory: ${e.message}');
      throw Exception('Không thể kết nối đến server: ${e.message}');
    } catch (e) {
      print('❌ Error in getTemplatesByCategory: $e');
      throw Exception('Lỗi khi tải templates theo category: $e');
    }
  }
}
