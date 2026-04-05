part of '../canvas_controller.dart';

extension CanvasControllerPageManagement on CanvasController {
  void ensurePageExists(int pageIndex) {
    while (pagesPoints.length <= pageIndex) {
      pagesPoints.add([]);
      redoPagesPoints.add([]);
      pagesImages.add([]);
      pagesTexts.add([]);
      pagesShapes.add([]);
      pagesTables.add([]);
      activeLaserStrokes.add([]);
      pagesScreenshotControllers.add(ScreenshotController());
      pagesBookmarks.add(false);
      pagesOutlines.add(null);
      pdfPageMapping.add(pagesPoints.length);
      pageThumbnails.add(null);
      pageTemplates.add(const PageTemplate());
    }
    while (activeLaserStrokes.length < pagesPoints.length) {
      activeLaserStrokes.add([]);
    }
  }

  void undo(int pageIndex) {
    if (pagesPoints[pageIndex].isEmpty) return;
    if (pagesPoints[pageIndex].last == null) {
      redoPagesPoints[pageIndex].add(pagesPoints[pageIndex].removeLast());
    }
    while (pagesPoints[pageIndex].isNotEmpty &&
        pagesPoints[pageIndex].last != null) {
      redoPagesPoints[pageIndex].add(pagesPoints[pageIndex].removeLast());
    }
    saveStrokes();
    notifyContentChanged();
  }

  void redo(int pageIndex) {
    if (redoPagesPoints[pageIndex].isEmpty) return;
    bool addedPoints = false;
    while (redoPagesPoints[pageIndex].isNotEmpty) {
      final pt = redoPagesPoints[pageIndex].removeLast();
      pagesPoints[pageIndex].add(pt);
      if (pt == null && addedPoints) break;
      addedPoints = true;
    }
    saveStrokes();
    notifyContentChanged();
  }

  void toggleGrid() {
    if (pageTemplates.isEmpty) return;
    CanvasBackgroundType cbg = pageTemplates[currentPageIndex].type;
    if (cbg == CanvasBackgroundType.blank || cbg == CanvasBackgroundType.custom) {
      cbg = CanvasBackgroundType.ruled_college;
    } else if (cbg == CanvasBackgroundType.ruled_college || cbg == CanvasBackgroundType.ruled_narrow) {
      cbg = CanvasBackgroundType.grid;
    } else {
      cbg = CanvasBackgroundType.blank;
    }
    pageTemplates[currentPageIndex] = pageTemplates[currentPageIndex].copyWith(type: cbg);
    notifyListeners();
  }

}
