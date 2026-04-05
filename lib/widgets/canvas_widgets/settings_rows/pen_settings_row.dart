import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../../../controllers/canvas_controller.dart';
import '../../../models/canvas_models.dart';
import '../advanced_pen_settings.dart';
import '../../custom_popover.dart';
import 'shared_settings_helpers.dart';

class PenSettingsRow extends StatelessWidget {
  final CanvasController canvasCtrl;
  final bool reversed;
  final bool isVertical;

  const PenSettingsRow({
    super.key,
    required this.canvasCtrl,
    this.reversed = false,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    Color activeIconColor = (canvasCtrl.isDarkMode && canvasCtrl.selectedColor.value == Colors.black.value)
        ? Colors.white
        : canvasCtrl.selectedColor;

    List<Widget> children = [
      IconButton(
        icon: Icon(
          canvasCtrl.currentPenType == PenType.perfect
              ? LucideIcons.penTool
              : (canvasCtrl.currentPenType == PenType.velocity
                    ? LucideIcons.wand2
                    : (canvasCtrl.currentPenType == PenType.pencil
                          ? Icons.mode_edit_outline
                          : (canvasCtrl.currentPenType == PenType.brush
                              ? Icons.brush
                              : (canvasCtrl.currentPenType == PenType.fountain
                                  ? Icons.draw
                                  : Icons.edit)))),
          color: activeIconColor,
        ),
        onPressed: () {
          // Cycle: Ball → Fountain → Brush → Pencil → Perfect → Velocity → Ball
          if (canvasCtrl.currentPenType == PenType.ball) {
            canvasCtrl.setPenType(PenType.fountain);
          } else if (canvasCtrl.currentPenType == PenType.fountain) {
            canvasCtrl.setPenType(PenType.brush);
          } else if (canvasCtrl.currentPenType == PenType.brush) {
            canvasCtrl.setPenType(PenType.pencil);
          } else if (canvasCtrl.currentPenType == PenType.pencil) {
            canvasCtrl.setPenType(PenType.perfect);
          } else if (canvasCtrl.currentPenType == PenType.perfect) {
            canvasCtrl.setPenType(PenType.velocity);
          } else {
            canvasCtrl.setPenType(PenType.ball);
          }
          canvasCtrl.notifyListeners();
        },
        tooltip: canvasCtrl.currentPenType == PenType.perfect
            ? 'قلم واقعي (نعومة فائقة)'
            : (canvasCtrl.currentPenType == PenType.velocity
                  ? 'قلم ذكي (حسب السرعة)'
                  : (canvasCtrl.currentPenType == PenType.pencil
                        ? 'قلم رصاص (جرافيت)'
                        : (canvasCtrl.currentPenType == PenType.brush
                              ? 'فرشاة'
                              : (canvasCtrl.currentPenType == PenType.fountain
                                    ? 'قلم حبر'
                                    : 'قلم عادي')))),
      ),
      IconButton(
        icon: Icon(
          canvasCtrl.currentLineType == LineType.solid
              ? Icons.horizontal_rule
              : (canvasCtrl.currentLineType == LineType.dashed
                    ? Icons.power_input
                    : Icons.more_horiz),
          color: activeIconColor,
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
            ? 'خط متصل'
            : (canvasCtrl.currentLineType == LineType.dashed
                  ? 'خط متقطع (Dashed)'
                  : 'خط منقط (Dotted)'),
      ),
      buildSettingsDivider(canvasCtrl, isVertical: isVertical),
      ...canvasCtrl.defaultPenColors.asMap().entries.map((entry) {
        final int index = entry.key;
        final Color c = entry.value;
        final bool isSelected = canvasCtrl.selectedColor == c;

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
                  onColorChanged: (newColor) =>
                      canvasCtrl.changeDefaultPenColor(index, newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: (canvasCtrl.defaultPenColors.length + canvasCtrl.customPenColors.length) > 3
                      ? () => canvasCtrl.deleteDefaultPenColor(index)
                      : null,
                );
              } else {
                canvasCtrl.updateSelectedColor(c);
              }
            },
            onLongPress: () {
              showPopoverColorPicker(
                context: itemContext,
                currentColor: c,
                onColorChanged: (newColor) =>
                    canvasCtrl.changeDefaultPenColor(index, newColor),
                canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                canvasCtrl: canvasCtrl,
                onDelete: (canvasCtrl.defaultPenColors.length + canvasCtrl.customPenColors.length) > 3
                    ? () => canvasCtrl.deleteDefaultPenColor(index)
                    : null,
              );
            },
          ),
        );
      }),
      ...canvasCtrl.customPenColors.asMap().entries.map((entry) {
        final int index = entry.key;
        final Color c = entry.value;
        final bool isSelected = canvasCtrl.selectedColor == c;

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
                  onColorChanged: (newColor) =>
                      canvasCtrl.changeCustomPenColor(index, newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: (canvasCtrl.defaultPenColors.length + canvasCtrl.customPenColors.length) > 3
                      ? () => canvasCtrl.deleteCustomPenColor(index)
                      : null,
                );
              } else {
                canvasCtrl.updateSelectedColor(c);
              }
            },
            onLongPress: () {
              showPopoverColorPicker(
                context: itemContext,
                currentColor: c,
                onColorChanged: (newColor) =>
                    canvasCtrl.changeCustomPenColor(index, newColor),
                canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                canvasCtrl: canvasCtrl,
                onDelete: (canvasCtrl.defaultPenColors.length + canvasCtrl.customPenColors.length) > 3
                    ? () => canvasCtrl.deleteCustomPenColor(index)
                    : null,
              );
            },
          ),
        );
      }),
      if (canvasCtrl.customPenColors.length < 7)
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
                  currentColor: canvasCtrl.selectedColor,
                  onColorChanged: (newColor) {
                    if (isFirstChange) {
                      canvasCtrl.addCustomPenColor(newColor);
                      addedIndex = canvasCtrl.customPenColors.length - 1;
                      isFirstChange = false;
                    } else {
                      canvasCtrl.changeCustomPenColor(addedIndex, newColor);
                    }
                  },
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: () {
                    // Force a close if they delete
                    if (!isFirstChange && addedIndex != -1) {
                      canvasCtrl.deleteCustomPenColor(addedIndex);
                    }
                  },
                );
              },
            ),
          ),
        ),
      buildSettingsDivider(canvasCtrl, isVertical: isVertical),
      ...List.generate(3, (index) {
        final double presetWidth = canvasCtrl.strokeWidthPresets[index];
        final bool isSelected = canvasCtrl.activeStrokeWidthIndex == index;
        double dotRadius = presetWidth.clamp(2.0, 20.0) / 2.0 + 1.0;

        return Builder(
          builder: (itemContext) => GestureDetector(
            onTap: () {
              if (isSelected) {
                _showStrokeWidthPopover(
                  context: itemContext,
                  canvasCtrl: canvasCtrl,
                  presetIndex: index,
                );
              } else {
                canvasCtrl.selectStrokeWidthPreset(index);
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isVertical ? 0 : 4, vertical: isVertical ? 4 : 0),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canvasCtrl.isDarkMode ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                border: isSelected
                    ? Border.all(color: activeIconColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Container(
                  width: dotRadius * 2,
                  height: dotRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canvasCtrl.isDarkMode && canvasCtrl.selectedColor.value == Colors.black.value ? Colors.white : canvasCtrl.selectedColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
      buildSettingsDivider(canvasCtrl, isVertical: isVertical),
      Builder(
        builder: (itemContext) => IconButton(
          icon: Icon(
            LucideIcons.settings,
            color: canvasCtrl.showAdvancedPenSettings
                ? activeIconColor
                : Colors.grey,
          ),
          tooltip: 'إعدادات القلم المتقدمة',
          onPressed: () {
            final RenderBox renderBox = itemContext.findRenderObject() as RenderBox;
            final Offset globalPosition = renderBox.localToGlobal(Offset.zero);
            final Size screenSize = MediaQuery.of(itemContext).size;
            final bool isTopHalf = globalPosition.dy < screenSize.height / 2;

            showCustomPopover(
              context: itemContext,
              isTopHalf: isTopHalf,
              width: 320,
              backgroundColor: Colors.transparent,
              bodyBuilder: (dialogContext) => AdvancedPenSettingsWindow(
                canvasCtrl: canvasCtrl,
                onPop: () => SmartDialog.dismiss(tag: 'custom_popover'),
              ),
            );
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

  static void _showStrokeWidthPopover({
    required BuildContext context,
    required CanvasController canvasCtrl,
    required int presetIndex,
  }) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset globalPosition = renderBox.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTopHalf = globalPosition.dy < screenSize.height / 2;
    
    Alignment? popoverAlignment;
    if (canvasCtrl.toolbarPosition == ToolbarPosition.left) {
      popoverAlignment = Alignment.centerRight;
    } else if (canvasCtrl.toolbarPosition == ToolbarPosition.right) {
      popoverAlignment = Alignment.centerLeft;
    }

    showCustomPopover(
      context: context,
      alignment: popoverAlignment,
      bodyBuilder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double currentWidth = canvasCtrl.strokeWidthPresets[presetIndex];
            final isDark = canvasCtrl.isDarkMode;
            final textColor = isDark ? Colors.white : Colors.black87;
            final bgColor = isDark
                ? Colors.grey.shade900.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95);

            return Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 248,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.penTool,
                            size: 16,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                          Expanded(
                            child: Slider(
                              value: currentWidth.clamp(1.0, 30.0),
                              min: 1.0,
                              max: 30.0,
                              divisions: 29,
                              activeColor: (isDark && canvasCtrl.selectedColor.value == Colors.black.value) ? Colors.white : canvasCtrl.selectedColor,
                              inactiveColor: isDark ? Colors.white12 : Colors.black12,
                              label: currentWidth.round().toString(),
                              onChanged: (val) {
                                setState(() {
                                  currentWidth = val;
                                });
                                canvasCtrl.updateStrokeWidthPreset(
                                  presetIndex,
                                  val,
                                );
                              },
                            ),
                          ),
                          Text(
                            '${currentWidth.round()} px',
                            style: TextStyle(fontSize: 12, color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      isTopHalf: isTopHalf,
      width: 280,
      height: 70,
      backgroundColor: Colors.transparent,
    );
  }
}
