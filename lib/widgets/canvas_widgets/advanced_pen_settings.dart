import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/canvas_controller.dart';
import 'dart:math' as math;
import '../../models/canvas_models.dart';
import '../../painters/canvas_painters.dart';

class AdvancedPenSettingsWindow extends StatefulWidget {
  final CanvasController canvasCtrl;

  final VoidCallback? onPop;

  const AdvancedPenSettingsWindow({super.key, required this.canvasCtrl, this.onPop});

  @override
  State<AdvancedPenSettingsWindow> createState() => _AdvancedPenSettingsWindowState();
}

class _AdvancedPenSettingsWindowState extends State<AdvancedPenSettingsWindow> {
  bool _showAdvancedOptions = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.canvasCtrl,
      builder: (context, _) {
        final isDark = widget.canvasCtrl.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.black87;
        final bgColor = isDark
            ? Colors.grey.shade900.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95);

        return Container(
      width: 320,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.sliders, size: 20, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        'إعدادات القلم المتقدمة',
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: textColor),
                    onPressed: () {
                      if (widget.onPop != null) {
                        widget.onPop!();
                      } else {
                        widget.canvasCtrl.toggleAdvancedPenSettings();
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Live Stroke Preview ---
              LiveStrokePreview(canvasCtrl: widget.canvasCtrl),
              const SizedBox(height: 16),
              
              // --- Pen Types Selection ---
              _buildPenTypeButtons(context, textColor),

              // 1. Opacity Slider
              _buildSliderRow(
                context,
                icon: LucideIcons.droplet,
                label: 'شفافية الحبر',
                value: widget.canvasCtrl.penOpacity,
                min: 0.1,
                max: 1.0,
                onChanged: widget.canvasCtrl.setPenOpacity,
                textColor: textColor,
              ),

              // 2. Stroke Width Precision Slider
              _buildSliderRow(
                context,
                icon: LucideIcons.penTool,
                label: 'حجم القلم الدقيق',
                value: widget.canvasCtrl.strokeWidth,
                min: 1.0,
                max: 50.0,
                onChanged: widget.canvasCtrl.updateStrokeWidth,
                textColor: textColor,
              ),

              // 3. Smoothing / Streamline Slider
              _buildSliderRow(
                context,
                icon: LucideIcons.activity,
                label: 'تنعيم الخط',
                value: widget.canvasCtrl.penSmoothing,
                min: 0.0,
                max: 1.0,
                onChanged: widget.canvasCtrl.setPenSmoothing,
                textColor: textColor,
              ),

              const SizedBox(height: 8),
              
              // Advanced Options Expand Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAdvancedOptions = !_showAdvancedOptions;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'خيارات متقدمة',
                        style: TextStyle(
                            color: textColor.withAlpha(150),
                            fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showAdvancedOptions
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: textColor.withAlpha(150),
                      ),
                    ],
                  ),
                ),
              ),
              
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _showAdvancedOptions
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 24),

                          // 4. Auto-Fill Toggle
                          _buildToggleRow(
                            context,
                            icon: LucideIcons.paintBucket,
                            label: 'تعبئة الأشكال التلقائية',
                            value: widget.canvasCtrl.penAutoFill,
                            onChanged: widget.canvasCtrl.togglePenAutoFill,
                            textColor: textColor,
                          ),

                          // 5. Pressure Sensitivity Toggle
                          _buildToggleRow(
                            context,
                            icon: LucideIcons.mousePointer2,
                            label: 'حساسية الضغط',
                            value: widget.canvasCtrl.penPressureSensitivity,
                            onChanged: widget.canvasCtrl.togglePenPressureSensitivity,
                            textColor: textColor,
                          ),

                          // 6. Palm Rejection Toggle
                          _buildToggleRow(
                            context,
                            icon: LucideIcons.hand,
                            label: 'تجاهل اللمس باليد',
                            value: widget.canvasCtrl.penPalmRejection,
                            onChanged: widget.canvasCtrl.togglePenPalmRejection,
                            textColor: textColor,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPenTypeButtons(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPenButton(
              context,
              type: PenType.ball,
              icon: Icons.edit, // Standard pen/edit
              label: 'جاف',
              textColor: textColor,
            ),
            const SizedBox(width: 8),
            _buildPenButton(
              context,
              type: PenType.fountain,
              icon: Icons.draw, // Fountain pen feel
              label: 'حبر',
              textColor: textColor,
            ),
            const SizedBox(width: 8),
            _buildPenButton(
              context,
              type: PenType.brush,
              icon: Icons.brush,
              label: 'فرشاة',
              textColor: textColor,
            ),
            const SizedBox(width: 8),
            _buildPenButton(
              context,
              type: PenType.pencil,
              icon: Icons.mode_edit_outline, // Pencil like
              label: 'رصاص',
              textColor: textColor,
            ),
            const SizedBox(width: 8),
            _buildPenButton(
              context,
              type: PenType.perfect,
              icon: LucideIcons.penTool, // Perfect pen
              label: 'واقعي',
              textColor: textColor,
            ),
            const SizedBox(width: 8),
            _buildPenButton(
              context,
              type: PenType.velocity,
              icon: LucideIcons.wand2, // Velocity (smart)
              label: 'ذكي',
              textColor: textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenButton(
    BuildContext context, {
    required PenType type,
    required IconData icon,
    required String label,
    required Color textColor,
  }) {
    final isSelected = widget.canvasCtrl.currentPenType == type;
    final activeColor = const Color(0xFFFF7F6A);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.canvasCtrl.setPenType(type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : textColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? activeColor : textColor.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: textColor, fontSize: 13)),
              const Spacer(),
              Text(
                max > 1.0 ? value.toStringAsFixed(1) : '${(value * 100).toInt()}%',
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.6), fontSize: 12),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: const Color(0xFFFF7F6A),
              inactiveColor: const Color(0xFFFF7F6A).withValues(alpha: 0.2),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: textColor, fontSize: 13)),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFFF7F6A),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveStrokePreview extends StatelessWidget {
  final CanvasController canvasCtrl;

  const LiveStrokePreview({super.key, required this.canvasCtrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: canvasCtrl,
      builder: (context, _) {
        return Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: canvasCtrl.isDarkMode ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canvasCtrl.isDarkMode ? Colors.white12 : Colors.black12,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _LiveStrokePreviewPainter(canvasCtrl),
            ),
          ),
        );
      },
    );
  }
}

