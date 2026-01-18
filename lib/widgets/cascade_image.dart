import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'file_loader_io.dart' if (dart.library.html) 'file_loader_web.dart';

/// A widget that tries to load images from a list of URLs sequentially.
/// If one fails, it tries the next. If all fail, it shows a placeholder.
///
/// This version downloads bytes manually and checks Magic Numbers to ensure
/// the data is a valid image before passing it to the Flutter engine.
/// This prevents 'ImageDescriptor.encoded' crashes caused by "Soft 404s" (HTML).
class CascadeImage extends StatefulWidget {
  final List<String> imageUrls;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final VoidCallback? onGenerateImage;
  final VoidCallback? onUploadImage;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const CascadeImage({
    super.key,
    required this.imageUrls,
    this.errorBuilder,
    this.onGenerateImage,
    this.onUploadImage,
    this.fit,
    this.width,
    this.height,
  });

  @override
  State<CascadeImage> createState() => _CascadeImageState();
}

class _CascadeImageState extends State<CascadeImage> {
  int _currentIndex = 0;
  bool _hasError = false;
  bool _isLoading = true;
  Uint8List? _validImageData;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CascadeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrls != oldWidget.imageUrls) {
      _currentIndex = 0;
      _hasError = false;
      _isLoading = true;
      _validImageData = null;
      _loadImage();
    }
  }

  bool _isImage(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // GIF: 47 49 46
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;

    // WebP: RIFF .... WEBP
    if (bytes.length > 12) {
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        if (bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    if (_currentIndex >= widget.imageUrls.length) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final url = widget.imageUrls[_currentIndex];

      // Check if it's a local file path (skip on web)
      if (!kIsWeb &&
          (url.startsWith('/') ||
              url.contains(':\\') ||
              url.startsWith('file://'))) {
        // Load from local file system
        final bytes = await loadFromLocalFile(url);

        if (bytes == null) {
          _retryNext();
          return;
        }

        if (!_isImage(bytes)) {
          _retryNext();
          return;
        }

        if (mounted) {
          setState(() {
            _validImageData = bytes;
            _isLoading = false;
          });
        }
        return;
      }

      // Remote URL - use HTTP
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode != 200) {
        _retryNext();
        return;
      }

      final bytes = response.bodyBytes;

      if (!_isImage(bytes)) {
        _retryNext();
        return;
      }

      if (mounted) {
        setState(() {
          _validImageData = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      _retryNext();
    }
  }

  void _retryNext() {
    if (mounted) {
      setState(() {
        _currentIndex++;
      });
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || widget.imageUrls.isEmpty) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(
          context,
          Exception('All images failed'),
          null,
        );
      }
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.withOpacity(0.1),
        child: (widget.onGenerateImage != null || widget.onUploadImage != null)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onGenerateImage != null)
                      IconButton(
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.blue,
                          size: 16,
                        ),
                        onPressed: widget.onGenerateImage,
                        tooltip: 'Generate with AI',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 16,
                      ),
                    if (widget.onUploadImage != null)
                      IconButton(
                        icon: const Icon(
                          Icons.upload_file,
                          color: Colors.green,
                          size: 16,
                        ),
                        onPressed: widget.onUploadImage,
                        tooltip: 'Upload Image',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 16,
                      ),
                  ],
                ),
              )
            : const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    if (_isLoading || _validImageData == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Render confirmed valid bytes
    return Image.memory(
      _validImageData!,
      key: ValueKey('$_currentIndex'), // Key change forces rebuild on new image
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) {
        // Fallback should ideally never happen if magic bytes passed,
        // but just in case of weird internal decoding error:
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.withOpacity(0.1),
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}
