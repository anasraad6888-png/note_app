part of '../canvas_controller.dart';

extension CanvasToolsLogic on CanvasController {
  bool disableAllTools({bool keepAddMenu = false}) {
    bool wasSettingsOpen = showPenSettingsRow ||
        showHighlighterSettingsRow ||
        showLaserSettingsRow ||
        showEraserSettingsRow ||
        showLassoSettingsRow ||
        showTextSettingsRow;

    isTextMode = false;
    isLassoMode = false;
    isLaserMode = false;
    isPanZoomMode = false;
    isHighlighterMode = false;
    isEraserMode = false;
    isShapeMode = false;
    isTableMode = false;
    showPenSettingsRow = false;
    showHighlighterSettingsRow = false;
    showLaserSettingsRow = false;
    showTextSettingsRow = false;
    showEraserSettingsRow = false;
    showLassoSettingsRow = false;
    if (!keepAddMenu) showAddSettingsRow = false;
    notifyListeners();
    
    return wasSettingsOpen;
  }

  void toggleAddMenu() {
    bool currentlyOpen = showAddSettingsRow;
    showPenSettingsRow = false;
    showHighlighterSettingsRow = false;
    showLaserSettingsRow = false;
    showEraserSettingsRow = false;
    showTextSettingsRow = false;
    showAddSettingsRow = !currentlyOpen;
    notifyListeners();
  }

  void activatePencil() {
    if (!isLassoMode &&
        !isTextMode &&
        !isLaserMode &&
        !isPanZoomMode &&
        !isHighlighterMode &&
        !isEraserMode &&
        !isShapeMode &&
        !isTableMode &&
        selectedColor != Colors.white) {
      showPenSettingsRow = !showPenSettingsRow;
    } else {
      bool openSettings = disableAllTools();
      if (selectedColor == Colors.white) selectedColor = Colors.black;
      if (openSettings) showPenSettingsRow = true;
    }
    notifyListeners();
  }

  void activateHighlighter() {
    if (isHighlighterMode) {
      showHighlighterSettingsRow = !showHighlighterSettingsRow;
    } else {
      bool openSettings = disableAllTools();
      isHighlighterMode = true;
      if (openSettings) showHighlighterSettingsRow = true;
    }
    notifyListeners();
  }

  void activateLaser() {
    if (isLaserMode) {
      showLaserSettingsRow = !showLaserSettingsRow;
    } else {
      bool openSettings = disableAllTools();
      isLaserMode = true;
      if (openSettings) showLaserSettingsRow = true;
    }
    notifyListeners();
  }

  void activateLasso() {
    if (isLassoMode) {
      showLassoSettingsRow = !showLassoSettingsRow;
    } else {
      bool openSettings = disableAllTools();
      isLassoMode = true;
      if (openSettings) showLassoSettingsRow = true;
    }
    notifyListeners();
  }

  void activateText() {
    if (isTextMode) {
      showTextSettingsRow = !showTextSettingsRow;
    } else {
      bool openSettings = disableAllTools();
      isTextMode = true;
      if (openSettings) showTextSettingsRow = true;
    }
    notifyListeners();
  }

  void activateEraser() {
    if (isEraserMode) {
      showEraserSettingsRow = !showEraserSettingsRow;
    } else {
      bool openSettings = disableAllTools();
      isEraserMode = true;
      if (openSettings) showEraserSettingsRow = true;
    }
    notifyListeners();
  }

  void activatePanZoom() {
    if (isPanZoomMode) {
      isPanZoomMode = false;
    } else {
      disableAllTools();
      isPanZoomMode = true;
    }
    notifyListeners();
  }

  void activateShape(BuildContext context, bool isDarkMode) {
    if (isShapeMode) {
      isShapeMode = false;
    } else {
      disableAllTools(keepAddMenu: true);
      isShapeMode = true;
      // You might want to show a shape picker dialog here if needed
    }
    notifyListeners();
  }

  void activateTable(BuildContext context, bool isDarkMode) {
    if (isTableMode) {
      isTableMode = false;
    } else {
      disableAllTools(keepAddMenu: true);
      isTableMode = true;
    }
    notifyListeners();
  }

  void toggleRuler([Size? screenSize]) {
    isRulerVisible = !isRulerVisible;
    if (isRulerVisible && screenSize != null) {
      // Pass the center of the screen. 
      // RulerWidget subtracts half its dimensions (760x80) from this position.
      rulerPosition = Offset(screenSize.width / 2, screenSize.height / 2);
      rulerAngle = 0.0;
    }
    notifyListeners();
  }

  void updateRuler(Offset pos, double angle) {
    rulerPosition = pos;
    rulerAngle = angle;
    notifyListeners();
  }

