import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/canvas_controller.dart';
import '../../../models/canvas_models.dart';
import 'shared_settings_helpers.dart';

class HighlighterSettingsRow extends StatelessWidget {
  final CanvasController canvasCtrl;
  final bool reversed;
  final bool isVertical;

  const HighlighterSettingsRow({
    super.key,
    required this.canvasCtrl,
    this.reversed = false,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      IconButton(
        icon: Icon(
          canvasCtrl.currentLineType == LineType.solid
              ? Icons.horizontal_rule
              : (canvasCtrl.currentLineType == LineType.dashed
                    ? Icons.power_input
                    : Icons.more_horiz),
          color: canvasCtrl.highlighterColor,
        ),
        onPressed: () {
          // Cycle: Solid → Dashed → Dotted → Solid
          if (canvasCtrl.currentLineType == LineType.solid) {
            canvasCtrl.setLineType(LineType.dashed);
          } else if (canvasCtrl.currentLineType == LineType.dashed) {
            canvasCtrl.setLineType(LineType.dotted);
          } else {
            canvasCtrl.setLineType(LineType.solid);
          }
        },
        tooltip: canvasCtrl.currentLineType == LineType.solid
            ? 'تظليل متصل'
            : (canvasCtrl.currentLineType == LineType.dashed
                  ? 'تظليل متقطع (Dashed)'
                  : 'تظليل منقط (Dotted)'),
      ),
      buildSettingsDivider(canvasCtrl, isVertical: isVertical),
      // Thickness Slider
      buildDynamicSlider(
        value: canvasCtrl.highlighterThickness,
        min: 10.0,
        max: 80.0,
        activeColor: canvasCtrl.highlighterColor,
        length: 120,
        isVertical: isVertical,
        onChanged: (v) {
          canvasCtrl.updateHighlighterThickness(v);
          canvasCtrl.notifyListeners();
        },
      ),
      SizedBox(width: isVertical ? 0 : 8, height: isVertical ? 8 : 0),
      buildSettingsDivider(canvasCtrl, isVertical: isVertical),
      const SizedBox(width: 8),
      // Colors
      ...canvasCtrl.defaultHighlighterColors.asMap().entries.map((entry) {
        final int index = entry.key;
        final Color c = entry.value;
        final bool isSelected = canvasCtrl.highlighterColor == c;

        return Builder(
          builder: (itemContext) => ModernColorSwatch(
            color: c.withValues(alpha: 0.5),
            isSelected: isSelected,
            isVertical: isVertical,
            onTap: () {
              if (isSelected) {
                showPopoverColorPicker(
                  context: itemContext,
                  currentColor: c,
                  onColorChanged: (newColor) =>
                      canvasCtrl.changeDefaultHighlighterColor(index, newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: (canvasCtrl.defaultHighlighterColors.length + canvasCtrl.customHighlighterColors.length) > 3
                      ? () => canvasCtrl.deleteDefaultHighlighterColor(index)
                      : null,
                );
              } else {
                canvasCtrl.updateHighlighterColor(c);
              }
            },
            onLongPress: () {
              showPopoverColorPicker(
                context: itemContext,
                currentColor: c,
                onColorChanged: (newColor) =>
                    canvasCtrl.changeDefaultHighlighterColor(index, newColor),
                canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                canvasCtrl: canvasCtrl,
                onDelete: (canvasCtrl.defaultHighlighterColors.length + canvasCtrl.customHighlighterColors.length) > 3
                    ? () => canvasCtrl.deleteDefaultHighlighterColor(index)
                    : null,
              );
            },
          ),
        );
      }),
      ...canvasCtrl.customHighlighterColors.asMap().entries.map((entry) {
        final int index = entry.key;
        final Color c = entry.value;
        final bool isSelected = canvasCtrl.highlighterColor == c;

        return Builder(
          builder: (itemContext) => ModernColorSwatch(
            color: c.withValues(alpha: 0.5),
            isSelected: isSelected,
            isVertical: isVertical,
            onTap: () {
              if (isSelected) {
                showPopoverColorPicker(
                  context: itemContext,
                  currentColor: c,
                  onColorChanged: (newColor) {
                    canvasCtrl.changeCustomHighlighterColor(index, newColor);
                    if (isSelected) canvasCtrl.updateHighlighterColor(newColor);
                  },
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: (canvasCtrl.defaultHighlighterColors.length + canvasCtrl.customHighlighterColors.length) > 3
                      ? () => canvasCtrl.deleteCustomHighlighterColor(index)
                      : null,
                );
              } else {
                canvasCtrl.updateHighlighterColor(c);
              }
            },
            onLongPress: () {
              showPopoverColorPicker(
                context: itemContext,
                currentColor: c,
                onColorChanged: (newColor) {
                  canvasCtrl.changeCustomHighlighterColor(index, newColor);
                  if (isSelected) canvasCtrl.updateHighlighterColor(newColor);
                },
                canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                canvasCtrl: canvasCtrl,
                onDelete: (canvasCtrl.defaultHighlighterColors.length + canvasCtrl.customHighlighterColors.length) > 3
                    ? () => canvasCtrl.deleteCustomHighlighterColor(index)
                    : null,
              );
            },
          ),
        );
      }),
      if (canvasCtrl.customHighlighterColors.length < 7)
        Builder(
          builder: (itemContext) => Tooltip(
            message: 'إضافة لون مخصص',
            child: ModernAddColorButton(
              isVertical: isVertical,
              onTap: () {
                bool isFirstChange = true;
                int addedIndex = -1;
                showPopoverColorPicker(
                  context: itemContext,
                  isAddMode: true,
                  currentColor: canvasCtrl.highlighterColor,
                  onColorChanged: (newColor) {
                    if (isFirstChange) {
                      canvasCtrl.addCustomHighlighterColor(newColor);
                      addedIndex = canvasCtrl.customHighlighterColors.length - 1;
                      canvasCtrl.updateHighlighterColor(newColor);
                      isFirstChange = false;
                    } else {
                      canvasCtrl.changeCustomHighlighterColor(addedIndex, newColor);
                      canvasCtrl.updateHighlighterColor(newColor);
                    }
                  },
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: () {
                    if (!isFirstChange && addedIndex != -1) {
                      canvasCtrl.deleteCustomHighlighterColor(addedIndex);
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
      children: reversed ? children.reversed.toList() : children,
    );
  }
}
