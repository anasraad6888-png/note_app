import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/canvas_controller.dart';
import 'drawing_tools_row.dart'; // Provides showPopoverColorPicker

class SelectionBoundingBox extends StatelessWidget {
  final int pageIndex;
  final CanvasController canvasCtrl;

  const SelectionBoundingBox({
    super.key,
    required this.pageIndex,
    required this.canvasCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final rect = canvasCtrl.getSelectionBoundingBox(pageIndex);
    if (rect == null) return const SizedBox.shrink();

    final group = canvasCtrl.activeSelectionGroup!;
    const double pad = 24.0;

    return Positioned(
      left: rect.left - pad,
      top: rect.top - pad,
      width: rect.width + (pad * 2),
      height: rect.height + (pad * 2),
      child: Transform.rotate(
        angle: group.currentRotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: pad,
              top: pad,
              right: pad,
              bottom: pad,
              child: GestureDetector(
                onPanUpdate: (details) {
                  canvasCtrl.translateSelection(details.delta);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    color: Colors.blueAccent.withAlpha(20),
                  ),
                ),
              ),
            ),
            // Delete Handle
            Positioned(
              top: pad - 15,
              left: pad - 15,
              child: GestureDetector(
                onTap: () => canvasCtrl.deleteSelection(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Rotate Handle
            Positioned(
              top: pad - 15,
              right: pad - 15,
              child: GestureDetector(
                onPanUpdate: (details) {
                  canvasCtrl.rotateSelection(details.delta.dx / 100.0);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    Icons.rotate_right,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Scale Handle
            Positioned(
              bottom: pad - 15,
              right: pad - 15,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final mag = (details.delta.dx + details.delta.dy) / 200.0;
                  canvasCtrl.scaleSelection(1.0 + mag);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.maximize2,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectionContextMenu extends StatelessWidget {
  final int pageIndex;
  final CanvasController canvasCtrl;

  const SelectionContextMenu({
    super.key,
    required this.pageIndex,
    required this.canvasCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final rect = canvasCtrl.getSelectionBoundingBox(pageIndex);
    if (rect == null) return const SizedBox.shrink();

    return Positioned(
      left: rect.left + (rect.width / 2),
      top: rect.top - 60,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: canvasCtrl.isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.scissors, size: 20),
                onPressed: () => canvasCtrl.cutSelection(),
                tooltip: 'Cut',
                color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 20),
                onPressed: () => canvasCtrl.copySelection(),
                tooltip: 'Copy',
                color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              IconButton(
                icon: const Icon(Icons.control_point_duplicate, size: 20),
                onPressed: () => canvasCtrl.duplicateSelection(),
                tooltip: 'Duplicate',
                color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              IconButton(
                icon: const Icon(Icons.document_scanner, size: 20),
                onPressed: () => canvasCtrl.performOCR(context),
                tooltip: 'Convert to Text',
                color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Builder(
                builder: (itemCtx) => IconButton(
                  icon: const Icon(LucideIcons.palette, size: 20),
                  onPressed: () {
                    showPopoverColorPicker(
                      context: itemCtx,
                      currentColor: canvasCtrl.selectedColor,
                      onColorChanged: (c) => canvasCtrl.recolorSelection(c),
                      canvasCtrl: canvasCtrl,
                    );
                  },
                  tooltip: 'Recolor',
                  color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
