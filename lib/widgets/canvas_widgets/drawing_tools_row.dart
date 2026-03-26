import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../custom_popover.dart';
import '../../dialogs/unified_color_picker_dialog.dart';
import '../../controllers/canvas_controller.dart';
import '../../controllers/audio_controller.dart';
import '../../dialogs/canvas_dialogs.dart';
import '../../models/canvas_models.dart';
import 'advanced_pen_settings.dart';

class DrawingToolsRow extends StatelessWidget {
  final CanvasController canvasCtrl;
  final AudioController audioCtrl;
  final Axis direction;

  const DrawingToolsRow({
    super.key,
    required this.canvasCtrl,
    required this.audioCtrl,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    bool isVertical = direction == Axis.vertical;
    final coralGlow = const Color(0xFFFF7F6A); // Soft salmon/coral

    bool isBasePen = !canvasCtrl.isLassoMode && !canvasCtrl.isEraserMode && !canvasCtrl.isHighlighterMode && !canvasCtrl.isLaserMode && !canvasCtrl.isPanZoomMode && !canvasCtrl.isTextMode && !canvasCtrl.isShapeMode && !canvasCtrl.isTableMode;
    bool isBrush = isBasePen && canvasCtrl.currentPenType == PenType.brush;
    bool isPen = isBasePen && canvasCtrl.currentPenType != PenType.brush;

    final topRow = <Widget>[
       GlowingToolButton(
         icon: Icons.brush,
         isActive: isBrush,
         activeColor: coralGlow,
         tooltip: 'فرشاة',
         onTap: () {
           if (!isBrush) {
             canvasCtrl.disableAllTools();
             if (canvasCtrl.selectedColor == Colors.white) canvasCtrl.selectedColor = Colors.black;
             canvasCtrl.setPenType(PenType.brush);
           } else {
             canvasCtrl.showPenSettingsRow = !canvasCtrl.showPenSettingsRow;
           }
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: LucideIcons.pencil,
         isActive: isPen,
         activeColor: coralGlow,
         tooltip: 'قلم',
         onTap: () {
           if (!isPen) {
             canvasCtrl.disableAllTools();
             if (canvasCtrl.selectedColor == Colors.white) canvasCtrl.selectedColor = Colors.black;
             if (canvasCtrl.currentPenType == PenType.brush) canvasCtrl.setPenType(PenType.ball);
           } else {
             canvasCtrl.showPenSettingsRow = !canvasCtrl.showPenSettingsRow;
           }
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: Icons.border_color,
         isActive: canvasCtrl.isHighlighterMode,
         activeColor: coralGlow,
         tooltip: 'تظليل',
         onTap: () {
           canvasCtrl.activateHighlighter();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: LucideIcons.lasso,
         isActive: canvasCtrl.isLassoMode,
         activeColor: coralGlow,
         tooltip: 'تحديد',
         onTap: () {
           canvasCtrl.activateLasso();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: LucideIcons.type,
         isActive: canvasCtrl.isTextMode,
         activeColor: coralGlow,
         tooltip: 'نص',
         onTap: () {
           canvasCtrl.activateText();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: LucideIcons.eraser,
         isActive: canvasCtrl.isEraserMode,
         activeColor: coralGlow,
         tooltip: 'ممحاة',
         onTap: () {
           canvasCtrl.activateEraser();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: Icons.zoom_out_map,
         isActive: canvasCtrl.isZoomWindowVisible,
         activeColor: coralGlow,
         tooltip: 'نافذة مكبرة',
         onTap: () {
           canvasCtrl.toggleZoomWindow(MediaQuery.of(context).size);
           canvasCtrl.notifyListeners();
         },
       ),
       Builder(
         builder: (btnContext) => ColorPickerIndicatorButton(
           color: canvasCtrl.isHighlighterMode 
                ? canvasCtrl.highlighterColor 
                : (canvasCtrl.isLaserMode ? canvasCtrl.laserColor : canvasCtrl.selectedColor),
           onTap: () {
              showPopoverColorPicker(
                  context: btnContext,
                  currentColor: canvasCtrl.isHighlighterMode 
                    ? canvasCtrl.highlighterColor 
                    : (canvasCtrl.isLaserMode ? canvasCtrl.laserColor : canvasCtrl.selectedColor),
                  onColorChanged: (newColor) {
                    if (canvasCtrl.isHighlighterMode) canvasCtrl.changeDefaultHighlighterColor(0, newColor);
                    else if (canvasCtrl.isLaserMode) canvasCtrl.updateLaserColor(newColor);
                    else canvasCtrl.updateSelectedColor(newColor);
                    canvasCtrl.notifyListeners();
                  },
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
              );
           },
         ),
       ),
    ];

    final bottomRow = <Widget>[
       GlowingToolButton(
         icon: Icons.stream,
         isActive: canvasCtrl.isLaserMode,
         activeColor: coralGlow,
         tooltip: 'ليزر',
         onTap: () {
           canvasCtrl.activateLaser();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: LucideIcons.hand,
         isActive: canvasCtrl.isPanZoomMode,
         activeColor: coralGlow,
         tooltip: 'تحريك',
         onTap: () {
           canvasCtrl.activatePanZoom();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: LucideIcons.ruler,
         isActive: canvasCtrl.isRulerVisible,
         activeColor: coralGlow,
         tooltip: 'مسطرة',
         onTap: () {
           canvasCtrl.toggleRuler(MediaQuery.of(context).size);
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: LucideIcons.plus,
         isActive: canvasCtrl.showAddSettingsRow,
         activeColor: coralGlow,
         tooltip: 'أدوات الإضافة',
         onTap: () {
           canvasCtrl.toggleAddMenu();
           canvasCtrl.notifyListeners();
         },
       ),
       Container(
         width: isVertical ? 24 : 1,
         height: isVertical ? 1 : 24,
         color: Colors.white24,
         margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
       ),
       GlowingToolButton(
         icon: LucideIcons.zoomIn,
         isActive: canvasCtrl.isZoomSliderVisible,
         activeColor: coralGlow,
         tooltip: 'التحكم بالتكبير',
         onTap: () {
           canvasCtrl.toggleZoomSlider();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         icon: LucideIcons.magnet,
         isActive: canvasCtrl.isSettingsMagnetActive,
         activeColor: coralGlow,
         tooltip: 'ربط الإعدادات الإضافية',
         onTap: () {
           canvasCtrl.toggleSettingsMagnet();
         },
       ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: canvasCtrl.isDarkMode ? const Color(0xD926262A) : const Color(0xE6F5F5F7), // Dark or light translucent pill
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: canvasCtrl.isDarkMode ? Colors.black.withAlpha(60) : Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isVertical 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: canvasCtrl.toolbarPosition == ToolbarPosition.right
              ? [
                  Column(mainAxisSize: MainAxisSize.min, children: bottomRow),
                  Column(mainAxisSize: MainAxisSize.min, children: topRow),
                ]
              : [
                  Column(mainAxisSize: MainAxisSize.min, children: topRow),
                  Column(mainAxisSize: MainAxisSize.min, children: bottomRow),
                ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: canvasCtrl.toolbarPosition == ToolbarPosition.bottom
              ? [
                  Row(mainAxisSize: MainAxisSize.min, children: bottomRow),
                  const SizedBox(height: 8),
                  Row(mainAxisSize: MainAxisSize.min, children: topRow),
                ]
              : [
                  Row(mainAxisSize: MainAxisSize.min, children: topRow),
                  const SizedBox(height: 8),
                  Row(mainAxisSize: MainAxisSize.min, children: bottomRow),
                ],
          ),
    );
  }

  // --- Helper Widgets ---

  // --- Static Helper for Settings ---
  static Widget buildSettingsRow(
    CanvasController canvasCtrl,
    BuildContext context, {
    bool reversed = false,
    bool isVertical = false,
  }) {
    Widget buildDivider() {
      return Container(
        width: isVertical ? 24 : 1,
        height: isVertical ? 1 : 24,
        color: canvasCtrl.isDarkMode ? Colors.white24 : Colors.black12,
        margin: EdgeInsets.symmetric(
          horizontal: isVertical ? 0 : 8,
          vertical: isVertical ? 8 : 0,
        ),
      );
    }

    Widget buildDynamicSlider({required double value, required double min, required double max, required Color activeColor, required ValueChanged<double> onChanged, double length = 120}) {
      Widget slider = Slider(
        value: value,
        min: min,
        max: max,
        activeColor: activeColor,
        onChanged: onChanged,
      );
      if (isVertical) {
        return SizedBox(
          height: length,
          child: RotatedBox(
            quarterTurns: 3,
            child: slider,
          ),
        );
      }
      return SizedBox(
        width: length,
        child: slider,
      );
    }

    if (canvasCtrl.showAddSettingsRow) {
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
                    bool isTopHalf =
                        canvasCtrl.settingsWindowPosition.dy <
                        MediaQuery.of(context).size.height / 2;
                    CanvasDialogs.showShapeSettingsDialog(
                      context: itemContext,
                      canvasCtrl: canvasCtrl,
                      isTopHalf: isTopHalf,
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
                    bool isTopHalf =
                        canvasCtrl.settingsWindowPosition.dy <
                        MediaQuery.of(context).size.height / 2;
                    CanvasDialogs.showTableSettingsDialog(
                      context: itemContext,
                      canvasCtrl: canvasCtrl,
                      isTopHalf: isTopHalf,
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
    } else if (canvasCtrl.showPenSettingsRow) {
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
            color: const Color(0xFFFF7F6A),
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
            color: const Color(0xFFFF7F6A),
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
        buildDivider(),
        ...canvasCtrl.defaultPenColors.asMap().entries.map((entry) {
          final int index = entry.key;
          final Color c = entry.value;
          final bool isSelected = canvasCtrl.selectedColor == c;

          return Builder(
            builder: (itemContext) => GestureDetector(
              onTap: () {
                if (isSelected) {
                  showPopoverColorPicker(
                    context: itemContext,
                    currentColor: c,
                    onColorChanged: (newColor) =>
                        canvasCtrl.changeDefaultPenColor(index, newColor),
                    canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                    canvasCtrl: canvasCtrl,
                    onDelete:
                        (canvasCtrl.defaultPenColors.length +
                                canvasCtrl.customPenColors.length) >
                            3
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
                  onDelete:
                      (canvasCtrl.defaultPenColors.length +
                              canvasCtrl.customPenColors.length) >
                          3
                      ? () => canvasCtrl.deleteDefaultPenColor(index)
                      : null,
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isVertical ? 0 : 4, vertical: isVertical ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: const Color(0xFFFF7F6A), width: 2)
                      : null,
                ),
                child: CircleAvatar(backgroundColor: c, radius: 12),
              ),
            ),
          );
        }),
        ...canvasCtrl.customPenColors.asMap().entries.map((entry) {
          final int index = entry.key;
          final Color c = entry.value;
          final bool isSelected = canvasCtrl.selectedColor == c;

          return Builder(
            builder: (itemContext) => GestureDetector(
              onTap: () {
                if (isSelected) {
                  showPopoverColorPicker(
                    context: itemContext,
                    currentColor: c,
                    onColorChanged: (newColor) =>
                        canvasCtrl.changeCustomPenColor(index, newColor),
                    canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                    canvasCtrl: canvasCtrl,
                    onDelete:
                        (canvasCtrl.defaultPenColors.length +
                                canvasCtrl.customPenColors.length) >
                            3
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
                  onDelete:
                      (canvasCtrl.defaultPenColors.length +
                              canvasCtrl.customPenColors.length) >
                          3
                      ? () => canvasCtrl.deleteCustomPenColor(index)
                      : null,
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isVertical ? 0 : 4, vertical: isVertical ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: const Color(0xFFFF7F6A), width: 2)
                      : null,
                ),
                child: CircleAvatar(backgroundColor: c, radius: 12),
              ),
            ),
          );
        }),
        if (canvasCtrl.customPenColors.length < 7)
          Builder(
            builder: (itemContext) => IconButton(
              icon: const Icon(
                LucideIcons.plusCircle,
                color: const Color(0xFFFF7F6A),
                size: 24,
              ),
              tooltip: 'إضافة لون مخصص',
              onPressed: () {
                showPopoverColorPicker(
                  context: itemContext,
                  currentColor: canvasCtrl.selectedColor,
                  onColorChanged: (newColor) =>
                      canvasCtrl.addCustomPenColor(newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                );
              },
            ),
          ),
        buildDivider(),
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
                      ? Border.all(color: const Color(0xFFFF7F6A), width: 2)
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
        buildDivider(),
        Builder(
          builder: (itemContext) => IconButton(
            icon: Icon(
              LucideIcons.settings,
              color: canvasCtrl.showAdvancedPenSettings
                  ? const Color(0xFFFF7F6A)
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
    if (canvasCtrl.showHighlighterSettingsRow) {
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
        buildDivider(),
        // Thickness Slider
        buildDynamicSlider(
          value: canvasCtrl.highlighterThickness,
          min: 10.0,
          max: 80.0,
          activeColor: canvasCtrl.highlighterColor,
          length: 120,
          onChanged: (v) {
            canvasCtrl.updateHighlighterThickness(v);
            canvasCtrl.notifyListeners();
          },
        ),
        SizedBox(width: isVertical ? 0 : 8, height: isVertical ? 8 : 0),
        buildDivider(),
        const SizedBox(width: 8),
        // Colors
        ...canvasCtrl.defaultHighlighterColors.asMap().entries.map((entry) {
          final int index = entry.key;
          final Color c = entry.value;
          final bool isSelected = canvasCtrl.highlighterColor == c;

          return Builder(
            builder: (itemContext) => GestureDetector(
              onTap: () {
                if (isSelected) {
                  showPopoverColorPicker(
                    context: itemContext,
                    currentColor: c,
                    onColorChanged: (newColor) =>
                        canvasCtrl.changeDefaultHighlighterColor(index, newColor),
                    canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                    canvasCtrl: canvasCtrl,
                    onDelete:
                        (canvasCtrl.defaultHighlighterColors.length +
                                canvasCtrl.customHighlighterColors.length) >
                            3
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
                  onDelete:
                      (canvasCtrl.defaultHighlighterColors.length +
                              canvasCtrl.customHighlighterColors.length) >
                          3
                      ? () => canvasCtrl.deleteDefaultHighlighterColor(index)
                      : null,
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isVertical ? 0 : 4, vertical: isVertical ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: const Color(0xFFFF7F6A), width: 2)
                      : null,
                ),
                child: CircleAvatar(
                  backgroundColor: c.withValues(alpha: 0.5),
                  radius: 12,
                ),
              ),
            ),
          );
        }),
        ...canvasCtrl.customHighlighterColors.asMap().entries.map((entry) {
          final int index = entry.key;
          final Color c = entry.value;
          final bool isSelected = canvasCtrl.highlighterColor == c;

          return Builder(
            builder: (itemContext) => GestureDetector(
              onTap: () {
                if (isSelected) {
                  showPopoverColorPicker(
                    context: itemContext,
                    currentColor: c,
                    onColorChanged: (newColor) {
                      canvasCtrl.changeCustomHighlighterColor(index, newColor);
                      if (isSelected)
                        canvasCtrl.updateHighlighterColor(newColor);
                    },
                    canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                    canvasCtrl: canvasCtrl,
                    onDelete:
                        (canvasCtrl.defaultHighlighterColors.length +
                                canvasCtrl.customHighlighterColors.length) >
                            3
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
                  onDelete:
                      (canvasCtrl.defaultHighlighterColors.length +
                              canvasCtrl.customHighlighterColors.length) >
                          3
                      ? () => canvasCtrl.deleteCustomHighlighterColor(index)
                      : null,
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isVertical ? 0 : 4, vertical: isVertical ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: const Color(0xFFFF7F6A), width: 2)
                      : null,
                ),
                child: CircleAvatar(
                  backgroundColor: c.withValues(alpha: 0.5),
                  radius: 12,
                ),
              ),
            ),
          );
        }),
        if (canvasCtrl.customHighlighterColors.length < 7)
          Builder(
            builder: (itemContext) => IconButton(
              icon: const Icon(
                LucideIcons.plusCircle,
                color: const Color(0xFFFF7F6A),
                size: 24,
              ),
              tooltip: 'إضافة لون مخصص',
              onPressed: () {
                showPopoverColorPicker(
                  context: itemContext,
                  currentColor: canvasCtrl.highlighterColor,
                  onColorChanged: (newColor) {
                    canvasCtrl.addCustomHighlighterColor(newColor);
                    canvasCtrl.updateHighlighterColor(newColor);
                  },
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
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
    if (canvasCtrl.showLaserSettingsRow) {
      List<Widget> children = [
        // Laser Mode Toggle
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  canvasCtrl.isLaserDot = false;
                  canvasCtrl.notifyListeners();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: !canvasCtrl.isLaserDot
                        ? (canvasCtrl.isDarkMode
                              ? Colors.white24
                              : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: !canvasCtrl.isLaserDot
                        ? [
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    LucideIcons.activity,
                    size: 16,
                    color: canvasCtrl.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  canvasCtrl.isLaserDot = true;
                  canvasCtrl.notifyListeners();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: canvasCtrl.isLaserDot
                        ? (canvasCtrl.isDarkMode
                              ? Colors.white24
                              : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: canvasCtrl.isLaserDot
                        ? [
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    LucideIcons.circleDot,
                    size: 16,
                    color: canvasCtrl.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: isVertical ? 0 : 8, height: isVertical ? 8 : 0),
        buildDivider(),
        SizedBox(width: isVertical ? 0 : 8, height: isVertical ? 8 : 0),
        // Colors
        ...canvasCtrl.defaultLaserColors.asMap().entries.map((entry) {
          final int index = entry.key;
          final Color c = entry.value;
          final bool isSelected = canvasCtrl.laserColor == c;

          return Builder(
            builder: (itemContext) => GestureDetector(
              onTap: () {
                if (isSelected) {
                  showPopoverColorPicker(
                    context: itemContext,
                    currentColor: c,
                    onColorChanged: (newColor) =>
                        canvasCtrl.changeDefaultLaserColor(index, newColor),
                    canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                    canvasCtrl: canvasCtrl,
                    onDelete:
                        (canvasCtrl.defaultLaserColors.length +
                                canvasCtrl.customLaserColors.length) >
                            3
                        ? () => canvasCtrl.deleteDefaultLaserColor(index)
                        : null,
                  );
                } else {
                  canvasCtrl.updateLaserColor(c);
                }
              },
              onLongPress: () {
                showPopoverColorPicker(
                  context: itemContext,
                  currentColor: c,
                  onColorChanged: (newColor) =>
                      canvasCtrl.changeDefaultLaserColor(index, newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete:
                      (canvasCtrl.defaultLaserColors.length +
                              canvasCtrl.customLaserColors.length) >
                          3
                      ? () => canvasCtrl.deleteDefaultLaserColor(index)
                      : null,
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isVertical ? 0 : 4, vertical: isVertical ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: const Color(0xFFFF7F6A), width: 2)
                      : null,
                ),
                child: CircleAvatar(
                  backgroundColor: c,
                  radius: 12,
                ),
              ),
            ),
          );
        }),
        ...canvasCtrl.customLaserColors.asMap().entries.map((entry) {
          final int index = entry.key;
          final Color c = entry.value;
          final bool isSelected = canvasCtrl.laserColor == c;

          return Builder(
            builder: (itemContext) => GestureDetector(
              onTap: () {
                if (isSelected) {
                  showPopoverColorPicker(
                    context: itemContext,
                    currentColor: c,
                    onColorChanged: (newColor) =>
                        canvasCtrl.changeCustomLaserColor(index, newColor),
                    canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                    canvasCtrl: canvasCtrl,
                    onDelete:
                        (canvasCtrl.defaultLaserColors.length +
                                canvasCtrl.customLaserColors.length) >
                            3
                        ? () => canvasCtrl.deleteCustomLaserColor(index)
                        : null,
                  );
                } else {
                  canvasCtrl.updateLaserColor(c);
                }
              },
              onLongPress: () {
                showPopoverColorPicker(
                  context: itemContext,
                  currentColor: c,
                  onColorChanged: (newColor) =>
                      canvasCtrl.changeCustomLaserColor(index, newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete:
                      (canvasCtrl.defaultLaserColors.length +
                              canvasCtrl.customLaserColors.length) >
                          3
                      ? () => canvasCtrl.deleteCustomLaserColor(index)
                      : null,
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isVertical ? 0 : 4, vertical: isVertical ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: const Color(0xFFFF7F6A), width: 2)
                      : null,
                ),
                child: CircleAvatar(
                  backgroundColor: c,
                  radius: 12,
                ),
              ),
            ),
          );
        }),
        if (canvasCtrl.customLaserColors.length < 7)
          Builder(
            builder: (itemContext) => IconButton(
              icon: const Icon(
                LucideIcons.plusCircle,
                color: const Color(0xFFFF7F6A),
                size: 24,
              ),
              tooltip: 'إضافة لون مخصص',
              onPressed: () {
                showPopoverColorPicker(
                  context: itemContext,
                  currentColor: canvasCtrl.laserColor,
                  onColorChanged: (newColor) {
                    canvasCtrl.addCustomLaserColor(newColor);
                  },
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
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
    if (canvasCtrl.showEraserSettingsRow) {
      List<Widget> children = [
        // Eraser Type Toggle
        isVertical
            ? Container(
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'مسح جزئي',
                      child: GestureDetector(
                        onTap: () => canvasCtrl.updateEraseEntireObject(false),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: !canvasCtrl.eraseEntireObject
                                ? const Color(0xFFFF7F6A)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            LucideIcons.eraser,
                            size: 18,
                            color: !canvasCtrl.eraseEntireObject
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'مسح كائن',
                      child: GestureDetector(
                        onTap: () => canvasCtrl.updateEraseEntireObject(true),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: canvasCtrl.eraseEntireObject
                                ? const Color(0xFFFF7F6A)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: canvasCtrl.eraseEntireObject
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => canvasCtrl.updateEraseEntireObject(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: !canvasCtrl.eraseEntireObject ? const Color(0xFFFF7F6A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'مسح جزئي',
                          style: TextStyle(
                            fontSize: 12,
                            color: !canvasCtrl.eraseEntireObject ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => canvasCtrl.updateEraseEntireObject(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: canvasCtrl.eraseEntireObject ? const Color(0xFFFF7F6A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'مسح كائن',
                          style: TextStyle(
                            fontSize: 12,
                            color: canvasCtrl.eraseEntireObject ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

        buildDivider(),

        // Filters Button
        Builder(
          builder: (itemCtx) => isVertical
              ? Tooltip(
                  message: 'فلاتر ذكية',
                  child: InkWell(
                    onTap: () => _showEraserFiltersPopover(
                      context: itemCtx,
                      canvasCtrl: canvasCtrl,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7F6A).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.filter, size: 18, color: Color(0xFFFF7F6A)),
                    ),
                  ),
                )
              : ActionChip(
                  label: const Text('فلاتر ذكية', style: TextStyle(fontSize: 12)),
                  avatar: const Icon(LucideIcons.filter, size: 14),
                  backgroundColor: const Color(0xFFFF7F6A).withAlpha(20),
                  side: BorderSide.none,
                  onPressed: () => _showEraserFiltersPopover(
                    context: itemCtx,
                    canvasCtrl: canvasCtrl,
                  ),
                ),
        ),

        buildDivider(),

        // Eraser Presets
        ...List.generate(3, (index) {
          final double presetWidth = canvasCtrl.eraserWidthPresets[index];
          final bool isSelected = canvasCtrl.activeEraserWidthIndex == index;
          double dotRadius = presetWidth.clamp(5.0, 40.0) / 2.0;

          return Builder(
            builder: (itemContext) => GestureDetector(
              onTap: () {
                if (isSelected) {
                  _showEraserWidthPopover(
                    context: itemContext,
                    canvasCtrl: canvasCtrl,
                    presetIndex: index,
                  );
                } else {
                  canvasCtrl.selectEraserWidthPreset(index);
                }
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isVertical ? 0 : 4, vertical: isVertical ? 4 : 0),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withAlpha(20),
                  border: isSelected
                      ? Border.all(color: const Color(0xFFFF7F6A), width: 2)
                      : null,
                ),
                child: Center(
                  child: Container(
                    width: dotRadius,
                    height: dotRadius,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFFFF7F6A)
                          : Colors.grey.withAlpha(150),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ];
      return Flex(
        direction: isVertical ? Axis.vertical : Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: reversed ? children.reversed.toList() : children,
      );
    }
    if (canvasCtrl.showTextSettingsRow) {
      List<Widget> children = [
        IconButton(
          icon: const Icon(LucideIcons.minus),
          onPressed: () {
            canvasCtrl.updateFontSize(canvasCtrl.selectedFontSize - 2);
            canvasCtrl.notifyListeners();
          },
        ),
        Text(
          canvasCtrl.selectedFontSize.toStringAsFixed(0),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(LucideIcons.plus),
          onPressed: () {
            canvasCtrl.updateFontSize(canvasCtrl.selectedFontSize + 2);
            canvasCtrl.notifyListeners();
          },
        ),
      ];
      return Flex(
        direction: isVertical ? Axis.vertical : Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: reversed ? children.reversed.toList() : children,
      );
    }
    if (canvasCtrl.showLassoSettingsRow) {
      List<Widget> children = [
        _buildLassoIconToggle(LucideIcons.penTool, 'خطوط', canvasCtrl.lassoSelectHandwriting, (v) {
          canvasCtrl.lassoSelectHandwriting = v;
          canvasCtrl.notifyListeners();
        }, isVertical),
        _buildLassoIconToggle(LucideIcons.highlighter, 'تظليل', canvasCtrl.lassoSelectHighlighter, (v) {
          canvasCtrl.lassoSelectHighlighter = v;
          canvasCtrl.notifyListeners();
        }, isVertical),
        _buildLassoIconToggle(LucideIcons.image, 'صور', canvasCtrl.lassoSelectImages, (v) {
          canvasCtrl.lassoSelectImages = v;
          canvasCtrl.notifyListeners();
        }, isVertical),
        _buildLassoIconToggle(LucideIcons.type, 'نصوص', canvasCtrl.lassoSelectTexts, (v) {
          canvasCtrl.lassoSelectTexts = v;
          canvasCtrl.notifyListeners();
        }, isVertical),
        _buildLassoIconToggle(LucideIcons.square, 'أشكال', canvasCtrl.lassoSelectShapes, (v) {
          canvasCtrl.lassoSelectShapes = v;
          canvasCtrl.notifyListeners();
        }, isVertical),
        _buildLassoIconToggle(LucideIcons.table, 'جداول', canvasCtrl.lassoSelectTables, (v) {
          canvasCtrl.lassoSelectTables = v;
          canvasCtrl.notifyListeners();
        }, isVertical),
      ];
      return Flex(
        direction: isVertical ? Axis.vertical : Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: reversed ? children.reversed.toList() : children,
      );
    }
    return const SizedBox.shrink();
  }

  static Widget _buildLassoIconToggle(
    IconData icon,
    String tooltip,
    bool isSelected,
    ValueChanged<bool> onChanged,
    bool isVertical,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVertical ? 0 : 4,
        vertical: isVertical ? 4 : 0,
      ),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => onChanged(!isSelected),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF7F6A).withAlpha(50) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: const Color(0xFFFF7F6A).withAlpha(100), width: 1) : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFFFF7F6A) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  static bool isColorPickerOpen = false;

  static Future<void> showPopoverColorPicker({
    required BuildContext context,
    required Color currentColor,
    required Function(Color) onColorChanged,
    VoidCallback? onDelete,
    GlobalKey? canvasRepaintKey,
    CanvasController? canvasCtrl,
    bool useDialog = false,
  }) async {
    if (isColorPickerOpen) return;
    isColorPickerOpen = true;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset globalPosition = renderBox.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTopHalf = globalPosition.dy < screenSize.height / 2;

    Alignment? popoverAlignment;
    if (canvasCtrl != null) {
      if (canvasCtrl.toolbarPosition == ToolbarPosition.left) {
        popoverAlignment = Alignment.centerRight;
      } else if (canvasCtrl.toolbarPosition == ToolbarPosition.right) {
        popoverAlignment = Alignment.centerLeft;
      }
    }

    await showCustomPopover(
      context: context,
      isTopHalf: isTopHalf,
      alignment: popoverAlignment,
      width: 560, // Wider for the horizontal color picker layout
      backgroundColor: Colors.transparent,
      bodyBuilder: (dialogContext) => UnifiedColorPickerDialog(
        initialColor: currentColor,
        onColorChanged: onColorChanged,
        onDelete: onDelete,
        canvasRepaintKey: canvasRepaintKey,
        onPop: () => SmartDialog.dismiss(tag: 'custom_popover'),
      ),
    );

    // Wait for the exit animation to finish before releasing the lock
    await Future.delayed(const Duration(milliseconds: 200));
    isColorPickerOpen = false;
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
              padding: const EdgeInsets.all(16),
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
                  Text(
                    'حجم القلم',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
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
                          activeColor: const Color(0xFFFF7F6A),
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
                ],
              ),
            );
          },
        );
      },
      isTopHalf: isTopHalf,
      width: 280,
      height: 120,
      backgroundColor: Colors.transparent,
    );
  }

  static void _showEraserWidthPopover({
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
            double currentWidth = canvasCtrl.eraserWidthPresets[presetIndex];
            final isDark = canvasCtrl.isDarkMode;
            final textColor = isDark ? Colors.white : Colors.black87;
            final bgColor = isDark
                ? Colors.grey.shade900.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95);

            return Container(
              width: 280,
              padding: const EdgeInsets.all(16),
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
                  Text(
                    'حجم الممحاة',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.eraser,
                        size: 16,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      Expanded(
                        child: Slider(
                          value: currentWidth.clamp(5.0, 100.0),
                          min: 5.0,
                          max: 100.0,
                          divisions: 95,
                          activeColor: const Color(0xFFFF7F6A),
                          inactiveColor: isDark ? Colors.white12 : Colors.black12,
                          label: currentWidth.round().toString(),
                          onChanged: (val) {
                            setState(() {
                              currentWidth = val;
                            });
                            canvasCtrl.updateEraserWidthPreset(
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
                ],
              ),
            );
          },
        );
      },
      isTopHalf: isTopHalf,
      width: 280,
      height: 120,
      backgroundColor: Colors.transparent,
    );
  }

  static void _showEraserFiltersPopover({
    required BuildContext context,
    required CanvasController canvasCtrl,
  }) {
    bool isTopHalf =
        canvasCtrl.settingsWindowPosition.dy <
        MediaQuery.of(context).size.height / 2;
    showCustomPopover(
      context: context,
      bodyBuilder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'فلاتر المسح الذكي',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'مسح التظليل فقط',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'يتجاهل القلم العادي ويمسح ألوان التظليل الشفافة',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    value:
                        !canvasCtrl.eraseFilters.contains('pen') &&
                        canvasCtrl.eraseFilters.contains('highlighter'),
                    onChanged: (val) {
                      setState(() {
                        if (val) {
                          canvasCtrl.toggleEraserFilter('pen', false);
                          canvasCtrl.toggleEraserFilter('highlighter', true);
                        } else {
                          canvasCtrl.toggleEraserFilter('pen', true);
                          canvasCtrl.toggleEraserFilter('highlighter', true);
                        }
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text(
                      'تجاهل الأشكال',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: !canvasCtrl.eraseFilters.contains('shapes'),
                    onChanged: (val) {
                      setState(() {
                        canvasCtrl.toggleEraserFilter('shapes', !val);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text(
                      'تجاهل الصور والنصوص',
                      style: TextStyle(fontSize: 14),
                    ),
                    value:
                        !canvasCtrl.eraseFilters.contains('images') &&
                        !canvasCtrl.eraseFilters.contains('texts'),
                    onChanged: (val) {
                      setState(() {
                        canvasCtrl.toggleEraserFilter('images', !val);
                        canvasCtrl.toggleEraserFilter('texts', !val);
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      isTopHalf: isTopHalf,
      width: 320,
      height: 320,
      backgroundColor: Theme.of(context).cardColor,
    );
  }
}


class GlowingToolButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const GlowingToolButton({
    Key? key,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.tooltip,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withAlpha(200) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(150),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey.shade800),
          ),
        ),
      ),
    );
  }
}

class ColorPickerIndicatorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const ColorPickerIndicatorButton({
    Key? key,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(180),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
