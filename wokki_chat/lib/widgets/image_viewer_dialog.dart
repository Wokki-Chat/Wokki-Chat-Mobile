import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ImageViewerDialog extends StatelessWidget {
  final String imageUrl;
  final String imageName;

  const ImageViewerDialog({
    super.key,
    required this.imageUrl,
    required this.imageName,
  });

  static Future<void> show(
    BuildContext context,
    String imageUrl,
    String imageName,
  ) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => ImageViewerDialog(
        imageUrl: imageUrl,
        imageName: imageName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PhotoView(
                    imageProvider: NetworkImage(imageUrl),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 5,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF895BF5)),
                      ),
                    ),
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.error, color: Colors.red, size: 64),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF303030),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF404040)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ImageOption(
                    icon: Icons.download,
                    label: 'Save image',
                    onTap: () => _downloadImage(context),
                  ),
                  _ImageOption(
                    icon: Icons.open_in_new,
                    label: 'Open in new tab',
                    onTap: () => _openInBrowser(context),
                  ),
                  _ImageOption(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () => _shareImage(context),
                  ),
                  _ImageOption(
                    icon: Icons.close,
                    label: 'Close',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$imageName';
      
      await dio.download(imageUrl, filePath);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to $filePath'),
            backgroundColor: const Color(0xFF22946E),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image'),
            backgroundColor: Color(0xFF9C2121),
          ),
        );
      }
    }
  }

  Future<void> _openInBrowser(BuildContext context) async {
    try {
      final url = Uri.parse(imageUrl);
      await Share.share(url.toString());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open image'),
            backgroundColor: Color(0xFF9C2121),
          ),
        );
      }
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$imageName';
      
      await dio.download(imageUrl, filePath);
      
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share image'),
            backgroundColor: Color(0xFF9C2121),
          ),
        );
      }
    }
  }
}

class _ImageOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ImageOption> createState() => _ImageOptionState();
}

class _ImageOptionState extends State<_ImageOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF404040) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}