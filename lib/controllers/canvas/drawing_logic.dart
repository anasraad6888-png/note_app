part of '../canvas_controller.dart';

extension CanvasDrawingLogic on CanvasController {
  List<DrawingPoint?> getSyncedPoints(int pageIndex) {
    if (audioCtrl.currentAudioIndex == null ||
        (!audioCtrl.isPlaying &&
            !audioCtrl.isRecording &&
            audioCtrl.currentAudioTimeMs == 0)) {
      return pagesPoints[pageIndex];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    return pagesPoints[pageIndex].where((p) {
      if (p == null) return true;
      if (p.audioIndex != activeIndex) return true;
      return p.timestamp <= audioCtrl.currentAudioTimeMs;
    }).toList();
  }

  List<PageShape> getSyncedShapes(int index) {
    if (audioCtrl.currentAudioIndex == null ||
        (!audioCtrl.isPlaying &&
            !audioCtrl.isRecording &&
            audioCtrl.currentAudioTimeMs == 0)) {
      return pagesShapes[index];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    return pagesShapes[index].where((s) {
      if (s.audioIndex != activeIndex) return true;
      return s.timestamp <= audioCtrl.currentAudioTimeMs;
    }).toList();
  }

  List<PageImage> getSyncedImages(int index) {
    if (audioCtrl.currentAudioIndex == null ||
        (!audioCtrl.isPlaying &&
            !audioCtrl.isRecording &&
            audioCtrl.currentAudioTimeMs == 0)) {
      return pagesImages[index];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    return pagesImages[index].where((img) {
      if (img.audioIndex != activeIndex) return true;
      return img.timestamp <= audioCtrl.currentAudioTimeMs;
    }).toList();
  }

  List<PageText> getSyncedTexts(int index) {
    if (audioCtrl.currentAudioIndex == null ||
        (!audioCtrl.isPlaying &&
            !audioCtrl.isRecording &&
            audioCtrl.currentAudioTimeMs == 0)) {
      return pagesTexts[index];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    return pagesTexts[index].where((t) {
      if (t.audioIndex != activeIndex) return true;
      return t.timestamp <= audioCtrl.currentAudioTimeMs;
    }).toList();
  }

  List<PageTable> getSyncedTables(int index) {
    if (audioCtrl.currentAudioIndex == null ||
        (!audioCtrl.isPlaying &&
            !audioCtrl.isRecording &&
            audioCtrl.currentAudioTimeMs == 0)) {
      return pagesTables[index];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    return pagesTables[index].where((tbl) {
      if (tbl.audioIndex != activeIndex) return true;
      return tbl.timestamp <= audioCtrl.currentAudioTimeMs;
    }).toList();
  }

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

  void setZoom(double scale, Size screenSize) {
    if (screenSize.width <= 0 || screenSize.height <= 0) return;

    final currentScale = transformationController.value.getMaxScaleOnAxis();
    if (scale == currentScale || scale <= 0) return;

    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

    // Calculate scene center point before transformation
    final sceneCenter = transformationController.toScene(screenCenter);

    // Zoom around the center of the screen
    final newMatrix = Matrix4.identity()
      ..translate(screenCenter.dx, screenCenter.dy)
      ..scale(scale)
      ..translate(-sceneCenter.dx, -sceneCenter.dy);

    // Safety check for invalid values (prevent crash)
    if (newMatrix.storage.any((v) => v.isNaN || v.isInfinite)) {
      return;
    }

    transformationController.value = newMatrix;
  }

  void addZoomPoint(Offset localPosition, Size zoomWindowSize, {double pressure = 0.5}) {
    if (zoomTargetRect.isEmpty) return;

    // 1. Map directly from zoom window (screen-fixed) to Target Rect (page-local)
    double scale = zoomWindowSize.width / zoomTargetRect.width;
    double targetHeightInWindow = zoomTargetRect.height * scale;
    double winOffsetY = (zoomWindowSize.height - targetHeightInWindow) / 2;

    double localX = zoomTargetRect.left + (localPosition.dx / zoomWindowSize.width) * zoomTargetRect.width;
    double localY = zoomTargetRect.top + ((localPosition.dy - winOffsetY) / targetHeightInWindow) * zoomTargetRect.height;

    Offset localPoint = Offset(localX, localY);

    // 2. To support ruler snapping, we need the Screen Global position of this point
    // Page-Local -> Scene-Local (ListView space)
    double scenePointX = 2150.0 + localX;
    double scenePointY = (140.0 + (currentPageIndex * 940.0) + 20.0) + localY - scrollController.offset;

    // Scene-Local -> Screen-Global (InteractiveViewer viewport)
    Offset screenPoint = MatrixUtils.transformPoint(
        transformationController.value, Offset(scenePointX, scenePointY));

    // 3. Apply snapping and add
    Offset snappedOffset = snapToRuler(localPoint, screenPoint);
    
    // Calculate adaptive stroke width
    double scaleInViewport = transformationController.value.getMaxScaleOnAxis();

    pagesPoints[currentPageIndex].add(
      DrawingPoint(
        snappedOffset,
        Paint()
          ..color = selectedColor
          ..isAntiAlias = true
          ..strokeWidth = strokeWidth / (scale * scaleInViewport)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
        pressure: pressure,
        penType: currentPenType,
      ),
    );
    notifyListeners();
  }

  void onZoomPanEnd() {
    addPoint(currentPageIndex, null);
    saveStrokes();
  }

  Offset snapToRuler(Offset localPoint, Offset globalPoint) {
    if (!isRulerVisible) return localPoint;

    // Convert ruler position (stored in body-local coords) to global screen coords.
    // This corrects the macOS title-bar offset (and any other body-offset on any platform).
    final renderBox = canvasRepaintKey.currentContext?.findRenderObject() as RenderBox?;
    final bodyOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    double cx = rulerPosition.dx + bodyOffset.dx;
    double cy = rulerPosition.dy + bodyOffset.dy;
    double w = 760;
    double h = 80;
    double snapDistance = 45.0;

    // 1. Transform touch global point to ruler-local coordinates
    double dx = globalPoint.dx - cx;
    double dy = globalPoint.dy - cy;
    double cosA = math.cos(-rulerAngle);
    double sinA = math.sin(-rulerAngle);
    double localX = dx * cosA - dy * sinA;
    double localY = dx * sinA + dy * cosA;

    // 2. Check proximity to top/bottom edges
    bool snapped = false;
    if (localX >= -w / 2 - 20 && localX <= w / 2 + 20) {
      if (localY < 0 && localY >= -h / 2 - snapDistance) {
        localY = -h / 2; // snap to top edge
        snapped = true;
        rulerCursorLocalX = localX;
        rulerCursorEdge = -1;
      } else if (localY >= 0 && localY <= h / 2 + snapDistance) {
        localY = h / 2;  // snap to bottom edge
        snapped = true;
        rulerCursorLocalX = localX;
        rulerCursorEdge = 1;
      }
    }

    if (!snapped) {
      rulerCursorLocalX = null;
      rulerCursorEdge = 0;
    }

    // 3. إعادة النقطة المنجذبة للإحداثيات العالمية ثم حساب الفارق المحلي الدقيق
    if (snapped) {
      double rCos = math.cos(rulerAngle);
      double rSin = math.sin(rulerAngle);
      double globalSnappedX = localX * rCos - localY * rSin + cx;
      double globalSnappedY = localX * rSin + localY * rCos + cy;

      double currentScale = transformationController.value.getMaxScaleOnAxis();
      Offset result = localPoint + ((Offset(globalSnappedX, globalSnappedY) - globalPoint) / currentScale);
      
      // Accumulate stroke length
      if (_rulerLastSnappedPoint != null) {
        activeStrokeLength = (activeStrokeLength ?? 0) + (result - _rulerLastSnappedPoint!).distance;
      } else {
        activeStrokeLength = 0;
      }
      _rulerLastSnappedPoint = result;
      return result;
    }
    
    // Not snapped — reset length accumulation
    _rulerLastSnappedPoint = null;
    activeStrokeLength = null;
    return localPoint;
  }

  void addPoint(int pageIndex, Offset? offset, {Offset? globalPosition, double pressure = 0.5}) {
    ensurePageExists(pageIndex);
    if (offset != null) {
      Offset snappedOffset = globalPosition != null
          ? snapToRuler(offset, globalPosition)
          : offset;
      
      double finalPressure = pressure;
      int now = DateTime.now().millisecondsSinceEpoch;

      if (currentPenType == PenType.velocity) {
        if (_lastPointTime != null && _lastPointOffset != null) {
          double dist = (snappedOffset - _lastPointOffset!).distance;
          int dt = now - _lastPointTime!;
          if (dt > 0) {
            double velocity = dist / dt;
            // Map velocity to pressure: 
            // - Fast (e.g. 2.0 px/ms or more) -> thin (0.2 pressure)
            // - Slow (e.g. 0.2 px/ms or less) -> thick (1.0 pressure)
            finalPressure = (1.0 - (velocity / 2.0)).clamp(0.2, 1.0);
          }
        }
        _lastPointTime = now;
        _lastPointOffset = snappedOffset;
      }

      final paint = Paint()
        ..color = selectedColor.withValues(alpha: penOpacity)
        ..isAntiAlias = true
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      switch (currentPenType) {
        case PenType.ball:
          paint.strokeWidth = strokeWidth;
          break;
        case PenType.fountain:
          paint.strokeWidth = strokeWidth * 1.2;
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
          break;
        case PenType.brush:
          paint.strokeWidth = strokeWidth * 1.8;
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
          break;
        case PenType.perfect:
        case PenType.velocity:
          paint.strokeWidth = strokeWidth * 1.5;
          paint.strokeCap = StrokeCap.round;
          break;
        default:
          paint.strokeWidth = strokeWidth;
          break;
      }

      pagesPoints[pageIndex].add(
        DrawingPoint(
          snappedOffset,
          paint,
          pressure: finalPressure,
          penType: currentPenType,
          lineType: currentLineType,
          smoothing: penSmoothing,
          autoFill: penAutoFill,
          simulatePressure: penPressureSensitivity,
          timestamp: audioCtrl.isRecording ? audioCtrl.currentAudioTimeMs : now,
          audioIndex: audioCtrl.isRecording
              ? audioCtrl.currentAudioIndex
              : null,
        ),
      );

      if (isPenHoldTriggered) {
         int lastNullIndex = pagesPoints[pageIndex].lastIndexOf(null);
         int startIndex = lastNullIndex + 1;
         if (pagesPoints[pageIndex].length - startIndex > 10) {
            List<DrawingPoint?> stroke = pagesPoints[pageIndex].sublist(startIndex);
            List<DrawingPoint>? shape = ShapeRecognizer.recognizeAndConvert(stroke);
            if (shape != null) {
               pagesPoints[pageIndex].removeRange(startIndex, pagesPoints[pageIndex].length);
               pagesPoints[pageIndex].addAll(shape);
               isPenHoldTriggered = false; // Prevent endless re-triggering over the smoothed geometry
            }
         }
      }
    } else {
      isPenHoldTriggered = false;
      penHoldTimer?.cancel();
      pagesPoints[pageIndex].add(null);
      _lastPointTime = null;
      _lastPointOffset = null;
      // Reset ruler stroke length on stroke end
      _rulerLastSnappedPoint = null;
      activeStrokeLength = null;
    }
    notifyContentChanged();
  }

  void startPenHoldTimer(int pageIndex, Offset currentOffset, {Offset? globalPosition, double pressure = 0.5}) {
    if (isPenHoldTriggered) return;
    penHoldTimer?.cancel();
    penHoldTimer = Timer(const Duration(milliseconds: 1000), () {
      isPenHoldTriggered = true;
      addPoint(pageIndex, currentOffset, globalPosition: globalPosition, pressure: pressure);
    });
  }

  void addHighlighterPoint(int pageIndex, Offset? offset,
      {Offset? globalPosition}) {
    ensurePageExists(pageIndex);
    if (offset == null) {
      isHighlighterHoldTriggered = false;
      highlighterHoldTimer?.cancel();
      highlighterStrokeStartIndex = null;
      highlighterDragStartPoint = null;
      if (pagesPoints[pageIndex].isNotEmpty &&
          pagesPoints[pageIndex].last != null) {
        pagesPoints[pageIndex].add(null);
      }
      notifyContentChanged();
      return;
    }

    Offset snappedOffset = globalPosition != null
        ? snapToRuler(offset, globalPosition)
        : offset;
        
    final paint = Paint()
      ..color = highlighterColor.withValues(alpha: highlighterOpacity)
      ..isAntiAlias = true
      ..strokeWidth = highlighterThickness
      ..strokeCap = highlighterTip
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.multiply;

    if (highlighterLineMode == StraightLineMode.always ||
        isHighlighterHoldTriggered) {
      if (pagesPoints[pageIndex].isNotEmpty) {
        int lastNullIndex = pagesPoints[pageIndex].lastIndexOf(null);
        int computedStartIndex = lastNullIndex + 1;
        
        // Save initial origin state when auto-straighten activates
        if (highlighterStrokeStartIndex == null) {
           highlighterStrokeStartIndex = computedStartIndex;
           if (computedStartIndex < pagesPoints[pageIndex].length) {
              highlighterDragStartPoint = pagesPoints[pageIndex][computedStartIndex]?.offset;
           } else {
              highlighterDragStartPoint = snappedOffset;
           }
        }
        
        final startOrigin = highlighterDragStartPoint!;
        
        // Remove active stroke trail safely
        if (highlighterStrokeStartIndex! < pagesPoints[pageIndex].length) {
           pagesPoints[pageIndex].removeRange(highlighterStrokeStartIndex!, pagesPoints[pageIndex].length);
        }
        
        // Core Smart Snapping Mechanics against Text blocks and OCR
        final allTextBounds = <Rect>[];
        if (pdfTextBounds[pageIndex] != null) {
          allTextBounds.addAll(pdfTextBounds[pageIndex]!);
        }
        for (var t in pagesTexts[pageIndex]) {
          allTextBounds.add(t.rect);
        }
        
        double strokeMinY = (startOrigin.dy < snappedOffset.dy ? startOrigin.dy : snappedOffset.dy) - highlighterThickness / 2;
        double strokeMaxY = (startOrigin.dy > snappedOffset.dy ? startOrigin.dy : snappedOffset.dy) + highlighterThickness / 2;
        double strokeMinX = startOrigin.dx < snappedOffset.dx ? startOrigin.dx : snappedOffset.dx;
        double strokeMaxX = startOrigin.dx > snappedOffset.dx ? startOrigin.dx : snappedOffset.dx;
        
        Rect strokeRect = Rect.fromLTRB(strokeMinX, strokeMinY, strokeMaxX, strokeMaxY);
        List<Rect> intersectingText = allTextBounds.where((r) => r.overlaps(strokeRect)).toList();
        
        if (intersectingText.isNotEmpty) {
           for (var rect in intersectingText) {
              double snapX1 = strokeMinX > rect.left ? strokeMinX : rect.left;
              double snapX2 = strokeMaxX < rect.right ? strokeMaxX : rect.right;
              if (snapX1 < snapX2) {
                 final snapPaint = Paint()
                   ..color = paint.color
                   ..isAntiAlias = true
                   ..strokeWidth = (rect.height + 4 < highlighterThickness) ? rect.height + 4 : highlighterThickness
                   ..strokeCap = paint.strokeCap
                   ..strokeJoin = paint.strokeJoin
                   ..blendMode = paint.blendMode;
                 
                 pagesPoints[pageIndex].add(DrawingPoint(
                    Offset(snapX1, rect.center.dy), 
                    snapPaint, 
                    penType: PenType.highlighter,
                    timestamp: audioCtrl.isRecording ? audioCtrl.currentAudioTimeMs : 0,
                    audioIndex: audioCtrl.isRecording ? audioCtrl.currentAudioIndex : null,
                 ));
                 pagesPoints[pageIndex].add(DrawingPoint(
                    Offset(snapX2, rect.center.dy), 
                    snapPaint, 
                    penType: PenType.highlighter,
                    timestamp: audioCtrl.isRecording ? audioCtrl.currentAudioTimeMs : 0,
                    audioIndex: audioCtrl.isRecording ? audioCtrl.currentAudioIndex : null,
                 ));
                 pagesPoints[pageIndex].add(null);
              }
           }
           if (pagesPoints[pageIndex].isNotEmpty && pagesPoints[pageIndex].last == null) {
               pagesPoints[pageIndex].removeLast();
           }
        } else {
           pagesPoints[pageIndex].add(
                DrawingPoint(
                  startOrigin,
                  paint,
                  penType: PenType.highlighter,
                  lineType: currentLineType,
                  timestamp: audioCtrl.isRecording ? audioCtrl.currentAudioTimeMs : 0,
                  audioIndex: audioCtrl.isRecording ? audioCtrl.currentAudioIndex : null,
                ),
           );
           pagesPoints[pageIndex].add(
                DrawingPoint(
                  snappedOffset,
                  paint,
                  penType: PenType.highlighter,
                  lineType: currentLineType,
                  timestamp: audioCtrl.isRecording ? audioCtrl.currentAudioTimeMs : 0,
                  audioIndex: audioCtrl.isRecording ? audioCtrl.currentAudioIndex : null,
                ),
           );
        }
      }
    } else {
      pagesPoints[pageIndex].add(
        DrawingPoint(
          snappedOffset,
          paint,
          penType: PenType.highlighter,
          lineType: currentLineType,
          timestamp: audioCtrl.isRecording ? audioCtrl.currentAudioTimeMs : 0,
          audioIndex: audioCtrl.isRecording ? audioCtrl.currentAudioIndex : null,
        ),
      );
    }
    notifyContentChanged();
  }

  void startHighlighterHoldTimer(int pageIndex, Offset currentOffset) {
    if (highlighterLineMode != StraightLineMode.holdToDraw) return;
    if (isHighlighterHoldTriggered) return;
    highlighterHoldTimer?.cancel();
    highlighterHoldTimer = Timer(const Duration(milliseconds: 500), () {
      isHighlighterHoldTriggered = true;
      addHighlighterPoint(pageIndex, currentOffset);
    });
  }

  void addEraserPoint(int pageIndex, Offset? offset, {Offset? globalPosition}) {
    ensurePageExists(pageIndex);
    if (offset == null) {
      pagesPoints[pageIndex].add(null);
      // Reset ruler stroke tracking
      _rulerLastSnappedPoint = null;
      activeStrokeLength = null;
      notifyContentChanged();
      return;
    }
    // Apply ruler snapping to the eraser if ruler is active
    Offset snappedOffset = (globalPosition != null) 
        ? snapToRuler(offset, globalPosition)
        : offset;
    if (eraseEntireObject) {
      performObjectBasedErasure(pageIndex, snappedOffset);
    } else {
      performPixelBasedErasure(pageIndex, snappedOffset);
    }
    notifyContentChanged();
  }

  void performPixelBasedErasure(int pageIndex, Offset offset) {
    bool canErasePen = eraseFilters.contains('pen');
    bool canEraseHL = eraseFilters.contains('highlighter');
    if (!canErasePen && !canEraseHL) return;
    
    PenType eType = (canErasePen && canEraseHL) 
        ? PenType.eraserBoth 
        : (canErasePen ? PenType.eraserPen : PenType.eraserHighlighter);

    pagesPoints[pageIndex].add(
      DrawingPoint(
        offset,
        Paint()
          ..color = const Color(0x00000000)
          ..isAntiAlias = true
          ..strokeWidth = eraserWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.clear,
        penType: eType,
        timestamp: audioCtrl.isRecording ? audioCtrl.currentAudioTimeMs : 0,
        audioIndex: audioCtrl.isRecording ? audioCtrl.currentAudioIndex : null,
      ),
    );
  }

  void performObjectBasedErasure(int pageIndex, Offset offset) {
    if (eraseFilters.contains('pen') || eraseFilters.contains('highlighter')) {
      List<DrawingPoint?> page = pagesPoints[pageIndex];
      int i = 0;
      while (i < page.length) {
        int segmentStart = i;
        while (i < page.length && page[i] != null) {
          i++;
        }
        int segmentEnd = i;
        if (segmentStart < segmentEnd) {
          bool hit = false;
          bool isHL = page[segmentStart]?.penType == PenType.highlighter;
          bool isPen = !isHL;
          if ((isPen && eraseFilters.contains('pen')) ||
              (isHL && eraseFilters.contains('highlighter'))) {
            for (int k = segmentStart; k < segmentEnd; k++) {
              if ((page[k]!.offset - offset).distance < eraserWidth / 2) {
                hit = true;
                break;
              }
            }
          }
          if (hit) {
            page.removeRange(
              segmentStart,
              segmentEnd + (i < page.length ? 1 : 0),
            );
            i = segmentStart;
            continue;
          }
        }
        i++;
      }
    }
    if (eraseFilters.contains('shapes')) {
      pagesShapes[pageIndex].removeWhere(
        (shape) => shape.rect
            .inflate(shape.borderWidth + eraserWidth / 2)
            .contains(offset),
      );
    }
    if (eraseFilters.contains('images')) {
      pagesImages[pageIndex].removeWhere(
        (img) => Rect.fromLTWH(
          img.offset.dx,
          img.offset.dy,
          img.size.width,
          img.size.height,
        ).inflate(eraserWidth / 2).contains(offset),
      );
    }
    if (eraseFilters.contains('texts')) {
      pagesTexts[pageIndex].removeWhere(
        (txt) => txt.rect.inflate(eraserWidth / 2).contains(offset),
      );
    }
    if (eraseFilters.contains('tables')) {
      pagesTables[pageIndex].removeWhere(
        (tbl) => tbl.rect.inflate(eraserWidth / 2).contains(offset),
      );
    }
  }

  Future<void> saveCurrentPageToGallery(int index) async {
    try {
      if (pagesScreenshotControllers.isEmpty) return;
      final imageBytes = await pagesScreenshotControllers[index].capture(
        delay: const Duration(milliseconds: 10),
      );
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/export_image_$index.png';
        final file = await File(path).writeAsBytes(imageBytes);
        await Gal.putImage(file.path);
        showMessage?.call('تم الحفظ في معرض الصور بنجاح!');
      }
    } catch (e) {
      showMessage?.call('خطأ في الحفظ: $e', isError: true);
    }
  }

  Future<void> shareAsPdf({List<int>? pageIndices, Rect? sharePositionOrigin}) async {
    try {
      if (buildPageForExport == null) {
        throw Exception("دالة بناء صفحات التصدير غير مهيأة.");
      }

      final pdf = pw.Document();
      final indicesToExport = pageIndices ?? List.generate(pagesScreenshotControllers.length, (i) => i);
      final tempController = ScreenshotController();

      showMessage?.call('جاري تجهيز ${indicesToExport.length} صفحات للتصدير...', isError: false);

      for (var index in indicesToExport) {
        final widgetToCapture = buildPageForExport!(index);
        final imageBytes = await tempController.captureFromWidget(
          widgetToCapture,
          delay: const Duration(milliseconds: 150),
        );

        if (imageBytes.isNotEmpty) {
          final image = pw.MemoryImage(imageBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) => pw.Center(child: pw.Image(image)),
            ),
          );
        }
      }
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${document.title}.pdf';
      await File(path).writeAsBytes(await pdf.save());
      
      // On iPads, sharePositionOrigin must be provided and non-zero
      await Share.shareXFiles(
        [XFile(path)], 
        text: 'مشاركة مستند: ${document.title}',
        sharePositionOrigin: sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
      );
    } catch (e) {
      showMessage?.call('خطأ في التصدير: $e', isError: true);
    }
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

  void updateAudioIndices(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    int? mapIndex(int? current) {
      if (current == null) return null;
      if (current == oldIndex) return newIndex;
      if (oldIndex < newIndex) {
        if (current > oldIndex && current <= newIndex) return current - 1;
      } else {
        if (current >= newIndex && current < oldIndex) return current + 1;
      }
      return current;
    }

    // 1. Update current index if needed
    audioCtrl.currentAudioIndex = mapIndex(audioCtrl.currentAudioIndex);

    // 2. Update all canvas elements across all pages
    for (int p = 0; p < pagesPoints.length; p++) {
      // 1. Points
      pagesPoints[p] = pagesPoints[p].map((pt) {
        if (pt == null || pt.audioIndex == null) return pt;
        final mapped = mapIndex(pt.audioIndex);
        if (mapped == pt.audioIndex) return pt;
        return DrawingPoint(
          pt.offset,
          pt.paint,
          timestamp: pt.timestamp,
          audioIndex: mapped,
        );
      }).toList();

      // 2. Texts
      pagesTexts[p] = pagesTexts[p].map((t) {
        if (t.audioIndex == null) return t;
        final mapped = mapIndex(t.audioIndex);
        if (mapped == t.audioIndex) return t;
        return PageText(
          id: t.id,
          text: t.text,
          rect: t.rect,
          color: t.color,
          fontSize: t.fontSize,
          fontFamily: t.fontFamily,
          textAlign: t.textAlign,
          isBold: t.isBold,
          isItalic: t.isItalic,
          isUnderline: t.isUnderline,
          isStrikethrough: t.isStrikethrough,
          fillColor: t.fillColor,
          borderColor: t.borderColor,
          borderWidth: t.borderWidth,
          isEditing: t.isEditing,
          timestamp: t.timestamp,
          audioIndex: mapped,
        );
      }).toList();

      // 3. Shapes
      pagesShapes[p] = pagesShapes[p].map((s) {
        if (s.audioIndex == null) return s;
        final mapped = mapIndex(s.audioIndex);
        if (mapped == s.audioIndex) return s;
        return PageShape(
          id: s.id,
          type: s.type,
          rect: s.rect,
          borderWidth: s.borderWidth,
          borderColor: s.borderColor,
          fillColor: s.fillColor,
          lineType: s.lineType,
          timestamp: s.timestamp,
          audioIndex: mapped,
        );
      }).toList();

      // 4. Images
      pagesImages[p] = pagesImages[p].map((img) {
        if (img.audioIndex == null) return img;
        final mapped = mapIndex(img.audioIndex);
        if (mapped == img.audioIndex) return img;
        return PageImage(
          img.path,
          img.offset,
          img.size,
          timestamp: img.timestamp,
          audioIndex: mapped,
        );
      }).toList();

      // 5. Tables
      pagesTables[p] = pagesTables[p].map((tbl) {
        if (tbl.audioIndex == null) return tbl;
        final mapped = mapIndex(tbl.audioIndex);
        if (mapped == tbl.audioIndex) return tbl;
        return PageTable(
          id: tbl.id,
          rect: tbl.rect,
          rows: tbl.rows,
          columns: tbl.columns,
          hasHeaderRow: tbl.hasHeaderRow,
          hasHeaderCol: tbl.hasHeaderCol,
          borderWidth: tbl.borderWidth,
          borderColor: tbl.borderColor,
          fillColor: tbl.fillColor,
          cellTexts: tbl.cellTexts,
          cellStyles: tbl.cellStyles,
          timestamp: tbl.timestamp,
          audioIndex: mapped,
        );
      }).toList();
    }
    notifyListeners();
  }

  void addLaserPoint(int pageIndex, Offset? localPoint) {
    if (pageIndex < 0 || pageIndex >= activeLaserStrokes.length) return;

    if (localPoint == null) {
      if (isLaserDot && currentLaserStroke != null) {
        // Remove immediate on release in dot mode
        activeLaserStrokes[pageIndex].remove(currentLaserStroke);
      }
      currentLaserStroke = null;
    } else {
      if (currentLaserStroke == null) {
        currentLaserStroke = LaserStroke(
          points: [LaserPoint(localPoint)],
          color: laserColor,
          creationTime: DateTime.now(),
        );
        activeLaserStrokes[pageIndex].add(currentLaserStroke!);
      } else {
        if (isLaserDot) {
          // "No Tail" mode: only keep the last point
          currentLaserStroke!.points.clear();
          currentLaserStroke!.points.add(LaserPoint(localPoint));
        } else {
          currentLaserStroke!.points.add(LaserPoint(localPoint));
        }
        currentLaserStroke!.creationTime = DateTime.now();
      }

      // Start timer if not running (60fps animation)
      if (_laserTimer == null || !_laserTimer!.isActive) {
        _laserTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
          final now = DateTime.now();

          for (var pageStrokes in activeLaserStrokes) {
            for (var stroke in pageStrokes) {
              stroke.points.removeWhere((p) =>
                  now.difference(p.timestamp).inMilliseconds >=
                  (laserFadeDuration * 1000));
            }
            pageStrokes.removeWhere((stroke) =>
                stroke.points.isEmpty && stroke != currentLaserStroke);
          }

          // Always notify to update opacity in the painter
          notifyContentChanged();

          // Stop timer if all laser strokes are gone
          bool hasAny = currentLaserStroke != null;
          if (!hasAny) {
            for (var ps in activeLaserStrokes) {
              if (ps.isNotEmpty) {
                hasAny = true;
                break;
              }
            }
          }
          if (!hasAny) {
            timer.cancel();
            _laserTimer = null;
          }
        });
      }
    }
    notifyListeners();
  }

}
