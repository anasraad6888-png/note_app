import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/canvas_models.dart';
import '../../controllers/canvas_controller.dart';

class InteractiveImageWidget extends StatelessWidget {
  final PageImage image;
  final int pageIndex;
  final CanvasController canvasCtrl;
  final bool readOnly;

  const InteractiveImageWidget({
    super.key,
    required this.image,
    required this.pageIndex,
    required this.canvasCtrl,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      return SizedBox(
        width: image.size.width,
        height: image.size.height,
        child: File(image.path).existsSync()
            ? Image.file(
                File(image.path),
                width: image.size.width,
                height: image.size.height,
                fit: BoxFit.cover,
                errorBuilder: (context, _, _) =>
                    canvasCtrl.missingImagePlaceholder(image),
              )
            : canvasCtrl.missingImagePlaceholder(image),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onPanUpdate: (canvasCtrl.isPanZoomMode || canvasCtrl.isTextMode)
              ? null
              : (details) => canvasCtrl.updateImagePosition(image, details.delta),
          child: File(image.path).existsSync()
              ? Image.file(
                  File(image.path),
                  width: image.size.width,
                  height: image.size.height,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) =>
                      canvasCtrl.missingImagePlaceholder(image),
                )
              : canvasCtrl.missingImagePlaceholder(image),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.red, size: 20),
            onPressed: () => canvasCtrl.deleteImage(pageIndex, image),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onPanUpdate: (details) =>
                canvasCtrl.updateImageSize(image, details.delta),
            child: Container(
              color: Colors.blue.withAlpha(150),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                LucideIcons.maximize2,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
