import 'package:flutter/material.dart';
import '../models/canvas_models.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:perfect_freehand/perfect_freehand.dart';

// --- Shared Top-Level Drawing Utilities ---

void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
  const double dashWidth = 10.0;
  const double dashSpace = 5.0;
  final Path dashedPath = Path();
  for (final ui.PathMetric metric in path.computeMetrics()) {
    double distance = 0.0;
    while (distance < metric.length) {
      dashedPath.addPath(
        metric.extractPath(distance, distance + dashWidth),
        Offset.zero,
      );
      distance += dashWidth + dashSpace;
    }
  }
  canvas.drawPath(dashedPath, paint);
}

void _drawTriangle(Canvas canvas, Rect rect, Paint paint) {
  final path = Path()
    ..moveTo(rect.centerLeft.dx + (rect.width / 2), rect.top)
    ..lineTo(rect.right, rect.bottom)
    ..lineTo(rect.left, rect.bottom)
    ..close();
  canvas.drawPath(path, paint);
}

void _drawArrow(
  Canvas canvas,
  Offset p1,
  Offset p2,
  Paint paint, {
  bool isDashed = false,
}) {
  if (isDashed) {
    _drawDashedLine(canvas, p1, p2, paint);
  } else {
    canvas.drawLine(p1, p2, paint);
  }
  final double angle = (p2 - p1).direction;
  const double arrowSize = 15.0;
  final path = Path()
    ..moveTo(p2.dx, p2.dy)
    ..lineTo(
      p2.dx - arrowSize * math.cos(angle - math.pi / 6),
      p2.dy - arrowSize * math.sin(angle - math.pi / 6),
    )
    ..moveTo(p2.dx, p2.dy)
    ..lineTo(
      p2.dx - arrowSize * math.cos(angle + math.pi / 6),
      p2.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
  canvas.drawPath(path, paint);
}

void _drawSineWave(
  Canvas canvas,
  Rect rect,
  Paint paint, {
  bool isDashed = false,
}) {
  final path = Path();
  for (double i = 0; i <= rect.width; i++) {
    final double x = rect.left + i;
    final double y = rect.center.dy + math.sin(i * 0.1) * (rect.height / 2);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  if (isDashed) {
    _drawDashedPath(canvas, path, paint);
  } else {
    canvas.drawPath(path, paint);
  }
}

void _drawCosineWave(
  Canvas canvas,
  Rect rect,
  Paint paint, {
  bool isDashed = false,
}) {
  final path = Path();
  for (double i = 0; i <= rect.width; i++) {
    final double x = rect.left + i;
    final double y = rect.center.dy + math.cos(i * 0.1) * (rect.height / 2);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  if (isDashed) {
    _drawDashedPath(canvas, path, paint);
  } else {
    canvas.drawPath(path, paint);
  }
}

void _drawStar(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final double cx = rect.center.dx;
  final double cy = rect.center.dy;
  final double r = math.min(rect.width, rect.height) / 2;
  final double innerR = r * 0.4;
  final double step = math.pi / 5;
  double angle = -math.pi / 2;
  for (int i = 0; i < 10; i++) {
    double radius = (i % 2 == 0) ? r : innerR;
    double x = cx + math.cos(angle) * radius;
    double y = cy + math.sin(angle) * radius;
    if (i == 0) path.moveTo(x, y);
    else path.lineTo(x, y);
    angle += step;
  }
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawDiamond(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right, rect.center.dy)
    ..lineTo(rect.center.dx, rect.bottom)
    ..lineTo(rect.left, rect.center.dy)
    ..close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawPentagon(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final double cx = rect.center.dx;
  final double cy = rect.center.dy;
  final double r = math.min(rect.width, rect.height) / 2;
  final double step = math.pi * 2 / 5;
  double angle = -math.pi / 2;
  for (int i = 0; i < 5; i++) {
    double x = cx + math.cos(angle) * r;
    double y = cy + math.sin(angle) * r;
    if (i == 0) path.moveTo(x, y);
    else path.lineTo(x, y);
    angle += step;
  }
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawHexagon(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final double cx = rect.center.dx;
  final double cy = rect.center.dy;
  final double r = math.min(rect.width, rect.height) / 2;
  final double step = math.pi * 2 / 6;
  double angle = -math.pi / 2;
  for (int i = 0; i < 6; i++) {
    double x = cx + math.cos(angle) * r;
    double y = cy + math.sin(angle) * r;
    if (i == 0) path.moveTo(x, y);
    else path.lineTo(x, y);
    angle += step;
  }
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawCross(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final w = rect.width;
  final h = rect.height;
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  final qw = w * 0.2;
  final qh = h * 0.2;
  final path = Path()
    ..moveTo(cx - qw, rect.top)..lineTo(cx + qw, rect.top)
    ..lineTo(cx + qw, cy - qh)..lineTo(rect.right, cy - qh)
    ..lineTo(rect.right, cy + qh)..lineTo(cx + qw, cy + qh)
    ..lineTo(cx + qw, rect.bottom)..lineTo(cx - qw, rect.bottom)
    ..lineTo(cx - qw, cy + qh)..lineTo(rect.left, cy + qh)
    ..lineTo(rect.left, cy - qh)..lineTo(cx - qw, cy - qh)
    ..close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawCloud(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final w = rect.width;
  final h = rect.height;
  final l = rect.left;
  final t = rect.top;
  path.moveTo(l + w * 0.2, t + h * 0.6);
  path.cubicTo(l, t + h * 0.6, l, t + h * 0.9, l + w * 0.2, t + h * 0.9);
  path.cubicTo(l + w * 0.4, t + h * 1.1, l + w * 0.7, t + h * 0.9, l + w * 0.8, t + h * 0.9);
  path.cubicTo(l + w, t + h * 0.9, l + w, t + h * 0.6, l + w * 0.8, t + h * 0.5);
  path.cubicTo(l + w * 0.9, t + h * 0.1, l + w * 0.4, t, l + w * 0.3, t + h * 0.4);
  path.cubicTo(l + w * 0.1, t + h * 0.2, l, t + h * 0.4, l + w * 0.2, t + h * 0.6);
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawHeart(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final w = rect.width;
  final h = rect.height;
  final cx = rect.center.dx;
  final t = rect.top;
  path.moveTo(cx, t + h * 0.3);
  path.cubicTo(cx - w * 0.5, t - h * 0.2, rect.left - w * 0.1, t + h * 0.5, cx, rect.bottom);
  path.cubicTo(rect.right + w * 0.1, t + h * 0.5, cx + w * 0.5, t - h * 0.2, cx, t + h * 0.3);
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawCylinder(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final w = rect.width;
  final h = rect.height;
  final rx = w / 2;
  final ry = h * 0.15;
  path.addOval(Rect.fromCenter(center: Offset(rect.center.dx, rect.top + ry), width: w, height: ry * 2));
  path.moveTo(rect.left, rect.top + ry);
  path.lineTo(rect.left, rect.bottom - ry);
  path.arcToPoint(Offset(rect.right, rect.bottom - ry), radius: Radius.elliptical(rx, ry), clockwise: false);
  path.lineTo(rect.right, rect.top + ry);
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawCube(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final offset = math.min(rect.width, rect.height) * 0.25;
  final w = rect.width - offset;
  final h = rect.height - offset;
  final l = rect.left;
  final t = rect.top;
  path.addRect(Rect.fromLTWH(l, t + offset, w, h));
  path.addRect(Rect.fromLTWH(l + offset, t, w, h));
  path.moveTo(l, t + offset);
  path.lineTo(l + offset, t);
  path.moveTo(l + w, t + offset);
  path.lineTo(l + w + offset, t);
  path.moveTo(l, t + offset + h);
  path.lineTo(l + offset, t + h);
  path.moveTo(l + w, t + offset + h);
  path.lineTo(l + w + offset, t + h);
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawParallelogram(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final offset = rect.width * 0.2;
  path.moveTo(rect.left + offset, rect.top);
  path.lineTo(rect.right, rect.top);
  path.lineTo(rect.right - offset, rect.bottom);
  path.lineTo(rect.left, rect.bottom);
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawOctagon(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final double cx = rect.center.dx;
  final double cy = rect.center.dy;
  final double r = math.min(rect.width, rect.height) / 2;
  final double step = math.pi * 2 / 8;
  double angle = -math.pi / 2 + (math.pi / 8);
  for (int i = 0; i < 8; i++) {
    double x = cx + math.cos(angle) * r;
    double y = cy + math.sin(angle) * r;
    if (i == 0) path.moveTo(x, y);
    else path.lineTo(x, y);
    angle += step;
  }
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawHeptagon(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final double cx = rect.center.dx;
  final double cy = rect.center.dy;
  final double r = math.min(rect.width, rect.height) / 2;
  final double step = math.pi * 2 / 7;
  double angle = -math.pi / 2;
  for (int i = 0; i < 7; i++) {
    double x = cx + math.cos(angle) * r;
    double y = cy + math.sin(angle) * r;
    if (i == 0) path.moveTo(x, y);
    else path.lineTo(x, y);
    angle += step;
  }
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawTrapezoid(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final double offset = rect.width * 0.2;
  path.moveTo(rect.left + offset, rect.top);
  path.lineTo(rect.right - offset, rect.top);
  path.lineTo(rect.right, rect.bottom);
  path.lineTo(rect.left, rect.bottom);
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawSemiCircle(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final r = math.min(rect.width, rect.height) / 2;
  path.moveTo(rect.center.dx - r, rect.center.dy);
  path.arcToPoint(
    Offset(rect.center.dx + r, rect.center.dy),
    radius: Radius.circular(r),
    clockwise: true,
  );
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawRightTriangle(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path()
    ..moveTo(rect.left, rect.top)
    ..lineTo(rect.right, rect.bottom)
    ..lineTo(rect.left, rect.bottom)
    ..close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawXMark(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final offset = math.min(rect.width, rect.height) * 0.15;
  final l = rect.left;
  final t = rect.top;
  final r = rect.right;
  final b = rect.bottom;
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  
  path.moveTo(l + offset, t);
  path.lineTo(cx, cy - offset);
  path.lineTo(r - offset, t);
  path.lineTo(r, t + offset);
  path.lineTo(cx + offset, cy);
  path.lineTo(r, b - offset);
  path.lineTo(r - offset, b);
  path.lineTo(cx, cy + offset);
  path.lineTo(l + offset, b);
  path.lineTo(l, b - offset);
  path.lineTo(cx - offset, cy);
  path.lineTo(l, t + offset);
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawTeardrop(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final r = math.min(rect.width, rect.height) / 2;
  final cx = rect.center.dx;
  final cy = rect.center.dy + r * 0.2;
  path.moveTo(cx, rect.top);
  path.cubicTo(
    cx + r * 0.8, cy - r * 0.5, 
    cx + r, cy + r * 0.8, 
    cx, cy + r * 0.8
  );
  path.cubicTo(
    cx - r, cy + r * 0.8, 
    cx - r * 0.8, cy - r * 0.5, 
    cx, rect.top
  );
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawSpeechBubble(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final double r = math.min(rect.width, rect.height) * 0.2;
  final h = rect.height * 0.8;
  
  path.moveTo(rect.left + r, rect.top);
  path.lineTo(rect.right - r, rect.top);
  path.arcToPoint(Offset(rect.right, rect.top + r), radius: Radius.circular(r), clockwise: true);
  path.lineTo(rect.right, rect.top + h - r);
  path.arcToPoint(Offset(rect.right - r, rect.top + h), radius: Radius.circular(r), clockwise: true);
  
  path.lineTo(rect.right - rect.width * 0.3, rect.top + h);
  path.lineTo(rect.right - rect.width * 0.4, rect.bottom);
  path.lineTo(rect.right - rect.width * 0.5, rect.top + h);
  
  path.lineTo(rect.left + r, rect.top + h);
  path.arcToPoint(Offset(rect.left, rect.top + h - r), radius: Radius.circular(r), clockwise: true);
  path.lineTo(rect.left, rect.top + r);
  path.arcToPoint(Offset(rect.left + r, rect.top), radius: Radius.circular(r), clockwise: true);
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawCrescent(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final r = math.min(rect.width, rect.height) / 2;
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  
  path.moveTo(cx, cy - r);
  path.arcToPoint(
    Offset(cx, cy + r),
    radius: Radius.circular(r),
    clockwise: false,
  );
  path.quadraticBezierTo(
    cx - r * 0.5, cy,
    cx, cy - r
  );
  path.close();
  
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawFlag(Canvas canvas, Rect rect, Paint paint, {bool isDashed = false}) {
  final path = Path();
  final poleW = rect.width * 0.05;
  path.moveTo(rect.left, rect.bottom);
  path.lineTo(rect.left, rect.top);
  path.lineTo(rect.right, rect.top + rect.height * 0.25);
  path.lineTo(rect.left + poleW, rect.top + rect.height * 0.5);
  path.lineTo(rect.left + poleW, rect.bottom);
  path.close();
  if (isDashed) _drawDashedPath(canvas, path, paint);
  else canvas.drawPath(path, paint);
}

void _drawUnifiedShape(Canvas canvas, Rect rect, String type, Paint paint, {bool isDashed = false}) {
  if (isDashed) {
    if (type == 'line') _drawDashedLine(canvas, rect.topLeft, rect.bottomRight, paint);
    else if (type == 'arrow') _drawArrow(canvas, rect.topLeft, rect.bottomRight, paint, isDashed: true);
    else if (type == 'sin') _drawSineWave(canvas, rect, paint, isDashed: true);
    else if (type == 'cos') _drawCosineWave(canvas, rect, paint, isDashed: true);
    else if (type == 'star') _drawStar(canvas, rect, paint, isDashed: true);
    else if (type == 'diamond') _drawDiamond(canvas, rect, paint, isDashed: true);
    else if (type == 'pentagon') _drawPentagon(canvas, rect, paint, isDashed: true);
    else if (type == 'hexagon') _drawHexagon(canvas, rect, paint, isDashed: true);
    else if (type == 'cross') _drawCross(canvas, rect, paint, isDashed: true);
    else if (type == 'cloud') _drawCloud(canvas, rect, paint, isDashed: true);
    else if (type == 'heart') _drawHeart(canvas, rect, paint, isDashed: true);
    else if (type == 'cylinder') _drawCylinder(canvas, rect, paint, isDashed: true);
    else if (type == 'cube') _drawCube(canvas, rect, paint, isDashed: true);
    else if (type == 'parallelogram') _drawParallelogram(canvas, rect, paint, isDashed: true);
    else if (type == 'octagon') _drawOctagon(canvas, rect, paint, isDashed: true);
    else if (type == 'heptagon') _drawHeptagon(canvas, rect, paint, isDashed: true);
    else if (type == 'trapezoid') _drawTrapezoid(canvas, rect, paint, isDashed: true);
    else if (type == 'semi_circle') _drawSemiCircle(canvas, rect, paint, isDashed: true);
    else if (type == 'right_triangle') _drawRightTriangle(canvas, rect, paint, isDashed: true);
    else if (type == 'x_mark') _drawXMark(canvas, rect, paint, isDashed: true);
    else if (type == 'teardrop') _drawTeardrop(canvas, rect, paint, isDashed: true);
    else if (type == 'speech_bubble') _drawSpeechBubble(canvas, rect, paint, isDashed: true);
    else if (type == 'crescent') _drawCrescent(canvas, rect, paint, isDashed: true);
    else if (type == 'flag') _drawFlag(canvas, rect, paint, isDashed: true);
    else {
      if (type == 'rectangle') _drawDashedPath(canvas, Path()..addRect(rect), paint);
      else if (type == 'circle') _drawDashedPath(canvas, Path()..addOval(rect), paint);
      else if (type == 'triangle') {
        final path = Path()
          ..moveTo(rect.centerLeft.dx + (rect.width / 2), rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
        _drawDashedPath(canvas, path, paint);
      }
    }
  } else {
    if (type == 'rectangle') canvas.drawRect(rect, paint);
    else if (type == 'circle') canvas.drawOval(rect, paint);
    else if (type == 'line') canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
    else if (type == 'triangle') _drawTriangle(canvas, rect, paint);
    else if (type == 'arrow') _drawArrow(canvas, rect.topLeft, rect.bottomRight, paint);
    else if (type == 'sin') _drawSineWave(canvas, rect, paint);
    else if (type == 'cos') _drawCosineWave(canvas, rect, paint);
    else if (type == 'star') _drawStar(canvas, rect, paint);
    else if (type == 'diamond') _drawDiamond(canvas, rect, paint);
    else if (type == 'pentagon') _drawPentagon(canvas, rect, paint);
    else if (type == 'hexagon') _drawHexagon(canvas, rect, paint);
    else if (type == 'cross') _drawCross(canvas, rect, paint);
    else if (type == 'cloud') _drawCloud(canvas, rect, paint);
    else if (type == 'heart') _drawHeart(canvas, rect, paint);
    else if (type == 'cylinder') _drawCylinder(canvas, rect, paint);
    else if (type == 'cube') _drawCube(canvas, rect, paint);
    else if (type == 'parallelogram') _drawParallelogram(canvas, rect, paint);
    else if (type == 'octagon') _drawOctagon(canvas, rect, paint);
    else if (type == 'heptagon') _drawHeptagon(canvas, rect, paint);
    else if (type == 'trapezoid') _drawTrapezoid(canvas, rect, paint);
    else if (type == 'semi_circle') _drawSemiCircle(canvas, rect, paint);
    else if (type == 'right_triangle') _drawRightTriangle(canvas, rect, paint);
    else if (type == 'x_mark') _drawXMark(canvas, rect, paint);
    else if (type == 'teardrop') _drawTeardrop(canvas, rect, paint);
    else if (type == 'speech_bubble') _drawSpeechBubble(canvas, rect, paint);
    else if (type == 'crescent') _drawCrescent(canvas, rect, paint);
    else if (type == 'flag') _drawFlag(canvas, rect, paint);
  }
}

void _fillUnifiedShape(Canvas canvas, Rect rect, String type, Paint fillPaint) {
  if (type == 'rectangle') canvas.drawRect(rect, fillPaint);
  else if (type == 'circle') canvas.drawOval(rect, fillPaint);
  else if (type == 'triangle') _drawTriangle(canvas, rect, fillPaint);
  else if (type == 'star') _drawStar(canvas, rect, fillPaint);
  else if (type == 'diamond') _drawDiamond(canvas, rect, fillPaint);
  else if (type == 'pentagon') _drawPentagon(canvas, rect, fillPaint);
  else if (type == 'hexagon') _drawHexagon(canvas, rect, fillPaint);
  else if (type == 'cross') _drawCross(canvas, rect, fillPaint);
  else if (type == 'cloud') _drawCloud(canvas, rect, fillPaint);
  else if (type == 'heart') _drawHeart(canvas, rect, fillPaint);
  else if (type == 'cylinder') _drawCylinder(canvas, rect, fillPaint);
  else if (type == 'cube') _drawCube(canvas, rect, fillPaint);
  else if (type == 'parallelogram') _drawParallelogram(canvas, rect, fillPaint);
  else if (type == 'octagon') _drawOctagon(canvas, rect, fillPaint);
  else if (type == 'heptagon') _drawHeptagon(canvas, rect, fillPaint);
  else if (type == 'trapezoid') _drawTrapezoid(canvas, rect, fillPaint);
  else if (type == 'semi_circle') _drawSemiCircle(canvas, rect, fillPaint);
  else if (type == 'right_triangle') _drawRightTriangle(canvas, rect, fillPaint);
  else if (type == 'x_mark') _drawXMark(canvas, rect, fillPaint);
  else if (type == 'teardrop') _drawTeardrop(canvas, rect, fillPaint);
  else if (type == 'speech_bubble') _drawSpeechBubble(canvas, rect, fillPaint);
  else if (type == 'crescent') _drawCrescent(canvas, rect, fillPaint);
  else if (type == 'flag') _drawFlag(canvas, rect, fillPaint);
}

void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
  const double dashWidth = 10.0;
  const double dashSpace = 5.0;
  double distance = (p2 - p1).distance;
  if (distance == 0) return;
  int dashCount = (distance / (dashWidth + dashSpace)).floor();
  for (int i = 0; i < dashCount; i++) {
    double start = i * (dashWidth + dashSpace);
    double end = start + dashWidth;
    canvas.drawLine(
      Offset.lerp(p1, p2, start / distance)!,
      Offset.lerp(p1, p2, end / distance)!,
      paint,
    );
  }
}

// --- Painters ---

class LaserPainter extends CustomPainter {
  final List<LaserStroke> strokes;
  final int fadeDuration;
  final int version;
  LaserPainter(this.strokes, {this.fadeDuration = 2, required this.version});

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;
    final now = DateTime.now();

    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      // Extract surviving points into a single continuous path
      // This eliminates overlapping opacity artifacts (dots/dashes) at joints.
      final path = Path();
      path.moveTo(stroke.points.first.offset.dx, stroke.points.first.offset.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].offset.dx, stroke.points[i].offset.dy);
      }

      // The tip is the last point. We use its age to gracefully fade out the 
      // entire remaining stroke when the user stops drawing.
      final lastPoint = stroke.points.last;
      final tipAge = now.difference(lastPoint.timestamp).inMilliseconds;
      double masterOpacity = 1.0 - (tipAge / (fadeDuration * 1000)).clamp(0.0, 1.0);

      // Add a slight curve to the fade out so it stays solid a bit longer then fades
      masterOpacity = math.pow(masterOpacity, 0.7).toDouble();

      if (masterOpacity <= 0) continue;

      final Paint glowPaint = Paint()
        ..color = stroke.color.withOpacity(masterOpacity * 0.6)
        ..strokeWidth = 14.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

      final Paint midPaint = Paint()
        ..color = stroke.color.withOpacity(masterOpacity * 0.8)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      final Paint corePaint = Paint()
        ..color = Colors.white.withOpacity(masterOpacity)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (stroke.points.length == 1) {
        // Draw a dot if there is only one point
        canvas.drawCircle(stroke.points.first.offset, 7.0, glowPaint..style = PaintingStyle.fill..strokeWidth = 0);
        canvas.drawCircle(stroke.points.first.offset, 3.0, midPaint..style = PaintingStyle.fill..strokeWidth = 0);
        canvas.drawCircle(stroke.points.first.offset, 1.25, corePaint..style = PaintingStyle.fill..strokeWidth = 0);
      } else {
        // Draw continuous solid path
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, midPaint);
        canvas.drawPath(path, corePaint);
        
        // Highlight the tip to make it punchy
        final tipGlow = Paint()
          ..color = stroke.color.withOpacity(masterOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
        final tipCore = Paint()..color = Colors.white.withOpacity(masterOpacity);
        
        canvas.drawCircle(lastPoint.offset, 8, tipGlow);
        canvas.drawCircle(lastPoint.offset, 3, tipCore);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LaserPainter oldDelegate) => oldDelegate.version != version;
}

class ShapePreviewPainter extends CustomPainter {
  final String type;
  final double borderWidth;
  final Color borderColor;
  final Color fillColor;
  final int lineType;
  final bool isDarkMode;

  ShapePreviewPainter({
    required this.type,
    required this.borderWidth,
    required this.borderColor,
    required this.fillColor,
    required this.lineType,
    this.isDarkMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height) * 0.8;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: (type == 'line' || type == 'arrow' || type == 'sin' || type == 'cos') ? size.width * 0.8 : side,
      height: side,
    );
    final paint = Paint()
      ..color = getSmartColor(borderColor, isDarkMode)
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = getSmartColor(fillColor, isDarkMode)
      ..style = PaintingStyle.fill;

    if (fillColor != Colors.transparent) {
      _fillUnifiedShape(canvas, rect, type, fillPaint);
    }
    _drawUnifiedShape(canvas, rect, type, paint, isDashed: lineType == 1);
  }

  @override
  bool shouldRepaint(covariant ShapePreviewPainter old) =>
      old.type != type ||
      old.borderWidth != borderWidth ||
      old.borderColor != borderColor ||
      old.fillColor != fillColor ||
      old.lineType != lineType ||
      old.isDarkMode != isDarkMode;
}

class PenPreviewPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final PenType penType;
  final bool isDarkMode;
  PenPreviewPainter({
    required this.color,
    required this.strokeWidth,
    required this.penType,
    this.isDarkMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = isDarkMode ? Colors.grey.shade800 : const Color(0xFFF5F5F5),
    );
    final paint = Paint()
      ..color = getSmartColor(color, isDarkMode)
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(w * 0.1, h * 0.7);
    path.cubicTo(w * 0.3, h * 0.1, w * 0.6, h * 0.9, w * 0.9, h * 0.3);

    switch (penType) {
      case PenType.ball:
        paint.strokeWidth = strokeWidth;
        canvas.drawPath(path, paint);
        break;
      case PenType.fountain:
        paint.strokeWidth = strokeWidth * 1.2;
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
        canvas.drawPath(path, paint);
        break;
      case PenType.brush:
        paint.strokeWidth = strokeWidth * 1.8;
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawPath(path, paint);
        break;
      case PenType.perfect:
      case PenType.velocity:
        paint.strokeWidth = strokeWidth * 1.5;
        paint.strokeCap = StrokeCap.round;
        canvas.drawPath(path, paint);
        break;
      case PenType.pencil:
        // Base stroke faint
        final baseColor = getSmartColor(color, isDarkMode);
        canvas.drawPath(
          path,
          Paint()
            ..color = baseColor.withValues(alpha: 0.35)
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke,
        );
        // Grain dots preview
        final rng = math.Random(7);
        final noisePaint = Paint()
          ..color = baseColor.withValues(alpha: 0.13)
          ..style = PaintingStyle.fill;
        for (double t = 0.0; t <= 1.0; t += 0.06) {
          final x = w * 0.1 + t * (w * 0.8);
          final y = h * 0.5 + math.sin(t * math.pi * 2) * h * 0.25;
          for (int g = 0; g < 3; g++) {
            final dx = (rng.nextDouble() - 0.5) * strokeWidth * 1.2;
            final dy = (rng.nextDouble() - 0.5) * strokeWidth * 0.6;
            canvas.drawCircle(Offset(x + dx, y + dy), rng.nextDouble() * strokeWidth * 0.2 + 0.4, noisePaint);
          }
        }
        // Grain sub-strokes (two passes at different opacity)
        canvas.drawPath(path, Paint()
          ..color = baseColor.withValues(alpha: 0.14)
          ..strokeWidth = strokeWidth * 0.65
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
        canvas.drawPath(path, Paint()
          ..color = baseColor.withValues(alpha: 0.10)
          ..strokeWidth = strokeWidth * 0.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
        break;
      default:
        paint.strokeWidth = strokeWidth;
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant PenPreviewPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.penType != penType ||
      old.isDarkMode != isDarkMode;
}

class HighlighterPreviewPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double opacity;
  final StrokeCap tip;
  HighlighterPreviewPainter({
    required this.color,
    required this.thickness,
    required this.opacity,
    required this.tip,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1E1E2E),
    );
    final dotPaint = Paint()..color = Colors.white.withAlpha(15);
    for (double x = 16; x < w; x += 24) {
      for (double y = 10; y < h; y += 20) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = thickness
      ..strokeCap = tip
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(w * 0.08, h * 0.55);
    path.cubicTo(w * 0.25, h * 0.25, w * 0.55, h * 0.80, w * 0.92, h * 0.45);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HighlighterPreviewPainter old) =>
      old.color != color ||
      old.thickness != thickness ||
      old.opacity != opacity ||
      old.tip != tip;
}

class ShapePainter extends CustomPainter {
  final List<PageShape> shapes;
  final PageShape? currentShape;
  final PageTemplate template;
  final bool isDarkMode;
  final int version;
  ShapePainter(this.shapes, this.currentShape, this.template, {this.isDarkMode = false, required this.version});
  
  bool get effectiveDarkMode => isDarkMode || template.paperColor.computeLuminance() < 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    for (var shp in [...shapes, currentShape].whereType<PageShape>()) {
      final paint = Paint()
        ..color = getSmartColor(shp.borderColor, effectiveDarkMode)
        ..strokeWidth = shp.borderWidth
        ..style = PaintingStyle.stroke;
      final fillPaint = Paint()
        ..color = getSmartColor(shp.fillColor, effectiveDarkMode)
        ..style = PaintingStyle.fill;

      if (shp.fillColor != Colors.transparent) {
        _fillUnifiedShape(canvas, shp.rect, shp.type, fillPaint);
      }
      _drawUnifiedShape(canvas, shp.rect, shp.type, paint, isDashed: shp.lineType == 1);
    }
  }



  @override
  bool shouldRepaint(covariant ShapePainter old) => old.version != version || old.isDarkMode != isDarkMode || old.template != template || old.currentShape != currentShape;
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  final PageTemplate template;
  final bool isDarkMode;
  final int version;
  DrawingPainter(this.points, this.template, {this.isDarkMode = false, required this.version});
  
  bool get effectiveDarkMode => isDarkMode || template.paperColor.computeLuminance() < 0.5;

  Path _createDashedPath(Path source, double dashLength, double dashSpace) {
    var dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLength : dashSpace;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  Path _createDottedPath(Path source, double defaultWidth) {
    // For dotted: draw tiny lines (0.1 length) with round caps, spaced by 2.5x the width
    var dest = Path();
    double dotSpace = defaultWidth * 2.5;
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dest.addPath(metric.extractPath(distance, distance + 0.1), Offset.zero);
        distance += dotSpace;
      }
    }
    return dest;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // PASS 1: HIGHLIGHTERS
    bool hasHL = points.any((p) => p != null && p.penType == PenType.highlighter);
    if (hasHL) {
      final layerBlendMode = effectiveDarkMode ? BlendMode.screen : BlendMode.multiply;
      final layerBgColor = effectiveDarkMode ? Colors.black : Colors.white;

      final bounds = canvas.getLocalClipBounds();
      canvas.saveLayer(bounds, Paint()..blendMode = layerBlendMode);
      canvas.drawColor(layerBgColor, BlendMode.src);
      
      int i = 0;
      while (i < points.length) {
        if (points[i] == null) { i++; continue; }
        final pt = points[i]!;
        if (pt.penType == PenType.highlighter) {
          final path = Path();
          path.moveTo(pt.offset.dx, pt.offset.dy);
          int j = i + 1;
          while (j < points.length && points[j] != null) {
            path.lineTo(points[j]!.offset.dx, points[j]!.offset.dy);
            j++;
          }
          final paint = Paint()
            ..color = pt.paint.color
            ..strokeWidth = pt.paint.strokeWidth
            ..strokeCap = pt.paint.strokeCap
            ..strokeJoin = pt.paint.strokeJoin
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..blendMode = BlendMode.srcOver;

          Path finalPath = path;
          if (pt.lineType == LineType.dashed) {
            finalPath = _createDashedPath(path, pt.paint.strokeWidth * 3, pt.paint.strokeWidth * 2);
          } else if (pt.lineType == LineType.dotted) {
            finalPath = _createDottedPath(path, pt.paint.strokeWidth);
          }

          canvas.drawPath(finalPath, paint);
          if (j == i + 1) { 
            canvas.drawCircle(pt.offset, pt.paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
          }
          i = j;
        } else if (pt.penType == PenType.eraserBoth || pt.penType == PenType.eraserHighlighter) {
          final path = Path();
          path.moveTo(pt.offset.dx, pt.offset.dy);
          int j = i + 1;
          while (j < points.length && points[j] != null) {
            path.lineTo(points[j]!.offset.dx, points[j]!.offset.dy);
            j++;
          }
          final paint = Paint()
            ..strokeWidth = pt.paint.strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke
            ..blendMode = BlendMode.clear;
          canvas.drawPath(path, paint);
          if (j == i + 1) canvas.drawCircle(pt.offset, pt.paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
          i = j;
        } else {
          while (i < points.length && points[i] != null) {
            i++;
          }
        }
      }
      canvas.restore();
    }

    // PASS 2: NORMAL PENS
    final bounds = canvas.getLocalClipBounds();
    canvas.saveLayer(bounds, Paint()); 
    int i = 0;
    while (i < points.length) {
      if (points[i] == null) { i++; continue; }
      final pt = points[i]!;
      
      if (pt.penType == PenType.highlighter || pt.penType == PenType.eraserHighlighter) {
        while (i < points.length && points[i] != null) {
          i++;
        }
        continue;
      }

      final isPerfectMode = pt.penType == PenType.perfect || pt.penType == PenType.velocity;
      if (isPerfectMode) {
        final List<PointVector> inputPoints = [];
        int j = i;
        while (j < points.length && points[j] != null) {
          inputPoints.add(PointVector(points[j]!.offset.dx, points[j]!.offset.dy, points[j]!.pressure));
          j++;
        }
        if (inputPoints.isNotEmpty) {
          final strokePoints = getStroke(
            inputPoints,
            options: StrokeOptions(
              size: pt.paint.strokeWidth,
              thinning: pt.penType == PenType.velocity ? 0.8 : 0.5,
              smoothing: pt.smoothing,
              streamline: pt.smoothing,
              simulatePressure: pt.penType == PenType.perfect && pt.simulatePressure,
              isComplete: true,
            ),
          );
          final path = Path();
          if (strokePoints.isNotEmpty) {
            path.moveTo(strokePoints.first.dx, strokePoints.first.dy);
            for (int k = 1; k < strokePoints.length; k++) {
              path.lineTo(strokePoints[k].dx, strokePoints[k].dy);
            }
            path.close();
          }
          Path finalPath = path;
          if (pt.lineType == LineType.dashed) {
            finalPath = _createDashedPath(path, pt.paint.strokeWidth * 4, pt.paint.strokeWidth * 3);
          } else if (pt.lineType == LineType.dotted) {
            // For filled paths like perfect freehand, dashed spacing works better
            finalPath = _createDashedPath(path, pt.paint.strokeWidth, pt.paint.strokeWidth * 2);
          }

          final fillPaint = Paint()
            ..color = getSmartColor(pt.paint.color, effectiveDarkMode)
            ..style = PaintingStyle.fill
            ..isAntiAlias = true
            ..blendMode = pt.paint.blendMode;

          if (pt.autoFill && strokePoints.isNotEmpty) {
            final autoFillPaint = Paint()
              ..color = getSmartColor(pt.paint.color, effectiveDarkMode).withValues(alpha: 0.15)
              ..style = PaintingStyle.fill
              ..isAntiAlias = true
              ..blendMode = pt.paint.blendMode;
            // Draw a simplified internal path based on just the raw offsets for filling
            final baseFillPath = Path();
            baseFillPath.moveTo(inputPoints.first.dx, inputPoints.first.dy);
            for (int k = 1; k < inputPoints.length; k++) {
              baseFillPath.lineTo(inputPoints[k].dx, inputPoints[k].dy);
            }
            baseFillPath.close();
            canvas.drawPath(baseFillPath, autoFillPaint);
          }

          canvas.drawPath(finalPath, fillPaint);
        }
        i = j;
      } else if (pt.penType == PenType.pencil) {
        // --- Pencil: graphite texture with noise and semi-transparency ---
        final List<Offset> strokeOffsets = [];
        int j = i;
        while (j < points.length && points[j] != null) {
          strokeOffsets.add(points[j]!.offset);
          j++;
        }

        if (strokeOffsets.isNotEmpty) {
          final baseColor = getSmartColor(pt.paint.color, effectiveDarkMode);
          final sw = pt.paint.strokeWidth;

          // Pass A: Faint base stroke (graphite base layer)
          final basePaint = Paint()
            ..color = baseColor.withValues(alpha: 0.35)
            ..strokeWidth = sw
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke;
          final basePath = Path();
          basePath.moveTo(strokeOffsets.first.dx, strokeOffsets.first.dy);
          for (int k = 1; k < strokeOffsets.length; k++) {
            basePath.lineTo(strokeOffsets[k].dx, strokeOffsets[k].dy);
          }

          Path finalBasePath = basePath;
          if (pt.lineType == LineType.dashed) {
            finalBasePath = _createDashedPath(basePath, sw * 3, sw * 2);
          } else if (pt.lineType == LineType.dotted) {
            finalBasePath = _createDottedPath(basePath, sw);
          }
          canvas.drawPath(finalBasePath, basePaint);

          // Pass B: Grain dots scattered along the stroke
          final noisePaint = Paint()
            ..color = baseColor.withValues(alpha: 0.12)
            ..style = PaintingStyle.fill
            ..isAntiAlias = true;

          // Fixed seed → stable texture across repaints
          final rng = math.Random(42);
          for (int k = 0; k < strokeOffsets.length; k++) {
            final offset = strokeOffsets[k];
            for (int g = 0; g < 3; g++) {
              final dx = (rng.nextDouble() - 0.5) * sw * 1.2;
              final dy = (rng.nextDouble() - 0.5) * sw * 0.6;
              final radius = rng.nextDouble() * (sw * 0.22) + 0.4;
              canvas.drawCircle(Offset(offset.dx + dx, offset.dy + dy), radius, noisePaint);
            }
          }

          // Pass C: Two offset sub-strokes for directional grain texture
          final grainPaint = Paint()
            ..color = baseColor.withValues(alpha: 0.15)
            ..strokeWidth = sw * 0.65
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke;

          for (final sign in [const Offset(0.4, 0.2), const Offset(-0.3, -0.15)]) {
            final grainPath = Path();
            grainPath.moveTo(
              strokeOffsets.first.dx + sign.dx * sw,
              strokeOffsets.first.dy + sign.dy * sw,
            );
            for (int k = 1; k < strokeOffsets.length; k++) {
              final jitter = rng.nextDouble() * 0.4 - 0.2;
              grainPath.lineTo(
                strokeOffsets[k].dx + (sign.dx + jitter) * sw,
                strokeOffsets[k].dy + (sign.dy + jitter) * sw,
              );
            }
            
            Path finalGrainPath = grainPath;
            if (pt.lineType == LineType.dashed) {
              finalGrainPath = _createDashedPath(grainPath, sw * 3, sw * 2);
            } else if (pt.lineType == LineType.dotted) {
              finalGrainPath = _createDottedPath(grainPath, sw);
            }
            canvas.drawPath(finalGrainPath, grainPaint);
          }
        }

        // Handle single-tap dot
        if (strokeOffsets.length <= 1) {
          final dotPaint = Paint()
            ..color = getSmartColor(pt.paint.color, effectiveDarkMode).withValues(alpha: 0.45)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(pt.offset, pt.paint.strokeWidth / 2, dotPaint);
        }
        i = j;
      } else {
        final path = Path();
        path.moveTo(pt.offset.dx, pt.offset.dy);
        int j = i + 1;
        while (j < points.length && points[j] != null) {
          path.lineTo(points[j]!.offset.dx, points[j]!.offset.dy);
          j++;
        }
        final strokePaint = Paint()
          ..color = pt.penType == PenType.eraserBoth || pt.penType == PenType.eraserPen 
              ? Colors.transparent 
              : getSmartColor(pt.paint.color, effectiveDarkMode)
          ..strokeWidth = pt.paint.strokeWidth
          ..strokeCap = pt.paint.strokeCap
          ..strokeJoin = pt.paint.strokeJoin
          ..isAntiAlias = true
          ..blendMode = pt.penType == PenType.eraserBoth || pt.penType == PenType.eraserPen 
              ? BlendMode.clear 
              : pt.paint.blendMode
          ..style = PaintingStyle.stroke;

        Path finalPath = path;
        if (pt.lineType == LineType.dashed) {
          finalPath = _createDashedPath(path, pt.paint.strokeWidth * 3, pt.paint.strokeWidth * 2);
        } else if (pt.lineType == LineType.dotted) {
          finalPath = _createDottedPath(path, pt.paint.strokeWidth);
        }

        canvas.drawPath(finalPath, strokePaint);
        
        if (pt.autoFill && j - i > 2) {
          final autoFillPaint = Paint()
            ..color = strokePaint.color.withValues(alpha: 0.15)
            ..style = PaintingStyle.fill;
          canvas.drawPath(path, autoFillPaint);
        }

        if (j == i + 1) {
          canvas.drawCircle(pt.offset, pt.paint.strokeWidth / 2, strokePaint..style = PaintingStyle.fill);
        }
        i = j;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => oldDelegate.version != version || oldDelegate.isDarkMode != isDarkMode || oldDelegate.template != template;
}

class LassoPainter extends CustomPainter {
  final List<Offset> points;
  final int version;
  LassoPainter(this.points, {required this.version});
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    var paint = Paint()
      ..color = Colors.amber.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    var path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
    var fillPaint = Paint()
      ..color = Colors.amber.withAlpha(30)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(LassoPainter oldDelegate) => true;
}

class CanvasBackgroundPainter extends CustomPainter {
  final PageTemplate template;
  final bool isDarkMode;
  
  CanvasBackgroundPainter(this.template, {this.isDarkMode = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    // For very large (infinite) canvases, cap the drawing area to avoid
    // millions of draw calls. The background tiles infinitely since we fill
    // the entire space with the bg color, and lines are drawn up to maxDim.
    const double maxDim = 12000.0;
    final double drawW = size.width > maxDim ? maxDim : size.width;
    final double drawH = size.height > maxDim ? maxDim : size.height;

    Color bgColor = template.paperColor;
    if (isDarkMode && bgColor.value == Colors.white.value) {
      bgColor = const Color(0xFF1C1C1E);
    }
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (template.type == CanvasBackgroundType.blank || template.type == CanvasBackgroundType.custom) return;

    Color actualLineColor = isDarkMode 
        ? getSmartColor(template.lineColor, isDarkMode).withAlpha(template.lineColor.alpha)
        : template.lineColor;

    final paint = Paint()
      ..color = actualLineColor
      ..strokeWidth = 1.0;

    final double spacing = template.lineSpacing;

    if (template.type == CanvasBackgroundType.ruled_college || template.type == CanvasBackgroundType.ruled_narrow) {
      for (double y = spacing; y < drawH; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(drawW, y), paint);
      }
    } else if (template.type == CanvasBackgroundType.grid) {
      for (double y = 0; y < drawH; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(drawW, y), paint);
      }
      for (double x = 0; x < drawW; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, drawH), paint);
      }
    } else if (template.type == CanvasBackgroundType.dotted) {
      paint.strokeCap = StrokeCap.round;
      paint.strokeWidth = 2.0;
      for (double y = spacing; y < drawH; y += spacing) {
        for (double x = spacing; x < drawW; x += spacing) {
          canvas.drawPoints(ui.PointMode.points, [Offset(x, y)], paint);
        }
      }
    } else if (template.type == CanvasBackgroundType.music) {
      double y = spacing * 2;
      while (y < drawH) {
        for (int i = 0; i < 5; i++) {
          canvas.drawLine(Offset(0, y + (i * 10)), Offset(drawW, y + (i * 10)), paint);
        }
        y += spacing * 4; 
      }
    } else if (template.type == CanvasBackgroundType.todo) {
      for (double y = spacing; y < drawH; y += spacing) {
        canvas.drawLine(Offset(spacing * 2, y), Offset(drawW, y), paint);
        canvas.drawRect(Rect.fromLTWH(spacing * 0.5, y - spacing * 0.7, spacing * 0.8, spacing * 0.8), paint..style = PaintingStyle.stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasBackgroundPainter oldDelegate) {
    return oldDelegate.template.type != template.type ||
           oldDelegate.template.paperColor != template.paperColor ||
           oldDelegate.template.lineColor != template.lineColor ||
           oldDelegate.template.lineSpacing != template.lineSpacing ||
           oldDelegate.isDarkMode != isDarkMode;
  }
}

class TablePainter extends CustomPainter {
  final List<PageTable> tables;
  final PageTable? currentTable;
  TablePainter({required this.tables, this.currentTable});
  @override
  void paint(Canvas canvas, Size size) {
    for (var table in tables) {
      _drawTable(canvas, table);
    }
    if (currentTable != null) {
      _drawTable(canvas, currentTable!);
    }
  }

  void _drawTable(Canvas canvas, PageTable table) {
    final rect = table.rect;
    final paint = Paint()
      ..color = table.borderColor
      ..strokeWidth = table.borderWidth
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = table.fillColor
      ..style = PaintingStyle.fill;
    if (table.fillColor != Colors.transparent) {
      canvas.drawRect(rect, fillPaint);
    }
    canvas.drawRect(rect, paint);
    final rowHeight = rect.height / table.rows;
    final colWidth = rect.width / table.columns;
    for (int i = 1; i < table.rows; i++) {
      final y = rect.top + i * rowHeight;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
    for (int i = 1; i < table.columns; i++) {
      final x = rect.left + i * colWidth;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
    }
    if (table.hasHeaderRow) {
      final headerPaint = Paint()
        ..color = table.borderColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rowHeight),
        headerPaint,
      );
    }
    if (table.hasHeaderCol) {
      final headerPaint = Paint()
        ..color = table.borderColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, colWidth, rect.height),
        headerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TablePainter oldDelegate) => true;
}

class TablePreviewPainter extends CustomPainter {
  final int rows;
  final int cols;
  final bool hasHeaderRow;
  final bool hasHeaderCol;
  final Color borderColor;
  final Color fillColor;
  final double borderWidth;
  TablePreviewPainter({
    required this.rows,
    required this.cols,
    required this.hasHeaderRow,
    required this.hasHeaderCol,
    required this.borderColor,
    required this.fillColor,
    required this.borderWidth,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(20, 10, size.width - 40, size.height - 20);
    if (fillColor != Colors.transparent) {
      canvas.drawRect(rect, Paint()..color = fillColor);
    }
    final rowH = rect.height / rows;
    final colW = rect.width / cols;
    final headerPaint = Paint()..color = borderColor.withAlpha(40);
    if (hasHeaderRow) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rowH),
        headerPaint,
      );
    }
    if (hasHeaderCol) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, colW, rect.height),
        headerPaint,
      );
    }
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, paint);
    for (int i = 1; i < rows; i++) {
      final y = rect.top + i * rowH;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
    for (int i = 1; i < cols; i++) {
      final x = rect.left + i * colW;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant TablePreviewPainter oldDelegate) => true;
}

class ZoomBackgroundPainter extends CustomPainter {
  final bool isDarkMode;
  ZoomBackgroundPainter({this.isDarkMode = false});
  @override
  void paint(Canvas canvas, Size size) {
    final bgColor = isDarkMode
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFFCFCF2);
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);
    final paint = Paint()
      ..color = isDarkMode
          ? Colors.white.withAlpha(20)
          : Colors.blue.withAlpha(50)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class ZoomWindowPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  final Rect canvasTargetRect;
  final bool isDarkMode;
  ZoomWindowPainter(this.points, this.canvasTargetRect, {this.isDarkMode = false});
  @override
  void paint(Canvas canvas, Size size) {
    if (canvasTargetRect.isEmpty ||
        canvasTargetRect.width == 0 ||
        canvasTargetRect.height == 0) {
      return;
    }
    canvas.clipRect(Offset.zero & size);
    double scale = size.width / canvasTargetRect.width;
    canvas.save();
    double offsetY = (size.height - (canvasTargetRect.height * scale)) / 2;
    canvas.translate(0, offsetY);
    canvas.scale(scale);
    canvas.translate(-canvasTargetRect.left, -canvasTargetRect.top);
    for (int i = 0; i < points.length; i++) {
      if (points[i] == null) continue;
      
      final firstPoint = points[i]!;
      final segmentPaint = firstPoint.paint;
      final isPerfect = firstPoint.penType == PenType.perfect;

      if (isPerfect) {
        final List<PointVector> inputPoints = [];
        int j = i;
        while (j < points.length && points[j] != null) {
          inputPoints.add(PointVector(
            points[j]!.offset.dx,
            points[j]!.offset.dy,
            points[j]!.pressure,
          ));
          j++;
        }

        if (inputPoints.isNotEmpty) {
          final strokePoints = getStroke(
            inputPoints,
            options: StrokeOptions(
              size: segmentPaint.strokeWidth,
              thinning: 0.5,
              smoothing: 0.5,
              streamline: 0.5,
              simulatePressure: true,
              isComplete: true,
            ),
          );

          final path = Path();
          if (strokePoints.isNotEmpty) {
            path.moveTo(strokePoints.first.dx, strokePoints.first.dy);
            for (int k = 1; k < strokePoints.length; k++) {
              path.lineTo(strokePoints[k].dx, strokePoints[k].dy);
            }
            path.close();
          }

          final fillPaint = Paint()
            ..color = getSmartColor(segmentPaint.color, isDarkMode)
            ..style = PaintingStyle.fill
            ..isAntiAlias = true;

          canvas.drawPath(path, fillPaint);
        }
        i = j;
      } else {
        final path = Path();
        path.moveTo(points[i]!.offset.dx, points[i]!.offset.dy);
        
        int j = i + 1;
        while (j < points.length && points[j] != null) {
          path.lineTo(points[j]!.offset.dx, points[j]!.offset.dy);
          j++;
        }
        
        final strokePaint = Paint()
          ..color = getSmartColor(segmentPaint.color, isDarkMode)
          ..strokeWidth = segmentPaint.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;

        canvas.drawPath(path, strokePaint);
        
        if (j == i + 1) {
          // Draw a single dot
          canvas.drawCircle(
            points[i]!.offset,
            segmentPaint.strokeWidth / 2,
            strokePaint..style = PaintingStyle.fill,
          );
        }
        
        i = j;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ZoomWindowPainter old) => true;
}
