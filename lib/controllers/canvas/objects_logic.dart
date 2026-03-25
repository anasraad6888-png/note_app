part of '../canvas_controller.dart';

extension CanvasObjectsLogic on CanvasController {
  void startShape(int pageIndex, Offset position) {
    if (!isShapeMode) return;
    shapeStartPos = position;
    currentDrawingShape = PageShape(
      id: UniqueKey().toString(),
      type: selectedShapeType,
      rect: Rect.fromLTWH(position.dx, position.dy, 0, 0),
      borderWidth: shapeBorderWidth,
      borderColor: shapeBorderColor,
      fillColor: shapeFillColor,
      lineType: shapeLineType,
    );
    notifyContentChanged();
  }

  void updateShape(int pageIndex, Offset position) {
    if (currentDrawingShape != null && shapeStartPos != null) {
      currentDrawingShape!.rect = Rect.fromPoints(
        shapeStartPos!,
        position,
      );
      notifyContentChanged();
    }
  }

  void endShape(int pageIndex) {
    if (currentDrawingShape != null) {
      while (pagesShapes.length <= pageIndex) {
        pagesShapes.add([]);
      }
      if (currentDrawingShape!.rect.width.abs() <= 5 || currentDrawingShape!.rect.height.abs() <= 5) {
        // Single tap insertion (Default Shape: 100x100)
        currentDrawingShape!.rect = Rect.fromLTWH(
          currentDrawingShape!.rect.left,
          currentDrawingShape!.rect.top,
          100,
          100,
        );
      }
      
      // Normalize rect to always have positive width/height
      final rect = currentDrawingShape!.rect;
      final normalizedRect = Rect.fromLTRB(
        rect.left < rect.right ? rect.left : rect.right,
        rect.top < rect.bottom ? rect.top : rect.bottom,
        rect.left > rect.right ? rect.left : rect.right,
        rect.top > rect.bottom ? rect.top : rect.bottom,
      );
      currentDrawingShape!.rect = normalizedRect;
      pagesShapes[pageIndex].add(currentDrawingShape!);
      saveStrokes();
      
      currentDrawingShape = null;
      shapeStartPos = null;
      notifyContentChanged();
    }
  }

  void startTable(int pageIndex, Offset position) {
    if (!isTableMode) return;
    tableStartPos = position;
    currentDrawingTable = PageTable(
      id: UniqueKey().toString(),
      rect: Rect.fromLTWH(position.dx, position.dy, 0, 0),
      rows: tableRows,
      columns: tableCols,
      hasHeaderRow: tableHeaderRow,
      hasHeaderCol: tableHeaderCol,
      borderWidth: tableBorderWidth,
      borderColor: tableBorderColor,
      fillColor: tableFillColor,
    );
    notifyContentChanged();
  }

  void updateTable(int pageIndex, Offset position) {
    if (currentDrawingTable != null && tableStartPos != null) {
      currentDrawingTable!.rect = Rect.fromPoints(
        tableStartPos!,
        position,
      );
      notifyContentChanged();
    }
  }

  void endTable(int pageIndex) {
    if (currentDrawingTable != null) {
      while (pagesTables.length <= pageIndex) {
        pagesTables.add([]);
      }
      if (currentDrawingTable!.rect.width.abs() <= 5 || currentDrawingTable!.rect.height.abs() <= 5) {
        // Single tap insertion (Default Table: 300x200)
        currentDrawingTable!.rect = Rect.fromLTWH(
          currentDrawingTable!.rect.left,
          currentDrawingTable!.rect.top,
          300,
          200,
        );
      }
      
      final rect = currentDrawingTable!.rect;
      final normalizedRect = Rect.fromLTRB(
        rect.left < rect.right ? rect.left : rect.right,
        rect.top < rect.bottom ? rect.top : rect.bottom,
        rect.left > rect.right ? rect.left : rect.right,
        rect.top > rect.bottom ? rect.top : rect.bottom,
      );
      currentDrawingTable!.rect = normalizedRect;
      pagesTables[pageIndex].add(currentDrawingTable!);
      saveStrokes();
      
      currentDrawingTable = null;
      tableStartPos = null;
      notifyContentChanged();
    }
  }

