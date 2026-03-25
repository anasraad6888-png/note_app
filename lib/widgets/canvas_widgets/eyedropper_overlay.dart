import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EyedropperOverlay extends StatefulWidget {
  final ui.Image capturedImage;
  
  const EyedropperOverlay({super.key, required this.capturedImage});

  @override
  State<EyedropperOverlay> createState() => _EyedropperOverlayState();
}

class _EyedropperOverlayState extends State<EyedropperOverlay> {
  Offset? currentPosition;
  Color hoveredColor = Colors.transparent;
  ByteData? byteData;
  int imageWidth = 0;

  @override
  void initState() {
    super.initState();
    _loadByteData();
  }

  Future<void> _loadByteData() async {
    byteData = await widget.capturedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    imageWidth = widget.capturedImage.width;
    setState(() {});
  }

  void _updateColor(Offset position) {
    if (byteData == null) return;
    
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    int x = (position.dx * pixelRatio).toInt();
    int y = (position.dy * pixelRatio).toInt();

    if (x < 0 || x >= widget.capturedImage.width || y < 0 || y >= widget.capturedImage.height) return;

    int offset = (y * imageWidth + x) * 4;
    
    int r = byteData!.getUint8(offset);
    int g = byteData!.getUint8(offset + 1);
    int b = byteData!.getUint8(offset + 2);
    int a = byteData!.getUint8(offset + 3);

    setState(() {
      hoveredColor = Color.fromARGB(a, r, g, b);
      currentPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) => _updateColor(details.globalPosition),
              onPanUpdate: (details) => _updateColor(details.globalPosition),
              onPanEnd: (details) {
                if (currentPosition != null) {
                  Navigator.of(context).pop(hoveredColor);
                } else {
                  Navigator.of(context).pop();
                }
              },
              onTapUp: (details) {
                 _updateColor(details.globalPosition);
                 Navigator.of(context).pop(hoveredColor);
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          if (currentPosition != null)
            Positioned(
              left: currentPosition!.dx - 50,
              top: currentPosition!.dy - 120, // Float above the finger
              child: IgnorePointer(
                child: CustomPaint(
                  painter: MagnifyingLoupePainter(
                    hoveredColor: hoveredColor,
                    capturedImage: widget.capturedImage,
                    centerPosition: currentPosition!,
                    devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                  ),
                  size: const Size(100, 100),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MagnifyingLoupePainter extends CustomPainter {
  final Color hoveredColor;
  final ui.Image capturedImage;
  final Offset centerPosition;
  final double devicePixelRatio;

  MagnifyingLoupePainter({
    required this.hoveredColor,
    required this.capturedImage,
    required this.centerPosition,
    required this.devicePixelRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.width / 2;
    Offset center = Offset(radius, radius);

    // 1. Draw backdrop shadow
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Draw zoomed image clip
    canvas.save();
    Path clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    double zoom = 2.0;

    double srcCx = centerPosition.dx * devicePixelRatio;
    double srcCy = centerPosition.dy * devicePixelRatio;
    double srcRadius = (radius * devicePixelRatio) / zoom;
    
    Rect srcRect = Rect.fromCenter(
      center: Offset(srcCx, srcCy),
      width: srcRadius * 2,
      height: srcRadius * 2,
    );

    Rect dstRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawImageRect(
      capturedImage,
      srcRect,
      dstRect,
      Paint()..isAntiAlias = false..filterQuality = FilterQuality.none, // Retain sharp pixels
    );
    canvas.restore();

    // 3. Draw grid (optional tracking visual)
    canvas.save();
    canvas.clipPath(clipPath);
    Paint gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Calculate grid alignment to actual pixels map
    double step = devicePixelRatio * zoom;
    double startX = (center.dx - srcRadius * zoom) % step;
    double startY = (center.dy - srcRadius * zoom) % step;

    for (double i = startX; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = startY; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
    canvas.restore();

    // 4. Draw preview ring filled with selected color
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = hoveredColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    canvas.drawCircle(center, radius + 7, borderPaint); 
    canvas.drawCircle(center, radius - 7, borderPaint..color = Colors.white.withOpacity(0.8));
    canvas.drawCircle(center, radius + 8, borderPaint..color = Colors.black26..strokeWidth = 1); 

    // 5. Crosshair
    Paint crosshairPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, 4, crosshairPaint);
    crosshairPaint.color = Colors.white;
    crosshairPaint.strokeWidth = 1;
    canvas.drawCircle(center, 4, crosshairPaint);
    
    canvas.drawLine(Offset(center.dx - 8, center.dy), Offset(center.dx + 8, center.dy), crosshairPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy + 8), crosshairPaint);
  }

  @override
  bool shouldRepaint(covariant MagnifyingLoupePainter oldDelegate) {
    return oldDelegate.centerPosition != centerPosition || oldDelegate.hoveredColor != hoveredColor;
  }
}
