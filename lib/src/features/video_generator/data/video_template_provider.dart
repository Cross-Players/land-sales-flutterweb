import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/dio_service.dart';
import 'video_template_service.dart';
import '../domain/video_template.dart';

/// Provider cho VideoTemplateService
///
/// Sử dụng dioProvider từ shared services
final videoTemplateServiceProvider = Provider<VideoTemplateService>((ref) {
  final dio = ref.watch(dioProvider);
  return VideoTemplateService(dio);
});

/// Provider lấy tất cả video templates
///
/// Sử dụng:
/// ```dart
/// final templatesAsync = ref.watch(videoTemplatesProvider);
/// templatesAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
///   data: (templates) => ListView(...),
/// )
/// ```
final videoTemplatesProvider = FutureProvider<List<VideoTemplate>>((ref) async {
  final service = ref.watch(videoTemplateServiceProvider);
  return await service.getAllTemplates();
});

/// Provider lấy templates phổ biến
///
/// Tự động filter các templates có isPopular = true
final popularTemplatesProvider = FutureProvider<List<VideoTemplate>>((
  ref,
) async {
  final service = ref.watch(videoTemplateServiceProvider);
  return await service.getPopularTemplates();
});

/// Provider lấy template theo ID
///
/// Sử dụng:
/// ```dart
/// final templateAsync = ref.watch(videoTemplateByIdProvider('property-showcase'));
/// ```
final videoTemplateByIdProvider = FutureProvider.family<VideoTemplate?, String>(
  (ref, id) async {
    final service = ref.watch(videoTemplateServiceProvider);
    return await service.getTemplateById(id);
  },
);

/// Provider lấy templates theo tag
///
/// Sử dụng:
/// ```dart
/// final modernTemplates = ref.watch(videoTemplatesByTagProvider('Hiện đại'));
/// ```
final videoTemplatesByTagProvider =
    FutureProvider.family<List<VideoTemplate>, String>((ref, tag) async {
      final service = ref.watch(videoTemplateServiceProvider);
      return await service.getAllTemplates(tag: tag);
    });

/// Provider tìm kiếm templates
///
/// Sử dụng:
/// ```dart
/// final searchResults = ref.watch(searchTemplatesProvider('luxury'));
/// ```
final searchTemplatesProvider =
    FutureProvider.family<List<VideoTemplate>, String>((ref, query) async {
      final service = ref.watch(videoTemplateServiceProvider);
      return await service.getAllTemplates(search: query);
    });

/// StateNotifier để refresh templates khi cần
class VideoTemplateNotifier
    extends StateNotifier<AsyncValue<List<VideoTemplate>>> {
  final VideoTemplateService _service;

  VideoTemplateNotifier(this._service) : super(const AsyncValue.loading()) {
    loadTemplates();
  }

  /// Load tất cả templates
  Future<void> loadTemplates() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getAllTemplates());
  }

  /// Refresh templates
  Future<void> refresh() async {
    await loadTemplates();
  }

  /// Filter templates theo tag
  Future<void> filterByTag(String tag) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getAllTemplates(tag: tag));
  }

  /// Search templates
  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.getAllTemplates(search: query),
    );
  }

  /// Load only popular templates
  Future<void> loadPopular() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getPopularTemplates());
  }
}

/// Provider cho VideoTemplateNotifier
///
/// Sử dụng khi cần control loading/refresh:
/// ```dart
/// final notifier = ref.read(videoTemplateNotifierProvider.notifier);
/// notifier.refresh();
/// notifier.filterByTag('Cao cấp');
/// ```
final videoTemplateNotifierProvider =
    StateNotifierProvider<
      VideoTemplateNotifier,
      AsyncValue<List<VideoTemplate>>
    >((ref) {
      final service = ref.watch(videoTemplateServiceProvider);
      return VideoTemplateNotifier(service);
    });