  void addTextAt(int pageIndex, Offset position) {
    currentPageIndex = pageIndex;
    pagesTexts[pageIndex].add(
      PageText(
        id: UniqueKey().toString(),
        text: "",
        rect: Rect.fromLTWH(position.dx - 100, position.dy - 50, 200, 100),
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: defaultFontSize,
        timestamp: audioCtrl.isRecording ? audioCtrl.currentAudioTimeMs : 0,
        audioIndex: audioCtrl.isRecording ? audioCtrl.currentAudioIndex : null,
        isEditing: true,
      ),
    );
    saveStrokes();
    notifyContentChanged();
  }

  void updateImagePosition(PageImage img, Offset delta) {
    img.offset += delta;
    saveStrokes();
    notifyContentChanged();
  }

  void deleteImage(int pageIndex, PageImage img) {
    pagesImages[pageIndex].remove(img);
    saveStrokes();
    notifyContentChanged();
  }

  void updateImageSize(PageImage img, Offset delta) {
    img.size = Size(
      (img.size.width + delta.dx).clamp(50.0, double.infinity),
      (img.size.height + delta.dy).clamp(50.0, double.infinity),
    );
    saveStrokes();
    notifyContentChanged();
  }

  void bringTextToFront(int pageIndex, PageText txt) {
    if (pagesTexts[pageIndex].remove(txt)) {
      pagesTexts[pageIndex].add(txt);
      saveStrokes();
      notifyListeners();
    }
  }

  Rect? getSelectionBoundingBox(int pageIndex) {
    if (activeSelectionGroup == null || activeSelectionGroup!.pageIndex != pageIndex || activeSelectionGroup!.isEmpty) {
      return null;
    }
    final group = activeSelectionGroup!;
    
    double minX = double.infinity,
        minY = double.infinity,
        maxX = double.negativeInfinity,
        maxY = double.negativeInfinity;

    void includePoint(Offset pt) {
      if (pt.dx < minX) minX = pt.dx;
      if (pt.dy < minY) minY = pt.dy;
      if (pt.dx > maxX) maxX = pt.dx;
      if (pt.dy > maxY) maxY = pt.dy;
    }
    
    void includeRect(Rect rect) {
      includePoint(rect.topLeft);
      includePoint(rect.bottomRight);
    }

    for (var pt in group.strokes) {
      if (pt != null) includePoint(pt.offset);
    }
    for (var img in group.images) {
      includeRect(Rect.fromLTWH(img.offset.dx, img.offset.dy, img.size.width, img.size.height));
    }
    for (var txt in group.texts) {
      includeRect(txt.rect);
    }
    for (var shp in group.shapes) {
      includeRect(shp.rect);
    }
    for (var tab in group.tables) {
      includeRect(tab.rect);
    }

    if (minX == double.infinity) return null;

    final baseRect = Rect.fromLTRB(minX - 10, minY - 10, maxX + 10, maxY + 10);
    group.initialBoundingBox = baseRect;
    
    // Apply dynamic bounds mathematically tracking affine parameters
    final center = baseRect.center;
    final w = baseRect.width * group.currentScale;
    final h = baseRect.height * group.currentScale;
    final updatedCenter = center + group.currentTranslation;
    return Rect.fromCenter(center: updatedCenter, width: w, height: h);
  }

  void deleteSelection() {
    activeSelectionGroup = null;
    saveStrokes();
    notifyListeners();
  }

  void editText(BuildContext context, int pageIndex, PageText txt) {
    // This would typically show a dialog to edit the text
    // For now, let's keep it simple or implement as needed
  }

  void purgeStaleImages() {
    bool hadStale = false;
    for (var page in pagesImages) {
      final stale = page.where((img) => !File(img.path).existsSync()).toList();
      if (stale.isNotEmpty) {
        page.removeWhere((img) => !File(img.path).existsSync());
        hadStale = true;
      }
    }
    if (hadStale) {
      saveStrokes();
    }
  }

}
