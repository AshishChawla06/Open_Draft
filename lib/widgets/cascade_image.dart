import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A widget that tries to load images from a list of URLs sequentially.
/// If one fails, it tries the next. If all fail, it shows a placeholder.
///
/// This version downloads bytes manually and checks Magic Numbers to ensure
/// the data is a valid image before passing it to the Flutter engine.
/// This prevents 'ImageDescriptor.encoded' crashes caused by "Soft 404s" (HTML).
class CascadeImage extends StatefulWidget {
  final List<String> imageUrls;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const CascadeImage({
    super.key,
    required this.imageUrls,
    this.errorBuilder,
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

      // Manual Download & Inspection
      final response = await http.get(
        Uri.parse(url),
        // Add a browser-like User-Agent to satisfy strict CDNs/Cloudflare
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode != 200) {
        // Silently retry next (don't throw to avoid debugger pause)
        _retryNext();
        return;
      }

      final bytes = response.bodyBytes;

      // Verify Magic Byte Signature (is it actually an image?)
      if (!_isImage(bytes)) {
        // Silently retry next (don't throw to avoid debugger pause)
        _retryNext();
        return;
      }

      if (mounted) {
        // Precache the bytes logic is automatic with Image.memory,
        // but we can "pre-decode" if we really want to be safe,
        // however Image.memory is generally safer than NetworkImage as bytes are local.
        setState(() {
          _validImageData = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Download failed or invalid signature -> Try next
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
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
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
