import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// Snap-worthy angles in radians (0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°)
const List<double> _kSnapAnglesRad = [
  0,
  math.pi / 4,
  math.pi / 2,
  3 * math.pi / 4,
  math.pi,
  5 * math.pi / 4,
  3 * math.pi / 2,
  7 * math.pi / 4,
];
const double _kSnapThresholdRad = 3.0 * math.pi / 180; // ±3 degrees

double _normalizeAngle(double a) {
  a = a % (2 * math.pi);
  if (a < 0) a += 2 * math.pi;
  return a;
}

double _snapAngle(double a) {
  a = _normalizeAngle(a);
  for (final snap in _kSnapAnglesRad) {
    double diff = (a - snap).abs();
    // Handle wrap-around (e.g. 359° vs 0°)
    if (diff > math.pi) diff = 2 * math.pi - diff;
    if (diff <= _kSnapThresholdRad) return snap;
  }
  return a;
}

class RulerWidget extends StatefulWidget {
  final Offset initialPosition;
  final double initialAngle;
  final Function(Offset, double) onChanged;
  final VoidCallback onClose;
  /// Current stroke length in pixels (null = no active stroke)
  final double? strokeLength;
  /// Pen cursor position in ruler-local X coords (null = not drawing near ruler)
  final double? cursorLocalX;
  /// Which edge the pen is on: -1=top, 0=none, +1=bottom
  final int cursorEdge;

  const RulerWidget({
    super.key,
    required this.initialPosition,
    required this.initialAngle,
    required this.onChanged,
    required this.onClose,
    this.strokeLength,
    this.cursorLocalX,
    this.cursorEdge = 0,
  });

  @override
  State<RulerWidget> createState() => _RulerWidgetState();
}

class _RulerWidgetState extends State<RulerWidget> {
  late Offset position;
  late double angle;
  double _startAngle = 0.0;
  bool _wasSnapped = false;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    angle = widget.initialAngle;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final screenSize = MediaQuery.of(context).size;
    // Safe zones: ruler center must stay away from toolbars
    const double kTopSafeZone = 90.0;    // ≈ top toolbar height
    const double kBottomSafeZone = 90.0; // ≈ bottom toolbar height
    const double rulerH = 80.0;