class _LiveStrokePreviewPainter extends CustomPainter {
  final CanvasController canvasCtrl;

  _LiveStrokePreviewPainter(this.canvasCtrl);

  List<DrawingPoint?> _getPreviewPoints(Size size) {
    final List<DrawingPoint?> points = [];
    final w = size.width;
    final h = size.height;

    double effectiveStrokeWidth = canvasCtrl.strokeWidth;
    MaskFilter? effectiveMaskFilter;

    switch (canvasCtrl.currentPenType) {
      case PenType.fountain:
        effectiveStrokeWidth = canvasCtrl.strokeWidth * 1.2;
        effectiveMaskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
        break;
      case PenType.brush:
        effectiveStrokeWidth = canvasCtrl.strokeWidth * 1.8;
        effectiveMaskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        break;
      case PenType.perfect:
      case PenType.velocity:
        effectiveStrokeWidth = canvasCtrl.strokeWidth * 1.5;
        break;
      default:
        break;
    }

    for (double t = 0; t <= 1.0; t += 0.01) {
      double x = w * 0.1 + t * (w * 0.8);
      double y = h / 2 + math.sin(t * math.pi * 2) * (h * 0.25);
      
      // Smoothly vary pressure to demonstrate pressure sensitivity
      double pressure = 0.3 + 0.7 * math.sin(t * math.pi);

      final ptPaint = Paint()
        ..color = canvasCtrl.selectedColor.withValues(alpha: canvasCtrl.penOpacity)
        ..strokeWidth = effectiveStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (effectiveMaskFilter != null) {
        ptPaint.maskFilter = effectiveMaskFilter;
      }

      points.add(DrawingPoint(
        Offset(x, y),
        ptPaint,
        pressure: pressure,
        penType: canvasCtrl.currentPenType,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        lineType: canvasCtrl.currentLineType,
        smoothing: canvasCtrl.penSmoothing,
        autoFill: canvasCtrl.penAutoFill,
        simulatePressure: canvasCtrl.penPressureSensitivity,
      ));
    }
    return points;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final points = _getPreviewPoints(size);
    // Use an empty PageTemplate since we don't need background rendering for the single stroke preview
    final painter = DrawingPainter(
      points,
      const PageTemplate(),
      isDarkMode: canvasCtrl.isDarkMode,
      version: 0,
    );
    painter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _LiveStrokePreviewPainter oldDelegate) {
    return true; // Repaint since ListenableBuilder triggers rebuild anyway
  }
}
