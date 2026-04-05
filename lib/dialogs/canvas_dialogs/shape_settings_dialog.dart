import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../painters/canvas_painters.dart';
import '../../controllers/canvas_controller.dart';
import '../../widgets/custom_popover.dart';
import 'dialog_helpers.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class ShapeSettingsDialog {
  static void showShapeSettingsDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
    required bool isTopHalf,
    Alignment? alignment,
  }) {
    final bool isDarkMode = canvasCtrl.isDarkMode;
    showCustomPopover(
      context: context,
      isTopHalf: isTopHalf,
      alignment: alignment,
      width: 320,
      backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Theme.of(context).cardColor,
      bodyBuilder: (dialogContext) {
        bool isAtBottom = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bgColor = isDarkMode ? const Color(0xFF2C2C2E) : Theme.of(context).cardColor;
            final double screenHeight = MediaQueryData.fromView(View.of(context)).size.height;
            return Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.60,
            ),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.axis == Axis.vertical) {
                      bool newIsAtBottom = scrollInfo.metrics.maxScrollExtent <= 0 ||
                          scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 10.0;
                      if (newIsAtBottom != isAtBottom) {
                        Future.microtask(() {
                          if (context.mounted) {
                            setDialogState(() {
                              isAtBottom = newIsAtBottom;
                            });
                          }
                        });
                      }
                    }
                    return false;
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'إعدادات الأشكال',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                              tooltip: 'إغلاق',
                              onPressed: () {
                                SmartDialog.dismiss(tag: 'custom_popover');
                              },
                            ),
                          ],
                        ),
                  const SizedBox(height: 12),
                  // Preview Area
                Container(
                  height: 90,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withAlpha(30) : Colors.grey.withAlpha(50),
                    ),
                  ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: ShapePreviewPainter(
                            type: canvasCtrl.selectedShapeType,
                            borderWidth: canvasCtrl.shapeBorderWidth,
                            borderColor: canvasCtrl.shapeBorderColor,
                            fillColor: canvasCtrl.shapeFillColor,
                            lineType: canvasCtrl.shapeLineType,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ),
                ),
                
                CanvasDialogHelpers.buildSettingsCard(
                  context: context,
                  isDarkMode: isDarkMode,
                  children: [
                    Text(
                      'نوع الشكل',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 104,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode,
                              canvasCtrl.selectedShapeType,
                              setDialogState,
                              'rectangle',
                              LucideIcons.square,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode,
                              canvasCtrl.selectedShapeType,
                              setDialogState,
                              'circle',
                              LucideIcons.circle,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode,
                              canvasCtrl.selectedShapeType,
                              setDialogState,
                              'triangle',
                              LucideIcons.triangle,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode,
                              canvasCtrl.selectedShapeType,
                              setDialogState,
                              'line',
                              LucideIcons.minus,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode,
                              canvasCtrl.selectedShapeType,
                              setDialogState,
                              'arrow',
                              LucideIcons.arrowRight,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode,
                              canvasCtrl.selectedShapeType,
                              setDialogState,
                              'sin',
                              null,
                              label: 'sin',
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode,
                              canvasCtrl.selectedShapeType,
                              setDialogState,
                              'cos',
                              null,
                              label: 'cos',
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'star', LucideIcons.star,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'diamond', LucideIcons.gem,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'pentagon', Icons.pentagon_outlined,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'hexagon', LucideIcons.hexagon,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'cross', LucideIcons.plus,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'cloud', LucideIcons.cloud,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'heart', LucideIcons.heart,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'cylinder', LucideIcons.database,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'cube', LucideIcons.box,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'parallelogram', LucideIcons.layers,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'octagon', LucideIcons.octagon,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'heptagon', null, 
                              customIcon: SizedBox(
                                width: 24, height: 24,
                                child: CustomPaint(
                                  painter: ShapePreviewPainter(
                                    type: 'heptagon',
                                    borderWidth: 2,
                                    borderColor: canvasCtrl.selectedShapeType == 'heptagon' ? (isDarkMode ? Colors.amber : Colors.blue) : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                                    fillColor: Colors.transparent,
                                    lineType: 0,
                                  ),
                                ),
                              ),
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'trapezoid', null,
                              customIcon: SizedBox(
                                width: 24, height: 24,
                                child: CustomPaint(
                                  painter: ShapePreviewPainter(
                                    type: 'trapezoid',
                                    borderWidth: 2,
                                    borderColor: canvasCtrl.selectedShapeType == 'trapezoid' ? (isDarkMode ? Colors.amber : Colors.blue) : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                                    fillColor: Colors.transparent,
                                    lineType: 0,
                                  ),
                                ),
                              ),
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'semi_circle', null,
                              customIcon: SizedBox(
                                width: 24, height: 24,
                                child: CustomPaint(
                                  painter: ShapePreviewPainter(
                                    type: 'semi_circle',
                                    borderWidth: 2,
                                    borderColor: canvasCtrl.selectedShapeType == 'semi_circle' ? (isDarkMode ? Colors.amber : Colors.blue) : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                                    fillColor: Colors.transparent,
                                    lineType: 0,
                                  ),
                                ),
                              ),
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'right_triangle', null,
                              customIcon: SizedBox(
                                width: 24, height: 24,
                                child: CustomPaint(
                                  painter: ShapePreviewPainter(
                                    type: 'right_triangle',
                                    borderWidth: 2,
                                    borderColor: canvasCtrl.selectedShapeType == 'right_triangle' ? (isDarkMode ? Colors.amber : Colors.blue) : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                                    fillColor: Colors.transparent,
                                    lineType: 0,
                                  ),
                                ),
                              ),
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'x_mark', LucideIcons.x,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'teardrop', LucideIcons.droplet,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'speech_bubble', LucideIcons.messageSquare,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'crescent', LucideIcons.moon,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                            CanvasDialogHelpers.shapeGridItem(
                              isDarkMode, canvasCtrl.selectedShapeType, setDialogState,
                              'flag', LucideIcons.flag,
                              onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                CanvasDialogHelpers.buildSettingsCard(
                  context: context,
                  isDarkMode: isDarkMode,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 0),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              'الخط',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  canvasCtrl.shapeBorderWidth.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? const Color(0xFFFF7F6A) : Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.black26 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () { canvasCtrl.shapeLineType = 0; canvasCtrl.notifyListeners(); setDialogState((){}); },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: canvasCtrl.shapeLineType == 0 ? const Color(0xFFFF7F6A) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('متصل', style: TextStyle(color: canvasCtrl.shapeLineType == 0 ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87), fontSize: 12, fontWeight: canvasCtrl.shapeLineType == 0 ? FontWeight.bold : FontWeight.normal)),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () { canvasCtrl.shapeLineType = 1; canvasCtrl.notifyListeners(); setDialogState((){}); },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: canvasCtrl.shapeLineType == 1 ? const Color(0xFFFF7F6A) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('متقطع', style: TextStyle(color: canvasCtrl.shapeLineType == 1 ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87), fontSize: 12, fontWeight: canvasCtrl.shapeLineType == 1 ? FontWeight.bold : FontWeight.normal)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 36,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: canvasCtrl.shapeBorderWidth,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          activeColor: const Color(0xFFFF7F6A),
                          inactiveColor: isDarkMode ? Colors.white12 : Colors.black12,
                          onChanged: (v) {
                            canvasCtrl.shapeBorderWidth = v;
                            canvasCtrl.notifyListeners();
                            setDialogState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                Row(
                  children: [
                    Expanded(
                      child: CanvasDialogHelpers.buildModernColorPicker(
                        context: context,
                        isDarkMode: isDarkMode,
                        setDialogState: setDialogState,
                        title: 'لون الإطار',
                        color: canvasCtrl.shapeBorderColor,
                        canvasCtrl: canvasCtrl,
                        onColorChanged: (c) {
                          canvasCtrl.shapeBorderColor = c;
                          canvasCtrl.notifyListeners();
                          setDialogState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CanvasDialogHelpers.buildModernColorPicker(
                        context: context,
                        isDarkMode: isDarkMode,
                        setDialogState: setDialogState,
                        title: 'التعبئة',
                        color: canvasCtrl.shapeFillColor,
                        canvasCtrl: canvasCtrl,
                        onColorChanged: (c) {
                          canvasCtrl.shapeFillColor = c;
                          canvasCtrl.notifyListeners();
                          setDialogState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ).animate().fade(duration: 200.ms).slideY(begin: 0.1, duration: 200.ms),
          ),
        ),
        ),

        // Fading down arrow indicator
        if (!isAtBottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor.withOpacity(0.0),
                      bgColor.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 20,
                    color: isDarkMode ? Colors.white30 : Colors.black38,
                  ),
                ),
              ),
            ),
          ),

      ],
    ),
  );
},
        );
      },
    );
  }
}
