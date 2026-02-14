import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mobile/core/widgets/video_player_widget.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Fullscreen modal for viewing media with swipe navigation
class MediaViewerModal extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const MediaViewerModal({
    super.key,
    required this.mediaUrls,
    this.initialIndex = 0,
  });

  @override
  State<MediaViewerModal> createState() => _MediaViewerModalState();
}

class _MediaViewerModalState extends State<MediaViewerModal> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // Image PageView with zoom
            PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final rawUrl = widget.mediaUrls[index];
                final url = _getSanitizedUrl(rawUrl);
                final isVideo =
                    url.toLowerCase().endsWith('.mp4') ||
                    url.toLowerCase().endsWith('.mov') ||
                    url.toLowerCase().endsWith('.avi') ||
                    url.toLowerCase().endsWith('.mkv');

                if (isVideo) {
                  return VideoPlayerWidget(url: url);
                }

                final isBase64 = url.startsWith('data:image');
                final isNetwork = url.startsWith('http');

                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: isBase64
                        ? _buildBase64Image(url)
                        : isNetwork
                        ? Image.network(
                            url,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                'Error loading media viewer image: $url - $error',
                              );
                              return _buildErrorWidget(context, url);
                            },
                          )
                        : Image.file(
                            File(url),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                'Error loading local media viewer image: $url - $error',
                              );
                              return _buildErrorWidget(context, url);
                            },
                          ),
                  ),
                );
              },
            ),

            // Top bar with close button and counter
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.x,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.mediaUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(48), // Balance the close button
                  ],
                ),
              ),
            ),

            // Bottom indicator dots
            if (widget.mediaUrls.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.mediaUrls.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBase64Image(String url) {
    try {
      final base64Content = url.split(',').last;
      return Image.memory(
        base64Decode(base64Content),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorWidget(context, "Mime: ${url.split(';').first}"),
      );
    } catch (e) {
      return _buildErrorWidget(context, "Base64 Error");
    }
  }

  String _getSanitizedUrl(String url) {
    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      final actualBaseUrl = ApiService.baseUrl;
      return url
          .replaceFirst('http://localhost:3000', actualBaseUrl)
          .replaceFirst('http://127.0.0.1:3000', actualBaseUrl);
    }
    return url;
  }

  Widget _buildErrorWidget(BuildContext context, String url) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.imageOff, color: Colors.white54, size: 64),
        const Gap(16),
        Text(
          'Gagal memuat media',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
        ),
        const Gap(8),
        Text(
          url,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white30,
            overflow: TextOverflow.ellipsis,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