    setState(() {
      // Translate: convert focal delta to global space accounting for rotation
      double cosA = math.cos(angle);
      double sinA = math.sin(angle);
      double localDx = details.focalPointDelta.dx;
      double localDy = details.focalPointDelta.dy;
      double globalDx = localDx * cosA - localDy * sinA;
      double globalDy = localDx * sinA + localDy * cosA;

      Offset newPos = position + Offset(globalDx, globalDy);

      // Clamp so the ruler centre never enters the toolbar safe zones
      newPos = Offset(
        newPos.dx.clamp(0.0, screenSize.width),
        newPos.dy.clamp(kTopSafeZone + rulerH / 2,
                        screenSize.height - kBottomSafeZone - rulerH / 2),
      );
      position = newPos;

      if (details.pointerCount > 1) {
        double rawAngle = _normalizeAngle(_startAngle + details.rotation);
        double snapped = _snapAngle(rawAngle);
        bool isSnapped = (snapped - rawAngle).abs() < _kSnapThresholdRad;

        if (isSnapped && !_wasSnapped) {
          HapticFeedback.lightImpact();
          _wasSnapped = true;
        } else if (!isSnapped) {
          _wasSnapped = false;
        }
        angle = snapped;
      }
    });
    widget.onChanged(position, angle);
  }

  @override
  Widget build(BuildContext context) {
    const double rulerW = 760;
    const double rulerH = 80;

    return Positioned(
      left: position.dx - rulerW / 2,
      top: position.dy - rulerH / 2,
      width: rulerW,
      height: rulerH,
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (d) => _startAngle = angle,
          onScaleUpdate: _handleScaleUpdate,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Ruler body ──────────────────────────────────────────────
              CustomPaint(
                size: const Size(rulerW, rulerH),
                painter: _RulerPainter(
                  angle: angle,
                  cursorLocalX: widget.cursorLocalX,
                  cursorEdge: widget.cursorEdge,
                ),
              ),

              // ── Close button ────────────────────────────────────────────
              Positioned(
                right: 10,
                top: rulerH / 2 - 14,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

              // ── Stroke-length label (shown while actively drawing) ──────
              if (widget.strokeLength != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -28,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.strokeLength!.toStringAsFixed(1)} px',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double angle;
  final double? cursorLocalX;
  final int cursorEdge;
  _RulerPainter({required this.angle, this.cursorLocalX, this.cursorEdge = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // ── Body: translucent blue-grey (70% opacity) ───────────────────────
    final bodyPaint = Paint()
      ..color = const Color(0xB3546E7A) // Blue-grey 700 at 70%
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, bodyPaint);

    // ── Top edge highlight (cyan) ───────────────────────────────────────
    final topEdgePaint = Paint()
      ..color = Colors.cyanAccent.withAlpha(200)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(12, 0), Offset(size.width - 12, 0), topEdgePaint);

    // ── Bottom edge highlight (amber) ──────────────────────────────────
    final bottomEdgePaint = Paint()
      ..color = Colors.amberAccent.withAlpha(200)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(12, size.height),
      Offset(size.width - 12, size.height),
      bottomEdgePaint,
    );

    // ── Border ─────────────────────────────────────────────────────────
    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // ── Tick marks ────────────────────────────────────────────────────
    // 1 cm ≈ 38px. Subdivisions: 10mm (full cm), 5mm (half), 2mm
    const double cmPx = 38.0;
    const double mmPx = cmPx / 10; // 3.8 px per mm

    final tickPaint = Paint()
      ..color = Colors.white.withAlpha(220)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    int totalMm = (size.width / mmPx).floor();

    for (int mm = 1; mm <= totalMm; mm++) {
      double x = mm * mmPx;
      bool isCm     = mm % 10 == 0;
      bool isHalfCm = mm % 5 == 0 && !isCm;
      // bool isMm     = !isCm && !isHalfCm;

      double topLen    = isCm ? 18 : (isHalfCm ? 10 : 5);
      double bottomLen = isCm ? 18 : (isHalfCm ? 10 : 5);

      // Top ticks
      canvas.drawLine(Offset(x, 0), Offset(x, topLen), tickPaint);
      // Bottom ticks
      canvas.drawLine(Offset(x, size.height), Offset(x, size.height - bottomLen), tickPaint);

      // cm number labels (both edges)
      if (isCm) {
        int cmNum = mm ~/ 10;

        // Top label
        textPainter.text = TextSpan(
          text: '$cmNum',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, topLen + 2));

        // Bottom label
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - bottomLen - textPainter.height - 2),
        );
      }
    }

    // ── Angle badge in the centre ─────────────────────────────────────
    int degree = (angle * 180 / math.pi).round() % 360;
    if (degree < 0) degree += 360;

    textPainter.text = TextSpan(
      text: '$degree°',
      style: const TextStyle(
        color: Colors.amberAccent,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      22,
      Paint()..color = Colors.black.withAlpha(160),
    );
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2),
    );

    // ── Edge labels ──────────────────────────────────────────────────
    final labelStyle = const TextStyle(fontSize: 9, fontWeight: FontWeight.w600);
    textPainter.text = TextSpan(text: '▲ TOP', style: labelStyle.copyWith(color: Colors.cyanAccent.withAlpha(180)));
    textPainter.layout();
    textPainter.paint(canvas, Offset(16, 2));

    textPainter.text = TextSpan(text: '▼ BOT', style: labelStyle.copyWith(color: Colors.amberAccent.withAlpha(180)));
    textPainter.layout();
    textPainter.paint(canvas, Offset(16, size.height - textPainter.height - 2));

    // ── Live cursor indicator ─────────────────────────────────────────
    if (cursorLocalX != null && cursorEdge != 0) {
      // Convert ruler-local X to widget-local X (ruler centre is at width/2)
      final double cx = size.width / 2 + cursorLocalX!;
      final bool isTop = cursorEdge == -1;
      final double edgeY = isTop ? 0.0 : size.height;
      final Color edgeColor = isTop ? Colors.cyanAccent : Colors.amberAccent;

      // Glow behind the cursor dot
      canvas.drawCircle(
        Offset(cx, edgeY),
        14,
        Paint()
          ..color = edgeColor.withAlpha(60)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Bright dot ON the edge
      canvas.drawCircle(
        Offset(cx, edgeY),
        5,
        Paint()..color = edgeColor,
      );

      // Pointer triangle pointing away from the ruler body
      final double tipY = isTop ? -10.0 : size.height + 10.0;
      final double baseY = isTop ? -2.0 : size.height + 2.0;
      final path = Path()
        ..moveTo(cx, tipY)
        ..lineTo(cx - 5, baseY)
        ..lineTo(cx + 5, baseY)
        ..close();
      canvas.drawPath(path, Paint()..color = edgeColor);

      // Thin vertical hair line across the ruler body for reference
      canvas.drawLine(
        Offset(cx, 0),
        Offset(cx, size.height),
        Paint()
          ..color = edgeColor.withAlpha(60)
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.angle != angle ||
      old.cursorLocalX != cursorLocalX ||
      old.cursorEdge != cursorEdge;
}
