import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/generated_video_provider.dart';
import '../domain/generated_video.dart';
import 'video_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(generatedVideosProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats Cards ────────────────────────────────────────────────────
          videosAsync.when(
            data: (videos) => _buildStatsRow(videos.length),
            loading: () => _buildStatsRow(0),
            error: (_, __) => _buildStatsRow(0),
          ),
          const SizedBox(height: 32),

          // ── Header ─────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Video đã tạo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(generatedVideosProvider),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Table ──────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTableHeader(),
                videosAsync.when(
                  data: (videos) => videos.isEmpty
                      ? _buildEmptyState()
                      : _buildVideoList(videos, ref),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(64),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => _buildErrorState(err.toString()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow(int total) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tổng video',
            total.toString(),
            Icons.video_library_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Hôm nay',
            '–',
            Icons.today_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Đang xử lý',
            '–',
            Icons.pending_outlined,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Lỗi', '–', Icons.error_outline, Colors.red),
        ),
      ],
    );
  }

  // ── Table Header ───────────────────────────────────────────────────────────

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 80), // thumbnail
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Video',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Template',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Ngày tạo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Thao tác',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Video list ─────────────────────────────────────────────────────────────

  Widget _buildVideoList(List<GeneratedVideo> videos, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videos.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (context, index) =>
          _VideoRow(video: videos[index], ref: ref),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(64),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có video nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Video sẽ xuất hiện ở đây sau khi generate xong.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          Text(
            'Không thể tải dữ liệu',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Kiểm tra kết nối MongoDB và backend.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Stat card ──────────────────────────────────────────────────────────────

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Video Row widget ───────────────────────────────────────────────────────────

class _VideoRow extends StatelessWidget {
  final GeneratedVideo video;
  final WidgetRef ref;

  const _VideoRow({required this.video, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(video.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: InkWell(
        onTap: () => _openDetail(context, video),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 80,
                height: 52,
                color: Colors.grey.shade100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + URL
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video.videoUrl,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Template
            Expanded(
              flex: 2,
              child: Text(
                video.templateId ?? '–',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                dateStr,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            // Actions
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  // Xem chi tiết
                  IconButton(
                    tooltip: 'Xem chi tiết',
                    icon: const Icon(Icons.open_in_new, size: 18),
                    onPressed: () => _openDetail(context, video),
                  ),
                  // Xoá
                  IconButton(
                    tooltip: 'Xoá',
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, GeneratedVideo video) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => VideoDetailScreen(video: video)));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá video?'),
        content: const Text(
          'Video sẽ bị xoá khỏi danh sách. Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(generatedVideoServiceProvider)
                    .deleteVideo(video.id);
                ref.invalidate(generatedVideosProvider);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Xoá thất bại')));
                }
              }
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }
}
