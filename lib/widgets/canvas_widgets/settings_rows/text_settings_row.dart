import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/canvas_controller.dart';
import 'shared_settings_helpers.dart';

class TextSettingsRow extends StatelessWidget {
  final CanvasController canvasCtrl;
  final bool reversed;
  final bool isVertical;

  const TextSettingsRow({
    super.key,
    required this.canvasCtrl,
    this.reversed = false,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final children = <Widget>[
      // Font Size Slider
      buildDynamicSlider(
        value: canvasCtrl.defaultFontSize,
        min: 12.0,
        max: 72.0,
        activeColor: const Color(0xFFFF7F6A),
        length: 120,
        isVertical: isVertical,
        onChanged: (v) {
          canvasCtrl.defaultFontSize = v;
          canvasCtrl.notifyListeners();
        },
      ),
      buildSettingsDivider(canvasCtrl, isVertical: isVertical),
      
      // Formatting Toggles
      IconButton(
        icon: const Icon(LucideIcons.bold),
        color: canvasCtrl.defaultTextBold ? const Color(0xFFFF7F6A) : (isDark ? Colors.grey[400] : Colors.grey[700]),
        onPressed: () {
          canvasCtrl.updateDefaultTextBold();
        },
        tooltip: 'عريض',
      ),
      IconButton(
        icon: const Icon(LucideIcons.italic),
        color: canvasCtrl.defaultTextItalic ? const Color(0xFFFF7F6A) : (isDark ? Colors.grey[400] : Colors.grey[700]),
        onPressed: () {
          canvasCtrl.updateDefaultTextItalic();
        },
        tooltip: 'مائل',
      ),
      IconButton(
        icon: const Icon(LucideIcons.underline),
        color: canvasCtrl.defaultTextUnderline ? const Color(0xFFFF7F6A) : (isDark ? Colors.grey[400] : Colors.grey[700]),
        onPressed: () {
          canvasCtrl.updateDefaultTextUnderline();
        },
        tooltip: 'تسطير',
      ),
      buildSettingsDivider(canvasCtrl, isVertical: isVertical),

      // Alignment variants
      IconButton(
        icon: const Icon(LucideIcons.alignLeft),
        color: canvasCtrl.defaultTextAlign == 'left' ? const Color(0xFFFF7F6A) : (isDark ? Colors.grey[400] : Colors.grey[700]),
        onPressed: () {
          canvasCtrl.updateDefaultTextAlign('left');
        },
        tooltip: 'محاذاة لليسار',
      ),
      IconButton(
        icon: const Icon(LucideIcons.alignCenter),
        color: canvasCtrl.defaultTextAlign == 'center' ? const Color(0xFFFF7F6A) : (isDark ? Colors.grey[400] : Colors.grey[700]),
        onPressed: () {
          canvasCtrl.updateDefaultTextAlign('center');
        },
        tooltip: 'توسيط',
      ),
      IconButton(
        icon: const Icon(LucideIcons.alignRight),
        color: canvasCtrl.defaultTextAlign == 'right' ? const Color(0xFFFF7F6A) : (isDark ? Colors.grey[400] : Colors.grey[700]),
        onPressed: () {
          canvasCtrl.updateDefaultTextAlign('right');
        },
        tooltip: 'محاذاة لليمين',
      ),

      buildSettingsDivider(canvasCtrl, isVertical: isVertical),

      // Colors
      ...canvasCtrl.defaultTextColors.asMap().entries.map((entry) {
        final int index = entry.key;
        final Color c = entry.value;
        final bool isSelected = canvasCtrl.defaultTextColor.value == c.value;
        return Builder(
          builder: (itemContext) => ModernColorSwatch(
            color: c,
            isSelected: isSelected,
            isVertical: isVertical,
            onTap: () {
              if (isSelected) {
                showPopoverColorPicker(
                  context: itemContext,
                  currentColor: c,
                  onColorChanged: (newColor) => canvasCtrl.changeDefaultTextColor(index, newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: (canvasCtrl.defaultTextColors.length + canvasCtrl.customTextColors.length) > 3
                      ? () => canvasCtrl.deleteDefaultTextColor(index)
                      : null,
                );
              } else {
                canvasCtrl.updateDefaultTextColor(c);
              }
            },
            onLongPress: () {
              showPopoverColorPicker(
                context: itemContext,
                currentColor: c,
                onColorChanged: (newColor) => canvasCtrl.changeDefaultTextColor(index, newColor),
                canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                canvasCtrl: canvasCtrl,
                onDelete: (canvasCtrl.defaultTextColors.length + canvasCtrl.customTextColors.length) > 3
                      ? () => canvasCtrl.deleteDefaultTextColor(index)
                      : null,
              );
            },
          ),
        );
      }),
      ...canvasCtrl.customTextColors.asMap().entries.map((entry) {
        final int index = entry.key;
        final Color c = entry.value;
        final bool isSelected = canvasCtrl.defaultTextColor.value == c.value;
        return Builder(
          builder: (itemContext) => ModernColorSwatch(
            color: c,
            isSelected: isSelected,
            isVertical: isVertical,
            onTap: () {
              if (isSelected) {
                showPopoverColorPicker(
                  context: itemContext,
                  currentColor: c,
                  onColorChanged: (newColor) => canvasCtrl.changeCustomTextColor(index, newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: (canvasCtrl.defaultTextColors.length + canvasCtrl.customTextColors.length) > 3
                      ? () => canvasCtrl.deleteCustomTextColor(index)
                      : null,
                );
              } else {
                canvasCtrl.updateDefaultTextColor(c);
              }
            },
            onLongPress: () {
              showPopoverColorPicker(
                context: itemContext,
                currentColor: c,
                onColorChanged: (newColor) => canvasCtrl.changeCustomTextColor(index, newColor),
                canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                canvasCtrl: canvasCtrl,
                onDelete: (canvasCtrl.defaultTextColors.length + canvasCtrl.customTextColors.length) > 3
                      ? () => canvasCtrl.deleteCustomTextColor(index)
                      : null,
              );
            },
          ),
        );
      }),

      if ((canvasCtrl.defaultTextColors.length + canvasCtrl.customTextColors.length) < 5)
        Builder(
          builder: (itemContext) => Tooltip(
            message: 'اختيار لون',
            child: ModernAddColorButton(
              isVertical: isVertical,
              onTap: () {
                bool isFirstChange = true;
                int addedIndex = -1;
                showPopoverColorPicker(
                  context: itemContext,
                  isAddMode: true,
                  currentColor: canvasCtrl.defaultTextColor,
                  onColorChanged: (newColor) {
                    if (isFirstChange) {
                      canvasCtrl.addCustomTextColor(newColor);
                      addedIndex = canvasCtrl.customTextColors.length - 1;
                      isFirstChange = false;
                    } else {
                      canvasCtrl.changeCustomTextColor(addedIndex, newColor);
                    }
                  },
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: () {
                    if (!isFirstChange && addedIndex != -1) {
                      canvasCtrl.deleteCustomTextColor(addedIndex);
                    }
                  },
                );
              },
            ),
          ),
        ),
    ];

    return Flex(
      direction: isVertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: reversed ? children.reversed.toList() : children,
    );
  }
}