  void toggleZoomWindow([Size? screenSize]) {
    isZoomWindowVisible = !isZoomWindowVisible;
    if (isZoomWindowVisible) {
      // Default to a 300x120 box in a reasonable page position
      zoomTargetRect = const Rect.fromLTWH(200, 200, 300, 120);
    }
    notifyListeners();
  }

  void toggleZoomSlider() {
    isZoomSliderVisible = !isZoomSliderVisible;
    notifyListeners();
  }

  Rect getCanvasZoomRect() {
    if (zoomTargetRect.isEmpty) return Rect.zero;
    final topLeft = transformationController.toScene(zoomTargetRect.topLeft);
    final bottomRight =
        transformationController.toScene(zoomTargetRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  Rect getCanvasPageZoomRect(int pageIndex) {
    if (zoomTargetRect.isEmpty) return Rect.zero;
    final sceneRect = getCanvasZoomRect(); // This is relative to the ListView widget
    if (sceneRect.isEmpty) return Rect.zero;

    // Page position relative to the ListView widget top-left:
    // PageSceneY - scrollOffset
    double pageLocalY = (140.0 + (pageIndex * 940.0) + 20.0) - scrollController.offset;
    double pageLocalX = 2150.0;
    
    return sceneRect.translate(-pageLocalX, -pageLocalY);
  }

  void setPenType(PenType type) {
    currentPenType = type;
    notifyListeners();
  }

  void setLineType(LineType type) {
    currentLineType = type;
    notifyListeners();
  }

  // --- Advanced Pen Settings Methods ---
  void toggleAdvancedPenSettings() {
    showAdvancedPenSettings = !showAdvancedPenSettings;
    notifyListeners();
  }

  void updateAdvancedPenSettingsPosition(Offset delta, double initialX, double initialY) {
    if (advancedPenSettingsPosition.dx < 0) {
      advancedPenSettingsPosition = Offset(initialX, initialY);
    }
    advancedPenSettingsPosition += delta;
    notifyListeners();
  }

  void setPenOpacity(double value) {
    penOpacity = value;
    notifyListeners();
  }

  void setPenSmoothing(double value) {
    penSmoothing = value;
    notifyListeners();
  }

  void togglePenAutoFill(bool value) {
    penAutoFill = value;
    notifyListeners();
  }

  void togglePenPalmRejection(bool value) {
    penPalmRejection = value;
    notifyListeners();
  }

  void togglePenPressureSensitivity(bool value) {
    penPressureSensitivity = value;
    notifyListeners();
  }
  // -------------------------------------

  void updateStrokeWidth(double v) {
    strokeWidth = v;
    strokeWidthPresets[activeStrokeWidthIndex] = v;
    notifyListeners();
  }

  void updatePressureSensitivity(double v) {
    pressureSensitivity = v;
    notifyListeners();
  }

  void updateStabilization(double v) {
    stabilization = v;
    notifyListeners();
  }

  void updateHoldToDrawShape(bool v) {
    holdToDrawShape = v;
    notifyListeners();
  }

  void updateScribbleToErase(bool v) {
    scribbleToErase = v;
    notifyListeners();
  }

  void updateHighlighterLineMode(StraightLineMode v) {
    highlighterLineMode = v;
    notifyListeners();
  }

  void updateHighlighterTip(StrokeCap v) {
    highlighterTip = v;
    notifyListeners();
  }

  void updateHighlighterThickness(double v) {
    highlighterThickness = v;
    notifyListeners();
  }

  void updateHighlighterOpacity(double v) {
    highlighterOpacity = v;
    notifyListeners();
  }

  void updateIsLaserDot(bool v) {
    isLaserDot = v;
    notifyListeners();
  }

  void updateLaserFadeDuration(int v) {
    laserFadeDuration = v;
    notifyListeners();
  }

  void updateLaserColor(Color v) {
    laserColor = v;
    notifyListeners();
  }

  void updateEraseEntireObject(bool v) {
    eraseEntireObject = v;
    notifyListeners();
  }

  void selectEraserWidthPreset(int index) {
    if (index >= 0 && index < eraserWidthPresets.length) {
      activeEraserWidthIndex = index;
      notifyListeners();
    }
  }

  void updateEraserWidthPreset(int index, double width) {
    if (index >= 0 && index < eraserWidthPresets.length) {
      eraserWidthPresets[index] = width;
      notifyListeners();
    }
  }

  void toggleEraserFilter(String filter, bool enabled) {
    if (enabled) {
      eraseFilters.add(filter);
    } else {
      eraseFilters.remove(filter);
    }
    notifyListeners();
  }

  void updateEraserWidth(double v) {
    updateEraserWidthPreset(activeEraserWidthIndex, v);
  }

  void updateDefaultTextBold() {
    defaultTextBold = !defaultTextBold;
    notifyListeners();
  }

  void updateDefaultTextItalic() {
    defaultTextItalic = !defaultTextItalic;
    notifyListeners();
  }

  void updateDefaultTextUnderline() {
    defaultTextUnderline = !defaultTextUnderline;
    notifyListeners();
  }

  void updateDefaultTextStrikethrough() {
    defaultTextStrikethrough = !defaultTextStrikethrough;
    notifyListeners();
  }

  void updateDefaultTextAlign(String v) {
    defaultTextAlign = v;
    notifyListeners();
  }

  void updateDefaultTextColor(Color v) {
    defaultTextColor = v;
    notifyListeners();
  }

  void updateDefaultTextFillColor(Color v) {
    defaultTextFillColor = v;
    notifyListeners();
  }

  void updateDefaultTextBorderColor(Color v) {
    defaultTextBorderColor = v;
    notifyListeners();
  }

  void updateSelectedColor(Color v) {
    selectedColor = v;
    notifyListeners();
  }

  void updateHighlighterColor(Color v) {
    highlighterColor = v;
    notifyListeners();
  }

  void toggleAudioBar() {
    isAudioBarVisible = !isAudioBarVisible;
    notifyListeners();
  }

  void updateZoomTargetRect(Rect rect) {
    zoomTargetRect = rect;

    // Determine which page the zoom target is currently over
    Offset sceneCenter = transformationController.toScene(rect.center);
    double yInWholeContent = sceneCenter.dy + scrollController.offset - 140.0;
    int newIndex = (yInWholeContent / 940.0).floor();
    if (newIndex >= 0 && newIndex < pagesPoints.length) {
      currentPageIndex = newIndex;
    }

    notifyListeners();
  }

  void toggleTextMode() => activateText();
  void toggleLassoMode() => activateLasso();
  void toggleLaserMode() => activateLaser();
  void togglePanZoomMode() => activatePanZoom();

  void addPage() {
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
    pdfPageMapping.add(null);
    pageThumbnails.add(null);
    pageTemplates.add(const PageTemplate());
    currentPageIndex = pagesPoints.length - 1;
    saveStrokes();
    // notifyListeners() is called by the currentPageIndex setter
  }

  void addBlankPageAt(int index) {
    if (index < 0 || index > pagesPoints.length) return;
    pagesPoints.insert(index, []);
    redoPagesPoints.insert(index, []);
    pagesImages.insert(index, []);
    pagesTexts.insert(index, []);
    pagesShapes.insert(index, []);
    pagesTables.insert(index, []);
    activeLaserStrokes.insert(index, []);
    pagesScreenshotControllers.insert(index, ScreenshotController());
    pagesBookmarks.insert(index, false);
    pagesOutlines.insert(index, null);
    pdfPageMapping.insert(index, null);
    pageThumbnails.insert(index, null);
    pageTemplates.insert(index, const PageTemplate());
    
    if (currentPageIndex >= index) {
      currentPageIndex++;
    } else {
      currentPageIndex = index;
    }
    saveStrokes();
    // notifyListeners() is called by the currentPageIndex setter
  }

  void duplicatePage(int index) {
    if (index < 0 || index >= pagesPoints.length) return;
    
    final newPoints = pagesPoints[index].map<DrawingPoint?>((pt) {
      if (pt == null) return null;
      return DrawingPoint(
        Offset(pt.offset.dx, pt.offset.dy),
        Paint()
          ..color = pt.paint.color
          ..isAntiAlias = pt.paint.isAntiAlias
          ..strokeWidth = pt.paint.strokeWidth
          ..strokeCap = pt.paint.strokeCap,
        timestamp: pt.timestamp,
        audioIndex: pt.audioIndex,
      );
    }).toList();
    final newImages = pagesImages[index].map((img) => PageImage.fromMap(img.toMap())).toList();
    final newTexts = pagesTexts[index].map((txt) {
      var map = txt.toMap();
      map['id'] = UniqueKey().toString();
      return PageText.fromMap(map);
    }).toList();
    final newShapes = pagesShapes[index].map((shp) {
      var map = shp.toMap();
      map['id'] = UniqueKey().toString();
      return PageShape.fromMap(map);
    }).toList();
    final newTables = pagesTables[index].map((tbl) {
      var map = tbl.toMap();
      map['id'] = UniqueKey().toString();
      return PageTable.fromMap(map);
    }).toList();

    int targetIndex = index + 1;
    pagesPoints.insert(targetIndex, newPoints);
    redoPagesPoints.insert(targetIndex, []);
    pagesImages.insert(targetIndex, newImages);
    pagesTexts.insert(targetIndex, newTexts);
    pagesShapes.insert(targetIndex, newShapes);
    pagesTables.insert(targetIndex, newTables);
    activeLaserStrokes.insert(targetIndex, []);
    pagesScreenshotControllers.insert(targetIndex, ScreenshotController());
    pagesBookmarks.insert(targetIndex, pagesBookmarks[index]);
    pagesOutlines.insert(targetIndex, pagesOutlines[index]);
    pdfPageMapping.insert(targetIndex, pdfPageMapping[index]); 
    pageThumbnails.insert(targetIndex, pageThumbnails[index]); // Deep copy of thumbnail byte array not strictly needed as it's immutable
    pageTemplates.insert(targetIndex, pageTemplates[index].copyWith());

    currentPageIndex = targetIndex;
    saveStrokes();
    notifyListeners();
  }

  void deletePage(int index) {
    if (pagesPoints.length <= 1) return; // Don't delete last page
    
    pagesPoints.removeAt(index);
    redoPagesPoints.removeAt(index);
    pagesImages.removeAt(index);
    pagesTexts.removeAt(index);
    pagesShapes.removeAt(index);
    pagesTables.removeAt(index);
    activeLaserStrokes.removeAt(index);
    pagesScreenshotControllers.removeAt(index);
    pagesBookmarks.removeAt(index);
    pagesOutlines.removeAt(index);
    pdfPageMapping.removeAt(index);
    pageThumbnails.removeAt(index);
    pageTemplates.removeAt(index);
    
    if (currentPageIndex >= pagesPoints.length) {
      currentPageIndex = pagesPoints.length - 1;
    }
    saveStrokes();
    notifyListeners();
  }

  void deleteSelectedPages(List<int> indices) {
    final sortedIndices = indices.toList()..sort((a, b) => b.compareTo(a));
    for (int idx in sortedIndices) {
      if (pagesPoints.length > 1) {
        deletePage(idx);
      }
    }
  }

  void reorderPage(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= pagesPoints.length) return;
    if (newIndex < 0 || newIndex > pagesPoints.length) return;
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    pagesPoints.insert(newIndex, pagesPoints.removeAt(oldIndex));
    redoPagesPoints.insert(newIndex, redoPagesPoints.removeAt(oldIndex));
    pagesImages.insert(newIndex, pagesImages.removeAt(oldIndex));
    pagesTexts.insert(newIndex, pagesTexts.removeAt(oldIndex));
    pagesShapes.insert(newIndex, pagesShapes.removeAt(oldIndex));
    pagesTables.insert(newIndex, pagesTables.removeAt(oldIndex));
    pageTemplates.insert(newIndex, pageTemplates.removeAt(oldIndex));
    activeLaserStrokes.insert(newIndex, activeLaserStrokes.removeAt(oldIndex));
    pagesScreenshotControllers.insert(newIndex, pagesScreenshotControllers.removeAt(oldIndex));
    pagesBookmarks.insert(newIndex, pagesBookmarks.removeAt(oldIndex));
    pagesOutlines.insert(newIndex, pagesOutlines.removeAt(oldIndex));
    pdfPageMapping.insert(newIndex, pdfPageMapping.removeAt(oldIndex));
    pageThumbnails.insert(newIndex, pageThumbnails.removeAt(oldIndex));

    if (currentPageIndex == oldIndex) {
      currentPageIndex = newIndex;
    } else if (oldIndex < currentPageIndex && newIndex >= currentPageIndex) {
      currentPageIndex--;
    } else if (oldIndex > currentPageIndex && newIndex <= currentPageIndex) {
      currentPageIndex++;
    }

    saveStrokes();
    notifyListeners();
  }

  void clearPage(int index) {
    ensurePageExists(index);
    pagesPoints[index].clear();
    redoPagesPoints[index].clear();
    pagesImages[index].clear();
    pagesTexts[index].clear();
    pagesShapes[index].clear();
    pagesTables[index].clear();
    notifyContentChanged();
  }

  void clearCurrentPage() {
    clearPage(currentPageIndex);
  }

  void setEraseFilter(String key, bool value) {
    if (value) {
      eraseFilters.add(key);
    } else {
      eraseFilters.remove(key);
    }
    notifyContentChanged();
  }

  Widget missingImagePlaceholder(PageImage img) {
    return Container(
      width: img.size.width,
      height: img.size.height,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  void deleteTable(int pageIndex, PageTable table) {
    pagesTables[pageIndex].remove(table);
    saveStrokes();
    notifyContentChanged();
  }

  void deleteShape(int pageIndex, PageShape shape) {
    pagesShapes[pageIndex].remove(shape);
    saveStrokes();
    notifyContentChanged();
  }

  void deleteText(int pageIndex, PageText text) {
    if (activeEditingText?.id == text.id) {
      stopEditingText();
    }
    pagesTexts[pageIndex].remove(text);
    saveStrokes();
    notifyContentChanged();
  }

}
