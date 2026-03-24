import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../../../shared/constants/api_constants.dart';
import '../domain/video_job.dart';

/// Service xử lý tạo job và lắng nghe trạng thái job.
/// - Flutter Web: dùng polling mỗi 2s (Dio stream không hỗ trợ Web)
/// - Native: dùng SSE stream
class VideoJobService {
  final Dio _dio;

  VideoJobService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  // ─── Tạo job ───────────────────────────────────────────────────────────────

  Future<String> createJob(String templateId) async {
    final response = await _dio.post(
      ApiConstants.videoJobs,
      data: {'templateId': templateId},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data['jobId'] as String;
  }

  // ─── Watch job ─────────────────────────────────────────────────────────────

  /// Flutter Web → polling mỗi 2s
  /// Native     → SSE stream
  Stream<VideoJob> watchJob(String jobId) {
    if (kIsWeb) {
      return _pollJob(jobId);
    } else {
      return _watchJobSse(jobId);
    }
  }

  // ─── Get status 1 lần ─────────────────────────────────────────────────────

  Future<VideoJob> getJobStatus(String jobId) async {
    final response = await _dio.get('${ApiConstants.videoJobs}/$jobId');
    return VideoJob.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Polling (Web) ────────────────────────────────────────────────────────

  Stream<VideoJob> _pollJob(String jobId) async* {
    const interval = Duration(seconds: 2);
    VideoJobStatus? lastStatus;

    while (true) {
      try {
        final job = await getJobStatus(jobId);

        // Chỉ emit khi status thay đổi
        if (job.status != lastStatus) {
          lastStatus = job.status;
          yield job;
        }

        if (job.isFinished) return;
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 404) {
          yield VideoJob(
            jobId: jobId,
            status: VideoJobStatus.error,
            errorMessage: 'Job not found',
          );
          return;
        }
        // Lỗi mạng tạm thời — thử lại
      }

      await Future.delayed(interval);
    }
  }

  // ─── SSE (Native) ─────────────────────────────────────────────────────────

  Stream<VideoJob> _watchJobSse(String jobId) {
    final controller = StreamController<VideoJob>.broadcast();
    _connectSse(jobId, controller);
    return controller.stream;
  }

  Future<void> _connectSse(
    String jobId,
    StreamController<VideoJob> controller,
  ) async {
    try {
      final response = await _dio.get<ResponseBody>(
        '${ApiConstants.videoJobs}/$jobId/stream',
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
          receiveTimeout: Duration.zero,
        ),
      );

      final stream = response.data!.stream;
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        buffer.write(text);

        while (buffer.toString().contains('\n\n')) {
          final content = buffer.toString();
          final splitIndex = content.indexOf('\n\n');
          final eventBlock = content.substring(0, splitIndex);
          buffer.clear();
          buffer.write(content.substring(splitIndex + 2));

          if (eventBlock.trimLeft().startsWith(':')) continue;

          final dataLine = eventBlock
              .split('\n')
              .where((l) => l.startsWith('data:'))
              .join();
          if (dataLine.isEmpty) continue;

          final jsonStr = dataLine.substring('data:'.length).trim();
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final job = VideoJob.fromJson(json);
            controller.add(job);
            if (job.isFinished) {
              await controller.close();
              return;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    }
  }
}
