import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

/// Diálogo fullscreen de galeria de fotos com swipe horizontal.
class PhotoGalleryDialog extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoGalleryDialog({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> photos,
    int initialIndex = 0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => PhotoGalleryDialog(photos: photos, initialIndex: initialIndex),
    );
  }

  @override
  State<PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<PhotoGalleryDialog> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: Image.asset(widget.photos[i], fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
<<<<<<< HEAD
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
=======
                icon: Icon(LucideIcons.x, color: Colors.white, size: 28),
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_current + 1} / ${widget.photos.length}',
<<<<<<< HEAD
                  style: const TextStyle(color: Colors.white, fontSize: 14),
=======
                  style: TextStyle(color: Colors.white, fontSize: 14),
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
