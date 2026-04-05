part of '../canvas_controller.dart';

extension CanvasControllerSelection on CanvasController {
  void copySelection() {
    if (activeSelectionGroup != null) {
      clipboardGroup = activeSelectionGroup!.clone();
      showMessage?.call("تم نسخ العناصر");
    }
  }

  void cutSelection() {
    if (activeSelectionGroup != null) {
      clipboardGroup = activeSelectionGroup!.clone();
      deleteSelection();
      showMessage?.call("تم قص العناصر");
    }
  }

  void pasteClipboard(int pageIndex, Offset position) {
    if (clipboardGroup == null) return;
    saveStrokes(); // For undo

    final clone = clipboardGroup!.clone();
    clone.pageIndex = pageIndex;

    final rect = clone.initialBoundingBox;
    if (rect != null) {
      final offset = position - rect.center;
      clone.currentTranslation += offset;
    }

    if (activeSelectionGroup != null) commitSelection();
    activeSelectionGroup = clone;

    disableAllTools();
    isLassoMode = true;
    showLassoSettingsRow = true;

    notifyContentChanged();
  }

  void duplicateSelection() {
    if (activeSelectionGroup == null) return;

    final clone = activeSelectionGroup!.clone();
    commitSelection(); // Bake the original elements natively into the page

    clone.currentTranslation += const Offset(
      20,
      20,
    ); // Append slight interaction offset
    activeSelectionGroup = clone;

    notifyContentChanged();
  }

  void recolorSelection(Color color) {
    if (activeSelectionGroup == null) return;
    final group = activeSelectionGroup!;

    final newStrokes = <DrawingPoint?>[];
    for (var p in group.strokes) {
      if (p == null) {
        newStrokes.add(null);
      } else {
        final newPaint = Paint()
          ..color = color
          ..strokeWidth = p.paint.strokeWidth
          ..strokeCap = p.paint.strokeCap
          ..strokeJoin = p.paint.strokeJoin
          ..style = p.paint.style
          ..blendMode = p.paint.blendMode;
        newStrokes.add(
          DrawingPoint(
            p.offset,
            newPaint,
            pressure: p.pressure,
            penType: p.penType,
            timestamp: p.timestamp,
            audioIndex: p.audioIndex,
          ),
        );
      }
    }
    group.strokes = newStrokes;

    for (var shape in group.shapes) {
      shape.borderColor = color;
    }
    for (var text in group.texts) {
      text.color = color;
    }
    for (var table in group.tables) {
      table.borderColor = color;
    }

    notifyContentChanged();
  }

  void translateSelection(Offset delta) {
    if (activeSelectionGroup == null) return;
    activeSelectionGroup!.currentTranslation += delta;
    notifyContentChanged();
  }

  void scaleSelection(double scaleFactor) {
    if (activeSelectionGroup == null) return;
    activeSelectionGroup!.currentScale *= scaleFactor;
    notifyContentChanged();
  }

  void rotateSelection(double angleDelta) {
    if (activeSelectionGroup == null) return;
    activeSelectionGroup!.currentRotation += angleDelta;
    notifyContentChanged();
  }

  void commitSelection() {
    if (activeSelectionGroup == null) return;
    final group = activeSelectionGroup!;

    final double tx = group.currentTranslation.dx;
    final double ty = group.currentTranslation.dy;
    final double scale = group.currentScale;
    final double rot = group.currentRotation;
    final Offset center = group.initialBoundingBox?.center ?? Offset.zero;

    Offset applyTransform(Offset pt) {
      double dx = pt.dx - center.dx;
      double dy = pt.dy - center.dy;
      dx *= scale;
      dy *= scale;
      if (rot != 0) {
        final rdx = dx * math.cos(rot) - dy * math.sin(rot);
        final rdy = dx * math.sin(rot) + dy * math.cos(rot);
        dx = rdx;
        dy = rdy;
      }
      return Offset(center.dx + dx + tx, center.dy + dy + ty);
    }

    final bakedStrokes = group.strokes.map((stroke) {
      if (stroke == null) return null;
      final newPaint = Paint()
        ..color = stroke.paint.color
        ..strokeWidth = math.max(0.1, stroke.paint.strokeWidth * scale)
        ..strokeCap = stroke.paint.strokeCap
        ..strokeJoin = stroke.paint.strokeJoin
        ..style = stroke.paint.style;
      return DrawingPoint(
        applyTransform(stroke.offset),
        newPaint,
        pressure: stroke.pressure,
        penType: stroke.penType,
        timestamp: stroke.timestamp,
        audioIndex: stroke.audioIndex,
      );
    }).toList();

    for (var img in group.images) {
      final imgCenter = Rect.fromLTWH(
        img.offset.dx,
        img.offset.dy,
        img.size.width,
        img.size.height,
      ).center;
      final newCenter = applyTransform(imgCenter);
      img.size = Size(img.size.width * scale, img.size.height * scale);
      img.offset = Offset(
        newCenter.dx - img.size.width / 2,
        newCenter.dy - img.size.height / 2,
      );
    }

    for (var txt in group.texts) {
      final newCenter = applyTransform(txt.rect.center);
      txt.rect = Rect.fromCenter(
        center: newCenter,
        width: txt.rect.width * scale,
        height: txt.rect.height * scale,
      );
      txt.fontSize *= scale;
      txt.angle += rot;
    }

    for (var shp in group.shapes) {
      final newCenter = applyTransform(shp.rect.center);
      shp.rect = Rect.fromCenter(
        center: newCenter,
        width: shp.rect.width * scale,
        height: shp.rect.height * scale,
      );
    }

    for (var tab in group.tables) {
      final newCenter = applyTransform(tab.rect.center);
      tab.rect = Rect.fromCenter(
        center: newCenter,
        width: tab.rect.width * scale,
        height: tab.rect.height * scale,
      );
    }

    pagesPoints[group.pageIndex].addAll(bakedStrokes);
    pagesImages[group.pageIndex].addAll(group.images);
    pagesTexts[group.pageIndex].addAll(group.texts);
    pagesShapes[group.pageIndex].addAll(group.shapes);
    pagesTables[group.pageIndex].addAll(group.tables);

    activeSelectionGroup = null;
    notifyContentChanged();
  }

}
