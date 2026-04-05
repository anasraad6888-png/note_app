part of '../canvas_controller.dart';

extension CanvasDrawingLogic on CanvasController {














  void setZoom(double scale, Size screenSize) {
    if (transformationController.value.getMaxScaleOnAxis().isNaN) return;

    final Size viewportSize = this.viewportSize ?? screenSize;
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    final double currentScale = transformationController.value.getMaxScaleOnAxis();
    final double clampedScale = scale.clamp(0.05, 5.0);

    // If practically same, skip
    if ((currentScale - clampedScale).abs() < 0.001) return;

    final Offset screenCenter = Offset(viewportSize.width / 2.0, viewportSize.height / 2.0);

    // Map screen center to scene coordinate to be our focal point FOR Y AXIS ONLY!
    // (X axis coordinate mapping is polluted by InteractiveViewer's conditional Alignment feature)
    final Offset sceneCenter = transformationController.toScene(screenCenter);

    final double virtualListViewWidth = viewportSize.width > 700.0 ? viewportSize.width : 700.0;
    final double scaledListViewWidth = virtualListViewWidth * clampedScale;
    
    double targetTx = (viewportSize.width - scaledListViewWidth) / 2.0;

    // Constrain the translation so we never pan the actual ListView off-screen completely
    if (scaledListViewWidth > viewportSize.width) {
      final double minX = viewportSize.width - scaledListViewWidth;
      final double maxX = 0.0;
      targetTx = targetTx.clamp(minX, maxX);
    }

    // Y Axis zooms normally around focal point! (Because alignment.y ensures no pollution)
    double targetTy = screenCenter.dy - (sceneCenter.dy * clampedScale);

    Matrix4 newMatrix = Matrix4.identity()
      ..translate(targetTx, targetTy)
      ..scale(clampedScale);

    if (newMatrix.storage.any((v) => v.isNaN || v.isInfinite)) {
      return;
    }

    // Clamp vertical translation: content top must not be below viewport top
    final double ty = newMatrix.getTranslation().y;
    if (ty > 0) {
      newMatrix.setTranslationRaw(newMatrix.getTranslation().x, 0, 0);
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
      saveStrokes();
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

  void cancelCurrentStroke(int pageIndex) {
    if (pageIndex >= pagesPoints.length) return;

    // Cancel any active hold timers
    penHoldTimer?.cancel();
    isPenHoldTriggered = false;
    highlighterHoldTimer?.cancel();
    isHighlighterHoldTriggered = false;

    // Cancel active drawing/highlighting strokes (remove points of the interrupted stroke)
    if (pagesPoints[pageIndex].isNotEmpty && pagesPoints[pageIndex].last != null) {
      while (pagesPoints[pageIndex].isNotEmpty && pagesPoints[pageIndex].last != null) {
        pagesPoints[pageIndex].removeLast();
      }
    }

    // Cancel active shapes
    if (isShapeMode && currentDrawingShape != null) {
      currentDrawingShape = null;
      shapeStartPos = null;
    }

    // Cancel active tables
    if (isTableMode && currentDrawingTable != null) {
      currentDrawingTable = null;
      tableStartPos = null;
    }

    // Cancel active lassos
    if (isLassoMode && lassoPath != null) {
      lassoPath = null;
    }

    _lastPointTime = null;
    _lastPointOffset = null;
    _rulerLastSnappedPoint = null;
    activeStrokeLength = null;

    notifyContentChanged();
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
      saveStrokes();
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
