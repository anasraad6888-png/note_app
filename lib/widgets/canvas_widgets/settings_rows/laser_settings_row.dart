import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/canvas_controller.dart';
import 'shared_settings_helpers.dart';

class LaserSettingsRow extends StatelessWidget {
  final CanvasController canvasCtrl;
  final bool reversed;
  final bool isVertical;

  const LaserSettingsRow({
    super.key,
    required this.canvasCtrl,
    this.reversed = false,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      // Laser Mode Toggle
      Container(
        height: isVertical ? null : 30,
        width: isVertical ? 30 : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: canvasCtrl.isDarkMode ? Colors.black.withAlpha(70) : Colors.black.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canvasCtrl.isDarkMode ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
            width: 1,
          ),
        ),
        child: Flex(
          direction: isVertical ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildModeButton(
              icon: LucideIcons.activity,
              isActive: !canvasCtrl.isLaserDot,
              activeColor: canvasCtrl.laserColor,
              isDarkMode: canvasCtrl.isDarkMode,
              isVertical: isVertical,
              tooltip: 'ليزر ذو أثر (Comet)',
              onTap: () {
                canvasCtrl.isLaserDot = false;
                canvasCtrl.notifyListeners();
              },
            ),
            SizedBox(width: isVertical ? 0 : 2, height: isVertical ? 2 : 0),
            _buildModeButton(
              icon: LucideIcons.circleDot,
              isActive: canvasCtrl.isLaserDot,
              activeColor: canvasCtrl.laserColor,
              isDarkMode: canvasCtrl.isDarkMode,
              isVertical: isVertical,
              tooltip: 'نقطة مؤشر فقط (Pointer)',
              onTap: () {
                canvasCtrl.isLaserDot = true;
                canvasCtrl.notifyListeners();
              },
            ),
          ],
        ),
      ),
      SizedBox(width: isVertical ? 0 : 8, height: isVertical ? 8 : 0),
      buildSettingsDivider(canvasCtrl, isVertical: isVertical),
      SizedBox(width: isVertical ? 0 : 8, height: isVertical ? 8 : 0),
      // Colors
      ...canvasCtrl.defaultLaserColors.asMap().entries.map((entry) {
        final int index = entry.key;
        final Color c = entry.value;
        final bool isSelected = canvasCtrl.laserColor == c;

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
                      canvasCtrl.changeDefaultLaserColor(index, newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: (canvasCtrl.defaultLaserColors.length + canvasCtrl.customLaserColors.length) > 3
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
                onDelete: (canvasCtrl.defaultLaserColors.length + canvasCtrl.customLaserColors.length) > 3
                    ? () => canvasCtrl.deleteDefaultLaserColor(index)
                    : null,
              );
            },
          ),
        );
      }),
      ...canvasCtrl.customLaserColors.asMap().entries.map((entry) {
        final int index = entry.key;
        final Color c = entry.value;
        final bool isSelected = canvasCtrl.laserColor == c;

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
                      canvasCtrl.changeCustomLaserColor(index, newColor),
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: (canvasCtrl.defaultLaserColors.length + canvasCtrl.customLaserColors.length) > 3
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
                onDelete: (canvasCtrl.defaultLaserColors.length + canvasCtrl.customLaserColors.length) > 3
                    ? () => canvasCtrl.deleteCustomLaserColor(index)
                    : null,
              );
            },
          ),
        );
      }),
      if (canvasCtrl.customLaserColors.length < 7)
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
                  currentColor: canvasCtrl.laserColor,
                  onColorChanged: (newColor) {
                    if (isFirstChange) {
                      canvasCtrl.addCustomLaserColor(newColor);
                      addedIndex = canvasCtrl.customLaserColors.length - 1;
                      canvasCtrl.updateLaserColor(newColor);
                      isFirstChange = false;
                    } else {
                      canvasCtrl.changeCustomLaserColor(addedIndex, newColor);
                      canvasCtrl.updateLaserColor(newColor);
                    }
                  },
                  canvasRepaintKey: canvasCtrl.canvasRepaintKey,
                  canvasCtrl: canvasCtrl,
                  onDelete: () {
                    if (!isFirstChange && addedIndex != -1) {
                      canvasCtrl.deleteCustomLaserColor(addedIndex);
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

  Widget _buildModeButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required bool isDarkMode,
    required bool isVertical,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: isVertical ? 5 : 9,
            vertical: isVertical ? 9 : 3,
          ),
          decoration: BoxDecoration(
            color: isActive 
                ? activeColor.withAlpha(40)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? activeColor.withAlpha(80) : Colors.transparent,
              width: 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(30),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive 
                ? activeColor 
                : (isDarkMode ? Colors.white54 : Colors.black54),
            shadows: isActive 
                ? [
                    Shadow(color: activeColor, blurRadius: 4),
                    Shadow(color: activeColor, blurRadius: 12),
                  ] 
                : null,
          ),
        ),
      ),
    );
  }
}
