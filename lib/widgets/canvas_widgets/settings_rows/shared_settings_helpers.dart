import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../../../controllers/canvas_controller.dart';
import '../../../dialogs/unified_color_picker_dialog.dart';
import '../../custom_popover.dart';
import '../../../models/canvas_models.dart';

Widget buildSettingsDivider(CanvasController canvasCtrl, {bool isVertical = false}) {
  return Container(
    width: isVertical ? 18 : 1,
    height: isVertical ? 1 : 18,
    color: canvasCtrl.isDarkMode ? Colors.white24 : Colors.black12,
    margin: EdgeInsets.symmetric(
      horizontal: isVertical ? 0 : 6,
      vertical: isVertical ? 6 : 0,
    ),
  );
}

Widget buildDynamicSlider({
  required double value,
  required double min,
  required double max,
  required Color activeColor,
  required ValueChanged<double> onChanged,
  bool isVertical = false,
  double length = 120,
}) {
  return Builder(
    builder: (context) {
      Widget slider = SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
        ),
        child: Slider(
          value: value,
          min: min,
          max: max,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      );

      if (isVertical) {
        return SizedBox(
          width: 36,
          height: length,
          child: RotatedBox(
            quarterTurns: 3,
            child: slider,
          ),
        );
      }
      return SizedBox(
        height: 28,
        width: length,
        child: slider,
      );
    },
  );
}

bool isColorPickerOpen = false;

Future<void> showPopoverColorPicker({
  required BuildContext context,
  required Color currentColor,
  required Function(Color) onColorChanged,
  VoidCallback? onDelete,
  GlobalKey? canvasRepaintKey,
  CanvasController? canvasCtrl,
  bool useDialog = false,
  bool isAddMode = false,
}) async {
  if (isColorPickerOpen) return;
  isColorPickerOpen = true;

  final RenderBox renderBox = context.findRenderObject() as RenderBox;
  final Offset globalPosition = renderBox.localToGlobal(Offset.zero);
  final Size screenSize = MediaQuery.of(context).size;
  final bool isTopHalf = globalPosition.dy < screenSize.height / 2;
  
  // Calculate horizontal position relative to screen
  final double centerPoint = globalPosition.dx + (renderBox.size.width / 2);
  final bool isRightHalf = centerPoint > (screenSize.width * 0.6);
  final bool isLeftHalf = centerPoint < (screenSize.width * 0.4);

  Alignment? popoverAlignment;

  if (canvasCtrl != null) {
    if (canvasCtrl.toolbarPosition == ToolbarPosition.left) {
      popoverAlignment = Alignment.centerRight;
    } else if (canvasCtrl.toolbarPosition == ToolbarPosition.right) {
      popoverAlignment = Alignment.centerLeft;
    } else {
      // Regardless of useDialog, we MUST enforce topCenter/bottomCenter for SmartDialog.showAttach
      // to avoid horizontal alignment bleed bugs in flutter_smart_dialog!
      if (canvasCtrl.toolbarPosition == ToolbarPosition.bottom) {
        popoverAlignment = Alignment.topCenter;
      } else {
        popoverAlignment = Alignment.bottomCenter;
      }
    }
  }

  final bool isSpawnedBelow = popoverAlignment == Alignment.bottomCenter;

  await showCustomPopover(
    context: context,
    isTopHalf: isTopHalf,
    alignment: popoverAlignment,
    backgroundColor: Colors.transparent,
    removeBackgroundDecoration: true,
    tag: 'color_picker_popover',
    bodyBuilder: (dialogContext) => UnifiedColorPickerDialog(
      initialColor: currentColor,
      onColorChanged: onColorChanged,
      onDelete: onDelete,
      canvasRepaintKey: canvasRepaintKey,
      isAddMode: isAddMode,
      isRightHalf: isRightHalf,
      isLeftHalf: isLeftHalf,
      isSpawnedBelow: isSpawnedBelow,
      onPop: () => SmartDialog.dismiss(tag: 'color_picker_popover'),
    ),
  );

  // Wait for the exit animation to finish before releasing the lock
  await Future.delayed(const Duration(milliseconds: 200));
  isColorPickerOpen = false;
}

class GlowingToolButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool hasSettings;
  final bool isSettingsExpanded;
  final ToolbarPosition toolbarPosition;
  final Color activeColor;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const GlowingToolButton({
    Key? key,
    this.toolbarPosition = ToolbarPosition.bottom,
    required this.icon,
    required this.isActive,
    this.hasSettings = false,
    this.isSettingsExpanded = false,
    required this.activeColor,
    required this.tooltip,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isVerticalToolbar = toolbarPosition == ToolbarPosition.left || toolbarPosition == ToolbarPosition.right;
    
    Widget buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.symmetric(
        horizontal: isVerticalToolbar ? 0 : 2,
        vertical: isVerticalToolbar ? 2 : 0,
      ),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withAlpha(35) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? activeColor.withAlpha(80) : Colors.transparent,
          width: 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withAlpha(20),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: toolbarPosition == ToolbarPosition.bottom ? -12 : null,
            bottom: toolbarPosition == ToolbarPosition.top ? -12 : null,
            left: toolbarPosition == ToolbarPosition.right ? -12 : null,
            right: toolbarPosition == ToolbarPosition.left ? -12 : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: (hasSettings && isActive) ? 1.0 : 0.0,
              child: AnimatedRotation(
                turns: (isSettingsExpanded && isActive) ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Icon(
                  toolbarPosition == ToolbarPosition.bottom 
                      ? Icons.keyboard_arrow_up
                      : (toolbarPosition == ToolbarPosition.top 
                          ? Icons.keyboard_arrow_down 
                          : (toolbarPosition == ToolbarPosition.right 
                              ? Icons.keyboard_arrow_left 
                              : Icons.keyboard_arrow_right)),
                  size: 14,
                  color: isActive ? activeColor : Colors.grey.shade500,
                  shadows: isActive ? [Shadow(color: activeColor, blurRadius: 6)] : null,
                ),
              ),
            ),
          ),
          Icon(
            icon,
            size: 24,
            color: isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey.shade800),
            shadows: isActive 
                ? [
                    Shadow(color: activeColor, blurRadius: 8),
                    Shadow(color: activeColor, blurRadius: 16),
                  ] 
                : null,
          ),
        ],
      ),
    );

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: buttonContent,
      ),
    );
  }
}

class ModernColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final bool isVertical;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ModernColorSwatch({
    Key? key,
    required this.color,
    required this.isSelected,
    this.isVertical = false,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          horizontal: isVertical ? 0 : 6,
          vertical: isVertical ? 6 : 0,
        ),
        width: isSelected ? 26 : 22,
        height: isSelected ? 26 : 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? Colors.white : (isDark ? Colors.white30 : Colors.black26),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(150),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: color.withAlpha(0),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: isSelected 
            ? Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.computeLuminance() > 0.6 ? Colors.black54 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ) 
            : null,
      ),
    );
  }
}

class ModernAddColorButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isVertical;

  const ModernAddColorButton({
    Key? key,
    required this.onTap,
    this.isVertical = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(
          horizontal: isVertical ? 0 : 6,
          vertical: isVertical ? 6 : 0,
        ),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Color(0xFFFF3B30),
              Color(0xFFFF9500),
              Color(0xFFFFCC00),
              Color(0xFF4CD964),
              Color(0xFF5AC8FA),
              Color(0xFF007AFF),
              Color(0xFF5856D6),
              Color(0xFFFF2D55),
              Color(0xFFFF3B30),
            ],
          ),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            LucideIcons.plus,
            size: 14,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}
