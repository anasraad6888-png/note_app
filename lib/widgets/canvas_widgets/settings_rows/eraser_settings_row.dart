import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/canvas_controller.dart';
import '../../custom_popover.dart';
import '../../../models/canvas_models.dart';
import 'shared_settings_helpers.dart';

class EraserSettingsRow extends StatelessWidget {
  final CanvasController canvasCtrl;
  final bool reversed;
  final bool isVertical;

  const EraserSettingsRow({
    super.key,
    required this.canvasCtrl,
    this.reversed = false,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
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
              height: 28,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

      buildSettingsDivider(canvasCtrl, isVertical: isVertical),

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
                label: const Text('فلاتر ذكية', style: TextStyle(fontSize: 11)),
                avatar: const Icon(LucideIcons.filter, size: 12),
                backgroundColor: const Color(0xFFFF7F6A).withAlpha(20),
                side: BorderSide.none,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                onPressed: () => _showEraserFiltersPopover(
                  context: itemCtx,
                  canvasCtrl: canvasCtrl,
                ),
              ),
      ),

      buildSettingsDivider(canvasCtrl, isVertical: isVertical),

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
              width: 26,
              height: 26,
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
