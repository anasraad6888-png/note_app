part of '../canvas_controller.dart';

extension CanvasControllerAudioSync on CanvasController {
  List<DrawingPoint?> getSyncedPoints(int pageIndex) {
    if (audioCtrl.currentAudioIndex == null || !audioCtrl.isAudioSyncEnabled) {
      return pagesPoints[pageIndex];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    List<DrawingPoint?> result = [];
    
    for (int i = 0; i < pagesPoints[pageIndex].length; i++) {
        DrawingPoint? p = pagesPoints[pageIndex][i];
        if (p == null) {
            result.add(null);
            continue;
        }
        
        bool isHighlighter = p.penType == PenType.highlighter || p.penType == PenType.eraserHighlighter;
        bool shouldSyncThis = isHighlighter ? audioCtrl.syncHighlighter : audioCtrl.syncHandwriting;
        
        if (p.audioIndex != activeIndex || !shouldSyncThis) {
            result.add(p);
            continue;
        }
        
        bool isFuture = p.timestamp > audioCtrl.currentAudioTimeMs;
        
        DrawingPoint cloned = isFuture ? DrawingPoint(
            p.offset,
            Paint()
              ..color = p.paint.color.withValues(alpha: p.paint.color.a * 0.15)
              ..strokeWidth = p.paint.strokeWidth
              ..strokeCap = p.paint.strokeCap
              ..strokeJoin = p.paint.strokeJoin
              ..style = p.paint.style
              ..blendMode = p.paint.blendMode,
            pressure: p.pressure,
            penType: p.penType,
            timestamp: p.timestamp,
            audioIndex: p.audioIndex,
            lineType: p.lineType,
            smoothing: p.smoothing,
            autoFill: p.autoFill,
            simulatePressure: p.simulatePressure,
        ) : p;

        if (i > 0 && pagesPoints[pageIndex][i-1] != null) {
            DrawingPoint prev = pagesPoints[pageIndex][i-1]!;
            if (prev.audioIndex == activeIndex) {
                bool prevIsFuture = prev.timestamp > audioCtrl.currentAudioTimeMs;
                if (prevIsFuture != isFuture) {
                    result.add(DrawingPoint(
                      p.offset,
                      prev.paint,
                      pressure: p.pressure,
                      penType: p.penType,
                      timestamp: p.timestamp,
                      audioIndex: p.audioIndex,
                      lineType: p.lineType,
                      smoothing: p.smoothing,
                      autoFill: p.autoFill,
                      simulatePressure: p.simulatePressure,
                    ));
                    result.add(null);
                }
            }
        }
        result.add(cloned);
    }
    return result;
  }

  List<PageShape> getSyncedShapes(int index) {
    if (audioCtrl.currentAudioIndex == null || !audioCtrl.isAudioSyncEnabled || !audioCtrl.syncShapes) {
      return pagesShapes[index];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    return pagesShapes[index].map((s) {
      if (s.audioIndex != activeIndex) return s;
      bool isFuture = s.timestamp > audioCtrl.currentAudioTimeMs;
      if (!isFuture) return s;
      return PageShape(
        id: s.id,
        type: s.type,
        rect: s.rect,
        borderWidth: s.borderWidth,
        borderColor: s.borderColor.withValues(alpha: (s.borderColor.a * 0.15).clamp(0.0, 1.0)),
        fillColor: s.fillColor.withValues(alpha: (s.fillColor.a * 0.15).clamp(0.0, 1.0)),
        lineType: s.lineType,
        timestamp: s.timestamp,
        audioIndex: s.audioIndex,
      );
    }).toList();
  }

  List<PageImage> getSyncedImages(int index) {
    if (audioCtrl.currentAudioIndex == null || !audioCtrl.isAudioSyncEnabled || !audioCtrl.syncImages) {
      return pagesImages[index];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    return pagesImages[index].map((img) {
      if (img.audioIndex != activeIndex) return img;
      bool isFuture = img.timestamp > audioCtrl.currentAudioTimeMs;
      if (!isFuture) return img;
      // We cannot change opacity directly on PageImage without adding a field.
      // So we return the image unmodified, but conceptually faded in UI.
      return img;
    }).toList();
  }

  List<PageText> getSyncedTexts(int index) {
    if (audioCtrl.currentAudioIndex == null || !audioCtrl.isAudioSyncEnabled || !audioCtrl.syncTexts) {
      return pagesTexts[index];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    return pagesTexts[index].map((t) {
      if (t.audioIndex != activeIndex) return t;
      bool isFuture = t.timestamp > audioCtrl.currentAudioTimeMs;
      if (!isFuture) return t;
      return PageText(
        id: t.id,
        text: t.text,
        rect: t.rect,
        color: t.color.withValues(alpha: (t.color.a * 0.15).clamp(0.0, 1.0)),
        fontSize: t.fontSize,
        fontFamily: t.fontFamily,
        textAlign: t.textAlign,
        isBold: t.isBold,
        isItalic: t.isItalic,
        isUnderline: t.isUnderline,
        isStrikethrough: t.isStrikethrough,
        fillColor: t.fillColor.withValues(alpha: (t.fillColor.a * 0.15).clamp(0.0, 1.0)),
        borderColor: t.borderColor.withValues(alpha: (t.borderColor.a * 0.15).clamp(0.0, 1.0)),
        borderWidth: t.borderWidth,
        isEditing: false,
        timestamp: t.timestamp,
        audioIndex: t.audioIndex,
        deltaJson: t.deltaJson,
        angle: t.angle,
        borderRadius: t.borderRadius,
      );
    }).toList();
  }

  List<PageTable> getSyncedTables(int index) {
    if (audioCtrl.currentAudioIndex == null || !audioCtrl.isAudioSyncEnabled || !audioCtrl.syncTables) {
      return pagesTables[index];
    }
    int activeIndex = audioCtrl.currentAudioIndex ?? -1;
    return pagesTables[index].map((tbl) {
      if (tbl.audioIndex != activeIndex) return tbl;
      bool isFuture = tbl.timestamp > audioCtrl.currentAudioTimeMs;
      if (!isFuture) return tbl;
      return PageTable(
        id: tbl.id,
        rect: tbl.rect,
        rows: tbl.rows,
        columns: tbl.columns,
        hasHeaderRow: tbl.hasHeaderRow,
        hasHeaderCol: tbl.hasHeaderCol,
        borderWidth: tbl.borderWidth,
        borderColor: tbl.borderColor.withValues(alpha: (tbl.borderColor.a * 0.15).clamp(0.0, 1.0)),
        fillColor: tbl.fillColor.withValues(alpha: (tbl.fillColor.a * 0.15).clamp(0.0, 1.0)),
        cellTexts: tbl.cellTexts,
        cellStyles: tbl.cellStyles,
        timestamp: tbl.timestamp,
        audioIndex: tbl.audioIndex,
      );
    }).toList();
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

}
