import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'media_viewer_modal.dart';

/// A gallery widget that displays media thumbnails and opens fullscreen viewer on tap
class MediaGalleryWidget extends StatelessWidget {
  final List<String> mediaUrls;
  final int maxVisibleItems;

  const MediaGalleryWidget({
    super.key,
    required this.mediaUrls,
    this.maxVisibleItems = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    final displayCount = mediaUrls.length > maxVisibleItems
        ? maxVisibleItems
        : mediaUrls.length;
    final extraCount = mediaUrls.length - maxVisibleItems;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.image, size: 18, color: AppTheme.primaryColor),
              const Gap(8),
              const Text(
                'Bukti Laporan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${mediaUrls.length} media',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              final isLastItem = index == maxVisibleItems - 1 && extraCount > 0;
              return _buildThumbnail(
                context,
                index,
                isLastItem ? extraCount : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, int index, int? extraCount) {
    return GestureDetector(
      onTap: () => _openViewer(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              mediaUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: Icon(LucideIcons.imageOff, color: Colors.grey.shade400),
              ),
            ),
            // Overlay for extra count
            if (extraCount != null)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, int initialIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          MediaViewerModal(mediaUrls: mediaUrls, initialIndex: initialIndex),
    );
  }
}
