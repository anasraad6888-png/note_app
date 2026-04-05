part of '../canvas_controller.dart';

extension CanvasControllerGeometry on CanvasController {
  bool isPointInPolygon(Offset point, List<Offset> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx) {
        isInside = !isInside;
      }
      j = i;
    }
    return isInside;
  }

  bool isRectInPolygon(Rect rect, double angle, List<Offset> polygon) {
    if (polygon.isEmpty) return false;
    final center = rect.center;
    final List<Offset> corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];

    if (angle != 0) {
      for (int i = 0; i < 4; i++) {
        final c = corners[i];
        final dx = c.dx - center.dx;
        final dy = c.dy - center.dy;
        corners[i] = Offset(
          center.dx + dx * math.cos(angle) - dy * math.sin(angle),
          center.dy + dx * math.sin(angle) + dy * math.cos(angle),
        );
      }
    }

    for (var corner in corners) {
      if (isPointInPolygon(corner, polygon)) return true;
    }

    // Check if any polygon vertex is inside rect bounds considering rotation
    for (var pt in polygon) {
      if (angle == 0) {
        if (rect.contains(pt)) return true;
      } else {
        final dx = pt.dx - center.dx;
        final dy = pt.dy - center.dy;
        final unrotatedPt = Offset(
          center.dx + dx * math.cos(-angle) - dy * math.sin(-angle),
          center.dy + dx * math.sin(-angle) + dy * math.cos(-angle),
        );
        if (rect.contains(unrotatedPt)) return true;
      }
    }
    return false;
  }

  bool isPointInSelectionUI(Offset pt) {
    if (activeSelectionGroup == null) return false;
    final rect = getSelectionBoundingBox(activeSelectionGroup!.pageIndex);
    if (rect == null) return false;
    
    // Validate Bounding Box Handle Padding
    final boundsRect = Rect.fromLTWH(rect.left - 30, rect.top - 30, rect.width + 60, rect.height + 60);
    if (boundsRect.contains(pt)) return true;
    
    // Validate Context Menu Geometry
    final menuRect = Rect.fromLTWH(rect.left - 20, rect.top - 80, rect.width + 40, 80);
    if (menuRect.contains(pt)) return true;
    
    return false;
  }

}
