import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/canvas_controller.dart';
import '../../../dialogs/canvas_dialogs.dart';
import '../../../models/canvas_models.dart';

class AddSettingsRow extends StatelessWidget {
  final CanvasController canvasCtrl;
  final bool reversed;
  final bool isVertical;

  const AddSettingsRow({
    super.key,
    required this.canvasCtrl,
    this.reversed = false,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      IconButton(
        icon: const Icon(LucideIcons.image, size: 22, color: Colors.green),
        tooltip: 'إدراج صورة',
        onPressed: () {
          canvasCtrl.pickImage();
        },
      ),
      IconButton(
        icon: const Icon(
          LucideIcons.filePlus,
          size: 22,
          color: Colors.purple,
        ),
        tooltip: 'إدراج PDF',
        onPressed: () {
          canvasCtrl.importPdf();
        },
      ),
      Builder(
        builder: (itemContext) => IconButton(
          icon: Icon(
            LucideIcons.shapes,
            size: 22,
            color: canvasCtrl.isShapeMode
                ? const Color(0xFFFF7F6A)
                : (canvasCtrl.isDarkMode ? Colors.white70 : Colors.black87),
          ),
          tooltip: 'الأشكال',
          onPressed: () {
            if (canvasCtrl.isShapeMode) {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (itemContext.mounted) {
                  final RenderBox box = itemContext.findRenderObject() as RenderBox;
                  final Offset globalPosition = box.localToGlobal(Offset.zero);
                  final bool isTopHalf = globalPosition.dy < MediaQuery.of(context).size.height / 2;
                  
                  Alignment? dialogAlignment;
                  if (canvasCtrl.toolbarPosition == ToolbarPosition.right) {
                    dialogAlignment = Alignment.centerLeft;
                  } else if (canvasCtrl.toolbarPosition == ToolbarPosition.left) {
                    dialogAlignment = Alignment.centerRight;
                  }

                  CanvasDialogs.showShapeSettingsDialog(
                    context: itemContext,
                    canvasCtrl: canvasCtrl,
                    isTopHalf: isTopHalf,
                    alignment: dialogAlignment,
                  );
                }
              });
            } else {
              canvasCtrl.activateShape(context, canvasCtrl.isDarkMode);
            }
          },
        ),
      ),
      Builder(
        builder: (itemContext) => IconButton(
          icon: Icon(
            LucideIcons.layoutGrid,
            size: 22,
            color: canvasCtrl.isTableMode
                ? const Color(0xFFFF7F6A)
                : (canvasCtrl.isDarkMode ? Colors.white70 : Colors.black87),
          ),
          tooltip: 'جداول',
          onPressed: () {
            if (canvasCtrl.isTableMode) {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (itemContext.mounted) {
                  final RenderBox box = itemContext.findRenderObject() as RenderBox;
                  final Offset globalPosition = box.localToGlobal(Offset.zero);
                  final bool isTopHalf = globalPosition.dy < MediaQuery.of(context).size.height / 2;

                  Alignment? dialogAlignment;
                  if (canvasCtrl.toolbarPosition == ToolbarPosition.right) {
                    dialogAlignment = Alignment.centerLeft;
                  } else if (canvasCtrl.toolbarPosition == ToolbarPosition.left) {
                    dialogAlignment = Alignment.centerRight;
                  }

                  CanvasDialogs.showTableSettingsDialog(
                    context: itemContext,
                    canvasCtrl: canvasCtrl,
                    isTopHalf: isTopHalf,
                    alignment: dialogAlignment,
                  );
                }
              });
            } else {
              canvasCtrl.activateTable(context, canvasCtrl.isDarkMode);
            }
          },
        ),
      ),
    ];
    return Flex(
      direction: isVertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      children: reversed ? children.reversed.toList() : children,
    );
  }
}
