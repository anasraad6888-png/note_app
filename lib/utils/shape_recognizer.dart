import 'dart:math';
import 'package:flutter/material.dart';
import '../models/canvas_models.dart';

class ShapeRecognizer {
  static List<DrawingPoint>? recognizeAndConvert(List<DrawingPoint?> rawStroke) {
    if (rawStroke.length < 10) return null; // Too short to recognize

    // Extract valid non-null points
    List<Offset> points = rawStroke.where((p) => p != null).map((p) => p!.offset).toList();
    if (points.length < 10) return null;

    final firstP = points.first;
    final lastP = points.last;

    // Bounding Box
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    double pathLength = 0;
    for (int i = 1; i < points.length; i++) {
       pathLength += (points[i] - points[i - 1]).distance;
       if (points[i].dx < minX) minX = points[i].dx;
       if (points[i].dx > maxX) maxX = points[i].dx;
       if (points[i].dy < minY) minY = points[i].dy;
       if (points[i].dy > maxY) maxY = points[i].dy;
    }

    final double width = maxX - minX;
    final double height = maxY - minY;
    final double diagonal = sqrt(width * width + height * height);
    if (diagonal < 20) return null; // Too small

    // Stroke closure distance
    final double closureDist = (firstP - lastP).distance;
    final bool isClosed = closureDist < (diagonal * 0.25);

    final Paint refPaint = rawStroke.first!.paint;
    final PenType? refType = rawStroke.first!.penType;

    // 1. STRAIGHT LINE TEST
    // If the path length is roughly equal to the distance between start and end
    if (!isClosed) {
       final double directDist = (firstP - lastP).distance;
       if (pathLength < directDist * 1.15) {
          // It's a straight line
          return _createLine(firstP, lastP, refPaint, refType);
       }
       // If it is an open shape but not a straight line, we probably shouldn't auto-shape it
       // unless we want to support open arcs/arrows.
       return null;
    }

    // It's a closed shape!

    double strokeArea = _polygonArea(points);
    double bbArea = width * height;
    double areaRatio = bbArea > 0 ? (strokeArea / bbArea) : 0;
    
    // Compute the centroid
    Offset centroid = Offset(
      points.fold(0.0, (s, p) => s + p.dx) / points.length,
      points.fold(0.0, (s, p) => s + p.dy) / points.length,
    );
    
    // Average distance from centroid (actual mean radius)
    double meanRadius = points.fold(0.0, (s, p) => s + (p - centroid).distance) / points.length;
    // Bounding-circle radius (largest distance from centroid)
    double maxRadius = points.fold(0.0, (s, p) => max(s, (p - centroid).distance));
    // Circularity: how uniformly round is the shape?
    // A perfect circle → meanRadius ≈ maxRadius → circularity close to 1.0
    // A rectangle → meanRadius ≈ 0.75 * maxRadius → circularity around 0.75
    double circularity = maxRadius > 0 ? (meanRadius / maxRadius) : 0;

    // ── 1. CIRCLE / ELLIPSE TEST (run first — more reliable) ──────────────────
    // Hand-drawn circles/ovals have circularity > 0.76 (mean/max radius from centroid).
    // Rectangles score ~0.70-0.75 because their corners push maxRadius up.
    if (circularity > 0.76 && areaRatio > 0.60 && areaRatio < 0.90) {
      Offset center = Offset(minX + width / 2, minY + height / 2);
      if ((width - height).abs() < (max(width, height) * 0.30)) {
        return _createCircle(center, max(width, height) / 2, refPaint, refType);
      } else {
        return _createEllipse(center, width, height, refPaint, refType);
      }
    }

    // ── 2. ORTHOGONAL RECTANGLE TEST ─────────────────────────────────────────
    int pointsNearBounds = 0;
    double marginX = width * 0.08;
    double marginY = height * 0.08;
    for (var p in points) {
      bool nearX = (p.dx - minX).abs() < marginX || (p.dx - maxX).abs() < marginX;
      bool nearY = (p.dy - minY).abs() < marginY || (p.dy - maxY).abs() < marginY;
      if (nearX || nearY) pointsNearBounds++;
    }

    if (pointsNearBounds / points.length > 0.92) {
      int cornerCount = _countCorners(points, 60.0);
      if (cornerCount >= 3 && cornerCount <= 6) {
        return _createRectangle(Rect.fromLTRB(minX, minY, maxX, maxY), refPaint, refType);
      }
    }

    // ── 3. POLYGON FALLBACK (Triangles, Diamonds, Tilted Rect, etc.) ─────────
    List<Offset> simplified = _douglasPeucker(points, diagonal * 0.08);

    if ((simplified.first - simplified.last).distance > 1.0) {
      simplified.add(simplified.first);
    }

    int vertices = simplified.length - 1;

    // Rescue: if Douglas-Peucker gives 5+ near-equal sides, it's really a circle
    if (vertices >= 5) {
      final vertexOffsets = simplified.sublist(0, vertices);
      final radii = vertexOffsets.map((p) => (p - centroid).distance).toList();
      final avgR = radii.reduce((a, b) => a + b) / radii.length;
      final variance = radii.map((r) => (r - avgR) * (r - avgR)).reduce((a, b) => a + b) / radii.length;
      final stdRatio = avgR > 0 ? sqrt(variance) / avgR : 1.0;
      if (stdRatio < 0.15) {
        // Vertices are all roughly equidistant from centre → it's a circle
        Offset center = Offset(minX + width / 2, minY + height / 2);
        if ((width - height).abs() < (max(width, height) * 0.30)) {
          return _createCircle(center, max(width, height) / 2, refPaint, refType);
        } else {
          return _createEllipse(center, width, height, refPaint, refType);
        }
      }
    }

    if (vertices >= 3 && vertices <= 8) {
      return _createPolygon(simplified, refPaint, refType);
    }

    return null; // Could not recognize simple shape
  }

