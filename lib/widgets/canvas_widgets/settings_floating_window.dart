import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/canvas_controller.dart';
import 'drawing_tools_row.dart';

class CanvasSettingsFloatingWindow extends StatelessWidget {
  final CanvasController canvasCtrl;

  const CanvasSettingsFloatingWindow({super.key, required this.canvasCtrl});

  @override
  Widget build(BuildContext context) {
    if (canvasCtrl.isSettingsMagnetActive) return const SizedBox.shrink();

    if (!canvasCtrl.showPenSettingsRow &&
        !canvasCtrl.showHighlighterSettingsRow &&
        !canvasCtrl.showLaserSettingsRow &&
        !canvasCtrl.showTextSettingsRow &&
        !canvasCtrl.showEraserSettingsRow &&
        !canvasCtrl.showLassoSettingsRow) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isRightSide = canvasCtrl.settingsWindowPosition.dx > screenWidth / 2;

    return Positioned(
      left: canvasCtrl.settingsWindowPosition.dx,
      top: canvasCtrl.settingsWindowPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          canvasCtrl.updateSettingsWindowPosition(details.delta);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: canvasCtrl.isDarkMode
                ? Colors.grey.shade900.withAlpha(240)
                : Colors.white.withAlpha(240),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: canvasCtrl.isDarkMode ? Colors.white10 : Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DrawingToolsRow.buildSettingsRow(canvasCtrl, context, reversed: isRightSide),
            ],
          ),
        ).animate().fade(duration: 200.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
      ),
    );
  }
}
