import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/canvas_controller.dart';
import '../../models/canvas_models.dart';
import 'drawing_tools_row.dart';

class CanvasToolPalette extends StatelessWidget {
  final CanvasController canvasCtrl;
  final AudioController audioCtrl;

  const CanvasToolPalette({
    super.key,
    required this.canvasCtrl,
    required this.audioCtrl,
  });

  @override
  Widget build(BuildContext context) {
    if (canvasCtrl.toolbarPosition == ToolbarPosition.top)
      return const SizedBox.shrink();

    Widget completePalette = _buildPaletteContainer(context);

    Widget palette = Draggable<String>(
      data: 'dock_tools',
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: _buildPaletteContainer(context, isFeedback: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.0,
        child: _buildPaletteContainer(context, isFeedback: true), // Safe to use isFeedback: true since it will omit the key
      ),
      onDragStarted: () => canvasCtrl.setDraggingPalette(true),
      onDragEnd: (_) => canvasCtrl.setDraggingPalette(false),
      onDraggableCanceled: (_, _) => canvasCtrl.setDraggingPalette(false),
      child: completePalette,
    );
    Widget sideSliders = _buildSideSliders(context);

    // وضع العناصر في Stack يغطي مساحة العمل لضمان صحة الـ Hit-Testing
    return Positioned.fill(
      child: Stack(
        children: [
          // 1. السلايدرات (بحركة انسيابية عكس اتجاه الشريط)
          AnimatedAlign(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutExpo,
            alignment: canvasCtrl.toolbarPosition == ToolbarPosition.right
                ? const Alignment(-0.95, -0.2)
                : const Alignment(0.95, -0.2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: canvasCtrl.isDraggingPalette ? 0.0 : 1.0,
              child: sideSliders,
            ),
          ),

          // 2. الشريط الأساسي (بحركة انسيابية سينمائية)
          AnimatedAlign(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutExpo,
            alignment: canvasCtrl.toolbarPosition == ToolbarPosition.left
                ? Alignment.centerLeft
                : (canvasCtrl.toolbarPosition == ToolbarPosition.right
                      ? Alignment.centerRight
                      : Alignment.bottomCenter),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutExpo,
              padding: EdgeInsets.only(
                left: canvasCtrl.toolbarPosition == ToolbarPosition.left
                    ? 10
                    : 0,
                right: canvasCtrl.toolbarPosition == ToolbarPosition.right
                    ? 10
                    : 0,
                bottom: canvasCtrl.toolbarPosition == ToolbarPosition.bottom
                    ? (canvasCtrl.isZoomWindowVisible ? 230 : 20)
                    : 0,
              ),
              child: palette,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideSliders(BuildContext context) {
    if (!canvasCtrl.isZoomSliderVisible) return const SizedBox.shrink();

    // Compute the minimum allowed scale: the scale at which all pages
    // fit exactly in the viewport (height-driven, as pages are taller than they are wide).
    final screenSize = canvasCtrl.viewportSize ?? MediaQuery.of(context).size;
    final int pageCount = canvasCtrl.pagesPoints.isNotEmpty
        ? canvasCtrl.pagesPoints.length
        : 1;
    final double totalContentH = 16.0 + pageCount * 940.0 + 16.0;
    final double minScaleH = screenSize.height / totalContentH;
    final double minScaleW = screenSize.width / 700.0;
    final double minScale = (minScaleH < minScaleW ? minScaleH : minScaleW)
        .clamp(0.05, 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: canvasCtrl.isDarkMode
                ? Colors.grey.shade800.withAlpha(240)
                : Colors.white.withAlpha(240),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
            ],
          ),
          child: RotatedBox(
            quarterTurns: 3,
            child: ValueListenableBuilder<Matrix4>(
              valueListenable: canvasCtrl.transformationController,
              builder: (context, matrix, _) {
                final currentScale = matrix.getMaxScaleOnAxis().clamp(minScale, 5.0);
                return Slider(
                  value: math.log(currentScale),
                  min: math.log(minScale),
                  max: math.log(5.0),
                  activeColor: Colors.blueGrey,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: (val) =>
                      canvasCtrl.setZoom(math.exp(val), MediaQuery.of(context).size),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteContainer(
    BuildContext context, {
    bool isFeedback = false,
  }) {
    bool isVertical =
        canvasCtrl.toolbarPosition == ToolbarPosition.left ||
        canvasCtrl.toolbarPosition == ToolbarPosition.right;

    Widget toolsContent = DrawingToolsRow(
      canvasCtrl: canvasCtrl,
      audioCtrl: audioCtrl,
      direction: isVertical ? Axis.vertical : Axis.horizontal,
    );

    Widget? settingsContent;
    if (canvasCtrl.isSettingsMagnetActive &&
        (canvasCtrl.showPenSettingsRow ||
            canvasCtrl.showHighlighterSettingsRow ||
            canvasCtrl.showLaserSettingsRow ||
            canvasCtrl.showEraserSettingsRow ||
            canvasCtrl.showLassoSettingsRow ||
            canvasCtrl.showTextSettingsRow ||
            canvasCtrl.showAddSettingsRow)) {
      settingsContent =
          Container(
                key: isFeedback ? null : canvasCtrl.dockedSettingsKey,
                padding: EdgeInsets.symmetric(
                  horizontal: isVertical ? 6 : 16, 
                  vertical: isVertical ? 16 : 6,
                ),
                decoration: BoxDecoration(
                  color: canvasCtrl.isDarkMode ? const Color(0xD926262A) : const Color(0xE6F5F5F7),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: canvasCtrl.isDarkMode ? Colors.black.withAlpha(60) : Colors.black.withAlpha(20),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
                    child: DrawingToolsRow.buildSettingsRow(
                      canvasCtrl,
                      context,
                      reversed: canvasCtrl.toolbarPosition == ToolbarPosition.right,
                      isVertical: isVertical,
                    ),
                  ),
                ),
              )
              .animate()
              .fade(duration: 200.ms)
              .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
    }

    Widget mainContainer = AnimatedSize(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutExpo,
      child: isVertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [toolsContent],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [toolsContent],
            ),
    );

    Widget result;
    if (isFeedback) {
      result = mainContainer;
    } else {
      if (canvasCtrl.toolbarPosition == ToolbarPosition.bottom) {
        result = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            settingsContent ?? const SizedBox.shrink(),
            settingsContent != null ? const SizedBox(height: 8) : const SizedBox.shrink(),
            mainContainer,
          ],
        );
      } else if (canvasCtrl.toolbarPosition == ToolbarPosition.left) {
        result = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            mainContainer,
            settingsContent != null ? const SizedBox(width: 8) : const SizedBox.shrink(),
            settingsContent ?? const SizedBox.shrink(),
          ],
        );
      } else if (canvasCtrl.toolbarPosition == ToolbarPosition.right) {
        result = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            settingsContent ?? const SizedBox.shrink(),
            settingsContent != null ? const SizedBox(width: 8) : const SizedBox.shrink(),
            mainContainer,
          ],
        );
      } else {
        result = mainContainer;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: result,
      ),
    );
  }
}
