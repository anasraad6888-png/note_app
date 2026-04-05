import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../unified_color_picker_dialog.dart';
import '../../controllers/canvas_controller.dart';
import '../../widgets/canvas_widgets/drawing_tools_row.dart' show showPopoverColorPicker;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class CanvasDialogHelpers {
  static Widget buildSettingsCard({
    required BuildContext context,
    required bool isDarkMode,
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static Widget buildCounterControl(
    BuildContext context,
    bool isDarkMode,
    String label,
    int value,
    int min,
    int max,
    Function(int) onUpdate,
    StateSetter setDialogState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black26 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    icon: Icon(LucideIcons.minus, size: 18, color: value > min ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey),
                    onPressed: value > min ? () { onUpdate(value - 1); setDialogState((){}); } : null,
                  ),
                  Container(
                    width: 30,
                    alignment: Alignment.center,
                    child: Text(
                      value.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    icon: Icon(LucideIcons.plus, size: 18, color: value < max ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey),
                    onPressed: value < max ? () { onUpdate(value + 1); setDialogState((){}); } : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget shapeGridItem(
    bool isDarkMode,
    String selectedShapeType,
    StateSetter setDialogState,
    String type,
    IconData? icon, {
    String? label,
    Widget? customIcon,
    required Function(String) onUpdate,
  }) {
    bool isSelected = selectedShapeType == type;
    final color = isSelected
        ? (isDarkMode ? Colors.amber : Colors.blue)
        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700);

    return GestureDetector(
      onTap: () {
        onUpdate(type);
        setDialogState(() {});
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode
                    ? Colors.amber.withValues(alpha: 0.3)
                    : Colors.blue.withValues(alpha: 0.2))
              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? Colors.amber : Colors.blue)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: customIcon ?? (icon != null
              ? Icon(
                  icon,
                  color: color,
                  size: 22,
                )
              : Text(
                  label ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )),
        ),
      ),
    );
  }

  static Widget colorPickerButton(
    BuildContext context,
    bool isDarkMode,
    StateSetter setDialogState,
    String title,
    Color currentColor,
    CanvasController canvasCtrl,
    Function(Color) onColorChanged,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => showPopoverColorPicker(
            context: context,
            currentColor: currentColor,
            canvasCtrl: canvasCtrl,
            useDialog: true,
            onColorChanged: (c) {
              onColorChanged(c);
              setDialogState(() {});
            },
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: currentColor == Colors.transparent ? Colors.white : currentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: currentColor == Colors.transparent
                ? Icon(Icons.format_color_reset, color: Colors.red.shade400, size: 24)
                : null,
          ),
        ),
      ],
    );
  }

  static Widget buildModernColorPicker({
    required BuildContext context,
    required bool isDarkMode,
    required StateSetter setDialogState,
    required String title,
    required Color color,
    required CanvasController canvasCtrl,
    required Function(Color) onColorChanged,
  }) {
    return Builder(
      builder: (buttonContext) => GestureDetector(
        onTap: () {
          showPopoverColorPicker(
            context: buttonContext,
            currentColor: color,
            onColorChanged: onColorChanged,
            canvasCtrl: canvasCtrl,
            useDialog: true,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            children: [
              Container(
                width: 24, 
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black26, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(100),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
