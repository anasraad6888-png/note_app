part of '../canvas_controller.dart';

extension CanvasControllerLassoDrawing on CanvasController {
  void startLasso(Offset pt) {
    if (activeSelectionGroup != null) {
      commitSelection();
    }
    lassoPath = [pt];
    notifyListeners();
  }

  void updateLasso(Offset pt) {
    if (lassoPath != null) {
      lassoPath!.add(pt);
      notifyContentChanged();
    }
  }

  void finishLassoSelection(int pageIndex) {
    if (lassoPath == null || lassoPath!.length < 3) {
      lassoPath = null;
      notifyListeners();
      return;
    }

    commitSelection(); // finalize previous bounds
    
    final group = CanvasSelectionGroup(pageIndex);
    final poly = lassoPath!;

    // 1. Strokes
    List<DrawingPoint?> remainingStrokes = [];
    List<DrawingPoint> currentStroke = [];

    for (var pt in pagesPoints[pageIndex]) {
      if (pt != null) {
        currentStroke.add(pt);
      } else {
        if (currentStroke.isNotEmpty) {
          if (lassoSelectHandwriting && currentStroke.any((p) => isPointInPolygon(p.offset, poly))) {
            group.strokes.addAll(currentStroke);
            group.strokes.add(null);
          } else {
            remainingStrokes.addAll(currentStroke);
            remainingStrokes.add(null);
          }
          currentStroke.clear();
        }
      }
    }
    if (currentStroke.isNotEmpty) {
       if (lassoSelectHandwriting && currentStroke.any((p) => isPointInPolygon(p.offset, poly))) {
          group.strokes.addAll(currentStroke);
          group.strokes.add(null);
       } else {
          remainingStrokes.addAll(currentStroke);
          remainingStrokes.add(null);
       }
    }

    // 2. Images
    List<PageImage> remainingImages = [];
    if (lassoSelectImages) {
      for (var img in pagesImages[pageIndex]) {
        if (isRectInPolygon(Rect.fromLTWH(img.offset.dx, img.offset.dy, img.size.width, img.size.height), 0, poly)) {
          group.images.add(img);
        } else {
          remainingImages.add(img);
        }
      }
    } else {
      remainingImages.addAll(pagesImages[pageIndex]);
    }

    // 3. Texts
    List<PageText> remainingTexts = [];
    if (lassoSelectTexts) {
      for (var txt in pagesTexts[pageIndex]) {
        if (isRectInPolygon(txt.rect, txt.angle, poly)) {
          group.texts.add(txt);
        } else {
          remainingTexts.add(txt);
        }
      }
    } else {
      remainingTexts.addAll(pagesTexts[pageIndex]);
    }

    // 4. Shapes 
    List<PageShape> remainingShapes = [];
    if (lassoSelectShapes) {
      for (var shape in pagesShapes[pageIndex]) {
        if (isRectInPolygon(shape.rect, 0.0, poly)) {
          group.shapes.add(shape);
        } else {
          remainingShapes.add(shape);
        }
      }
    } else {
      remainingShapes.addAll(pagesShapes[pageIndex]);
    }

    // 5. Tables
    List<PageTable> remainingTables = [];
    if (lassoSelectTables) {
      for (var table in pagesTables[pageIndex]) {
        if (isRectInPolygon(table.rect, 0.0, poly)) {
          group.tables.add(table);
        } else {
          remainingTables.add(table);
        }
      }
    } else {
      remainingTables.addAll(pagesTables[pageIndex]);
    }

    if (group.isNotEmpty) {
      activeSelectionGroup = group;
      pagesPoints[pageIndex] = remainingStrokes;
      pagesImages[pageIndex] = remainingImages;
      pagesTexts[pageIndex] = remainingTexts;
      pagesShapes[pageIndex] = remainingShapes;
      pagesTables[pageIndex] = remainingTables;
      saveStrokes(); // save intermediate state
    }
    
    lassoPath = null;
    notifyListeners();
  }

}
