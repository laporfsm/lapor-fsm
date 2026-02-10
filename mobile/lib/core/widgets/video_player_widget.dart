import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String? url;
  final File? file;
  final bool autoPlay;
  final bool looping;

  const VideoPlayerWidget({
    super.key,
    this.url,
    this.file,
    this.autoPlay = false,
    this.looping = false,
  }) : assert(
         url != null || file != null,
         'Either url or file must be provided',
       );

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.file != null) {
        _videoPlayerController = VideoPlayerController.file(widget.file!);
      } else if (widget.url != null) {
        final url = _getSanitizedUrl(widget.url!);
        if (url.startsWith('http://') || url.startsWith('https://')) {
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(url),
          );
        } else {
          // Treat as local file path
          _videoPlayerController = VideoPlayerController.file(File(url));
        }
      }

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryColor,
          handleColor: AppTheme.primaryColor,
          backgroundColor: Colors.grey.withValues(alpha: 0.5),
          bufferedColor: Colors.white.withValues(alpha: 0.3),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 42),
                const SizedBox(height: 12),
                Text(errorMessage, style: const TextStyle(color: Colors.white)),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat video',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white30, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Chewie(controller: _chewieController!),
    );
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
}