  /// Counts how many times the drawing direction changes by at least [minAngleDeg] degrees.
  static int _countCorners(List<Offset> points, double minAngleDeg) {
    if (points.length < 6) return 0;
    int corners = 0;
    final threshold = minAngleDeg * pi / 180;
    // Sample every 5th point to avoid noise
    const step = 5;
    for (int i = step; i < points.length - step; i += step) {
      final v1 = points[i] - points[i - step];
      final v2 = points[i + step] - points[i];
      if (v1.distance < 1 || v2.distance < 1) continue;
      final dot = (v1.dx * v2.dx + v1.dy * v2.dy) / (v1.distance * v2.distance);
      final angle = acos(dot.clamp(-1.0, 1.0));
      if (angle > threshold) corners++;
    }
    return corners;
  }

  // --- Geometrical Generator Helpers --- 

  static List<DrawingPoint> _createLine(Offset p1, Offset p2, Paint paint, PenType? type) {
     return [
        DrawingPoint(p1, paint, penType: type),
        DrawingPoint(p2, paint, penType: type),
     ];
  }

  static List<DrawingPoint> _createRectangle(Rect rect, Paint paint, PenType? type) {
     return [
        DrawingPoint(rect.topLeft, paint, penType: type),
        DrawingPoint(rect.topRight, paint, penType: type),
        DrawingPoint(rect.bottomRight, paint, penType: type),
        DrawingPoint(rect.bottomLeft, paint, penType: type),
        DrawingPoint(rect.topLeft, paint, penType: type),
     ];
  }

  static List<DrawingPoint> _createPolygon(List<Offset> points, Paint paint, PenType? type) {
     return points.map((p) => DrawingPoint(p, paint, penType: type)).toList();
  }

  static List<DrawingPoint> _createCircle(Offset center, double radius, Paint paint, PenType? type) {
     List<DrawingPoint> circle = [];
     int segments = 36;
     for (int i = 0; i <= segments; i++) {
        double theta = (i * 2 * pi) / segments;
        circle.add(DrawingPoint(
           Offset(center.dx + radius * cos(theta), center.dy + radius * sin(theta)),
           paint,
           penType: type,
        ));
     }
     return circle;
  }

  static List<DrawingPoint> _createEllipse(Offset center, double width, double height, Paint paint, PenType? type) {
     List<DrawingPoint> ellipse = [];
     int segments = 36;
     for (int i = 0; i <= segments; i++) {
        double theta = (i * 2 * pi) / segments;
        ellipse.add(DrawingPoint(
           Offset(center.dx + (width/2) * cos(theta), center.dy + (height/2) * sin(theta)),
           paint,
           penType: type,
        ));
     }
     return ellipse;
  }

  // --- Shoelace Formula for Polygon Area ---
  static double _polygonArea(List<Offset> points) {
    if (points.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < points.length - 1; i++) {
      area += points[i].dx * points[i + 1].dy - points[i + 1].dx * points[i].dy;
    }
    area += points.last.dx * points.first.dy - points.first.dx * points.last.dy;
    return (area / 2).abs();
  }

  // --- Douglas-Peucker Algorithm ---
  static List<Offset> _douglasPeucker(List<Offset> points, double epsilon) {
    if (points.length <= 2) return points;

    double maxDist = 0;
    int index = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double dist = _perpendicularDistance(points[i], points.first, points.last);
      if (dist > maxDist) {
        maxDist = dist;
        index = i;
      }
    }

    if (maxDist > epsilon) {
      List<Offset> left = _douglasPeucker(points.sublist(0, index + 1), epsilon);
      List<Offset> right = _douglasPeucker(points.sublist(index), epsilon);
      // Combine without duplicating the middle point
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  static double _perpendicularDistance(Offset pt, Offset lineStart, Offset lineEnd) {
    double dx = lineEnd.dx - lineStart.dx;
    double dy = lineEnd.dy - lineStart.dy;

    if (dx == 0 && dy == 0) return (pt - lineStart).distance;

    double t = ((pt.dx - lineStart.dx) * dx + (pt.dy - lineStart.dy) * dy) / (dx * dx + dy * dy);

    // Limit t to [0, 1] to ensure we measure distance to the line segment, not the infinite line
    // t = t.clamp(0.0, 1.0); 
    // Actually, Douglas Peucker uses infinite line distance, but bounded is fine.
    
    Offset projection = Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);
    return (pt - projection).distance;
  }
}
