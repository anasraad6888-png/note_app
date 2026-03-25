import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/canvas_widgets/eyedropper_overlay.dart';
import '../widgets/pro_compact_color_picker.dart';

class UnifiedColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;
  final VoidCallback? onDelete; // For drawing tools deletion support
  final GlobalKey? canvasRepaintKey; // For eyedropper
  final VoidCallback? onPop; // Custom pop callback for SmartDialog integration

  const UnifiedColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.onDelete,
    this.canvasRepaintKey,
    this.onPop,
  });

  @override
  State<UnifiedColorPickerDialog> createState() =>
      _UnifiedColorPickerDialogState();
}

class _UnifiedColorPickerDialogState extends State<UnifiedColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  void _updateColor(Color color) {
    if (mounted) {
      setState(() {
        _selectedColor = color;
      });
    }
    widget.onColorChanged(color);
  }

  void _closeDialog() {
    if (widget.onPop != null) {
      widget.onPop!();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 550, // Much wider for horizontal layout
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: _closeDialog,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "اختيار اللون",
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.canvasRepaintKey != null)
                      IconButton(
                        icon: const Icon(
                          LucideIcons.pipette,
                          size: 18,
                          color: const Color(0xFFFF7F6A),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'لقط لون من الشاشة',
                        onPressed: () async {
                          final canvasContext = widget.canvasRepaintKey?.currentContext;
                          if (canvasContext == null) return;
                          
                          // Capture necessary values BEFORE unmounting the dialog
                          final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
                          
                          _closeDialog();
                          await Future.delayed(
                            const Duration(milliseconds: 200),
                          );

                          if (canvasContext.mounted) {
                            RenderRepaintBoundary boundary =
                                canvasContext.findRenderObject()
                                    as RenderRepaintBoundary;
                            ui.Image image = await boundary.toImage(
                              pixelRatio: pixelRatio,
                            );

                            if (canvasContext.mounted) {
                              Color? pickedColor = await Navigator.of(canvasContext)
                                  .push(
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (context, _, _) =>
                                          EyedropperOverlay(
                                            capturedImage: image,
                                          ),
                                    ),
                                  );

                              if (pickedColor != null) {
                                _updateColor(pickedColor);
                              }
                            }
                          }
                        },
                      ),
                    if (widget.onDelete != null)
                      TextButton.icon(
                        icon: const Icon(LucideIcons.ban, size: 14),
                        label: const Text("شفاف"),
                        style: TextButton.styleFrom(
                          foregroundColor: isDarkMode
                              ? Colors.white70
                              : Colors.black54,
                          textStyle: const TextStyle(fontSize: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          widget.onDelete!();
                          _closeDialog();
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(
                cardColor: Colors
                    .transparent, // Prevents double background when nested
              ),
              child: SizedBox(
                height: 250, // Updated height to match Top/Bottom split
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ProCompactColorPicker(
                    pickerColor: _selectedColor,
                    onColorChanged: _updateColor,
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
