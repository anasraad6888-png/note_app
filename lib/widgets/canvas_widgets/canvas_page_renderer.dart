import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../controllers/canvas_controller.dart';
import '../../painters/canvas_painters.dart';
import '../pdf_page_background.dart';
import '../interactive_table_widget.dart';
import '../interactive_shape_widget.dart';
import '../interactive_text/interactive_text_widget.dart';
import 'zoom_viewfinder.dart';
import 'canvas_selection_overlay.dart';
import '../interactive_image_widget.dart';

class CanvasPageRenderer extends StatelessWidget {
  final int index;
  final CanvasController canvasCtrl;
  final bool isReadOnly;

  const CanvasPageRenderer({
    super.key,
    required this.index,
    required this.canvasCtrl,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: CanvasBackgroundPainter(
              canvasCtrl.pageTemplates[index],
              isDarkMode: canvasCtrl.isDarkMode,
            ),
          ),
        ),
        if (canvasCtrl.pdfDocument != null &&
            index < canvasCtrl.pdfDocument!.pagesCount)
          Positioned.fill(
            child: canvasCtrl.isDarkMode
                ? ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -1,
                      0,
                      0,
                      0,
                      255,
                      0,
                      -1,
                      0,
                      0,
                      255,
                      0,
                      0,
                      -1,
                      0,
                      255,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    child: PdfPageBackground(
                      document: canvasCtrl.pdfDocument!,
                      pageNumber: index + 1,
                    ),
                  )
                : PdfPageBackground(
                    document: canvasCtrl.pdfDocument!,
                    pageNumber: index + 1,
                  ),
          ),
        ClipRect(
          child: CustomPaint(
            painter: ShapePainter(
              canvasCtrl.getSyncedShapes(index),
              (!isReadOnly &&
                      canvasCtrl.currentPageIndex == index &&
                      canvasCtrl.isShapeMode)
                  ? canvasCtrl.currentDrawingShape
                  : null,
              canvasCtrl.pageTemplates[index],
              isDarkMode: canvasCtrl.isDarkMode,
              version: canvasCtrl.contentVersion,
            ),
            size: Size.infinite,
          ),
        ),
        ClipRect(
          child: CustomPaint(
            painter: DrawingPainter(
              canvasCtrl.getSyncedPoints(index),
              canvasCtrl.pageTemplates[index],
              isDarkMode: canvasCtrl.isDarkMode,
              version: canvasCtrl.contentVersion,
            ),
            size: Size.infinite,
          ),
        ),
        if (!isReadOnly &&
            canvasCtrl.lassoPath != null &&
            canvasCtrl.currentPageIndex == index)
          Positioned.fill(
            child: CustomPaint(
              painter: LassoPainter(
                canvasCtrl.lassoPath!,
                version: canvasCtrl.contentVersion,
              ),
              size: Size.infinite,
            ),
          ),
        if (!isReadOnly && canvasCtrl.activeSelectionGroup?.pageIndex == index)
          Positioned.fill(
            child: Transform(
              transform: Matrix4.identity()
                ..translate(
                  canvasCtrl.activeSelectionGroup!.currentTranslation.dx,
                  canvasCtrl.activeSelectionGroup!.currentTranslation.dy,
                )
                ..scale(canvasCtrl.activeSelectionGroup!.currentScale)
                ..rotateZ(canvasCtrl.activeSelectionGroup!.currentRotation),
              origin:
                  canvasCtrl.activeSelectionGroup!.initialBoundingBox?.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (canvasCtrl.activeSelectionGroup!.strokes.isNotEmpty)
                    CustomPaint(
                      painter: DrawingPainter(
                        canvasCtrl.activeSelectionGroup!.strokes,
                        canvasCtrl.pageTemplates[index],
                        isDarkMode: canvasCtrl.isDarkMode,
                        version: canvasCtrl.contentVersion,
                      ),
                      size: Size.infinite,
                    ),
                  ...canvasCtrl.activeSelectionGroup!.images.map(
                    (img) => Positioned(
                      left: img.offset.dx,
                      top: img.offset.dy,
                      child: InteractiveImageWidget(image: img, pageIndex: index, canvasCtrl: canvasCtrl, readOnly: true),
                    ),
                  ),
                  ...canvasCtrl.activeSelectionGroup!.texts.map(
                    (txt) => InteractiveTextWidget(
                      textData: txt,
                      isDarkMode: canvasCtrl.isDarkMode,
                      readOnly: true,
                      onSave: () {},
                      onDelete: () {},
                      onSelect: () {},
                      canvasCtrl: canvasCtrl,
                    ),
                  ),
                  ...canvasCtrl.activeSelectionGroup!.shapes.map(
                    (shp) => InteractiveShapeWidget(
                      shape: shp,
                      pageIndex: index,
                      isDarkMode: canvasCtrl.isDarkMode,
                      onSave: () {},
                      readOnly: true,
                      onUpdate: () {},
                      onDelete: () {},
                    ),
                  ),
                  ...canvasCtrl.activeSelectionGroup!.tables.map(
                    (tbl) => InteractiveTableWidget(
                      table: tbl,
                      pageIndex: index,
                      readOnly: true,
                      isDarkMode: canvasCtrl.isDarkMode,
                      onSave: () {},
                      onDelete: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (!isReadOnly)
          ClipRect(
            child: CustomPaint(
              painter: LaserPainter(
                index < canvasCtrl.activeLaserStrokes.length
                    ? canvasCtrl.activeLaserStrokes[index]
                    : [],
                fadeDuration: canvasCtrl.laserFadeDuration,
                version: canvasCtrl.contentVersion,
              ),
              size: Size.infinite,
            ),
          ),
        ...canvasCtrl
            .getSyncedImages(index)
            .asMap()
            .entries
            .map(
              (entry) => Positioned(
                key: ValueKey('img_${index}_${entry.key}_${entry.value.path}'),
                left: entry.value.offset.dx,
                top: entry.value.offset.dy,
                child: isReadOnly
                    ? InteractiveImageWidget(image: entry.value, pageIndex: index, canvasCtrl: canvasCtrl, readOnly: true)
                    : InteractiveImageWidget(image: entry.value, pageIndex: index, canvasCtrl: canvasCtrl, readOnly: false),
              ),
            ),
        ...canvasCtrl
            .getSyncedShapes(index)
            .asMap()
            .entries
            .map(
              (entry) => InteractiveShapeWidget(
                key: ValueKey(
                  'shape_interactive_${index}_${entry.key}_${entry.value.id}',
                ),
                shape: entry.value,
                pageIndex: index,
                onSave: canvasCtrl.saveStrokes,
                readOnly: isReadOnly,
                onUpdate: canvasCtrl.notifyListeners,
                onDelete: () => canvasCtrl.deleteShape(index, entry.value),
              ),
            ),
        ...canvasCtrl
            .getSyncedTables(index)
            .asMap()
            .entries
            .map(
              (entry) => InteractiveTableWidget(
                key: ValueKey('table_${index}_${entry.key}_${entry.value.id}'),
                table: entry.value,
                pageIndex: index,
                onSave: canvasCtrl.saveStrokes,
                readOnly: isReadOnly,
                isDarkMode: canvasCtrl.isDarkMode,
                onDelete: () => canvasCtrl.deleteTable(index, entry.value),
              ),
            ),
        if (!isReadOnly &&
            canvasCtrl.currentDrawingTable != null &&
            canvasCtrl.currentPageIndex == index)
          InteractiveTableWidget(
            key: ValueKey('current_table_$index'),
            table: canvasCtrl.currentDrawingTable!,
            pageIndex: index,
            onSave: canvasCtrl.saveStrokes,
            isDarkMode: canvasCtrl.isDarkMode,
            onDelete: () {},
          ),
        ...canvasCtrl
            .getSyncedTexts(index)
            .asMap()
            .entries
            .map(
              (entry) => InteractiveTextWidget(
                key: ValueKey('text_${index}_${entry.value.id}'),
                textData: entry.value,
                isDarkMode: canvasCtrl.isDarkMode,
                onSave: canvasCtrl.saveStrokes,
                readOnly: isReadOnly,
                onDelete: () => canvasCtrl.deleteText(index, entry.value),
                onSelect: () => canvasCtrl.bringTextToFront(index, entry.value),
                canvasCtrl: canvasCtrl,
              ),
            ),
            
        // Current Drawing Text Box (Indicator)
        if (!isReadOnly && canvasCtrl.isTextMode && canvasCtrl.currentDrawingTextRect != null)
          Positioned.fromRect(
            rect: Rect.fromLTRB(
              math.min(canvasCtrl.currentDrawingTextRect!.left, canvasCtrl.currentDrawingTextRect!.right),
              math.min(canvasCtrl.currentDrawingTextRect!.top, canvasCtrl.currentDrawingTextRect!.bottom),
              math.max(canvasCtrl.currentDrawingTextRect!.left, canvasCtrl.currentDrawingTextRect!.right),
              math.max(canvasCtrl.currentDrawingTextRect!.top, canvasCtrl.currentDrawingTextRect!.bottom),
            ),
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2.0, style: BorderStyle.solid),
                  color: Colors.blueAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          
        // Top-most Z-Index Layer: Interactive Selection Envelope
        if (!isReadOnly &&
            canvasCtrl.isLassoMode &&
            canvasCtrl.activeSelectionGroup?.pageIndex == index) ...[
          SelectionBoundingBox(pageIndex: index, canvasCtrl: canvasCtrl),
          SelectionContextMenu(pageIndex: index, canvasCtrl: canvasCtrl),
        ],
        ZoomTargetBox(canvasCtrl: canvasCtrl, pageIndex: index),
      ],
    );
  }
}
