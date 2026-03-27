import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'models/note_document.dart';
import 'models/canvas_models.dart';
import 'painters/canvas_painters.dart';
import 'dart:math' as math;
import 'widgets/pdf_page_background.dart';
import 'widgets/interactive_table_widget.dart';
import 'widgets/interactive_shape_widget.dart';
import 'widgets/interactive_text/interactive_text_widget.dart';
import 'widgets/canvas_widgets/top_toolbar.dart';
import 'widgets/canvas_widgets/drawing_tools_row.dart';
import 'widgets/canvas_widgets/audio_player_window.dart';
import 'widgets/canvas_widgets/tool_palette.dart';
import 'widgets/canvas_widgets/text_toolbar_dock.dart';
import 'widgets/canvas_widgets/settings_floating_window.dart';
import 'widgets/canvas_widgets/zoom_viewfinder.dart';
import 'widgets/ruler_widget.dart';
import 'controllers/audio_controller.dart';
import 'controllers/canvas_controller.dart';
import 'dialogs/canvas_dialogs.dart';

class DrawingCanvas extends StatefulWidget {
  final NoteDocument document;
  final Function(NoteDocument)? onSave;
  final VoidCallback? onClose;
  final bool isDarkMode;
  final VoidCallback onDarkModeToggle;

  const DrawingCanvas({
    super.key,
    required this.document,
    this.onSave,
    this.onClose,
    required this.isDarkMode,
    required this.onDarkModeToggle,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _CanvasScrollBehavior extends MaterialScrollBehavior {
  final bool allowDrag;
  const _CanvasScrollBehavior(this.allowDrag);

  @override
  Set<ui.PointerDeviceKind> get dragDevices => allowDrag
      ? {
          ui.PointerDeviceKind.touch,
          ui.PointerDeviceKind.stylus,
          ui.PointerDeviceKind.mouse,
          ui.PointerDeviceKind.trackpad,
        }
      : <ui.PointerDeviceKind>{};
}

const double _kInfiniteCanvasSize = 50000.0;

class _DrawingCanvasState extends State<DrawingCanvas>
    with WidgetsBindingObserver {
  late AudioController audioCtrl;
  late CanvasController canvasCtrl;
  int _pointerCount = 0;
  bool _isSpacePressed = false;
  bool _isStylusButtonPressed = false;
  bool _infiniteCentered = false;

  bool get _shouldNavigate {
    return canvasCtrl.isPanZoomMode ||
        _pointerCount > 1 ||
        _isSpacePressed ||
        _isStylusButtonPressed;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWithNewDocument();
  }

  /// Called by the OS whenever window metrics change (keyboard show/hide).
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final editCtx = canvasCtrl.activeEditingContext;
      if (editCtx == null) return;
      if (!editCtx.mounted) return;

      // Scroll the canvas so the text box is visible above the keyboard.
      // alignment=0.3 positions the text box 30% from the top of the viewport,
      // ensuring it's clear of both the top toolbar and text formatting toolbar.
      Scrollable.ensureVisible(
        editCtx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.3,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    audioCtrl.dispose();
    canvasCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id) {
      // Document changed, rebuild the controller
      audioCtrl.dispose();
      canvasCtrl.dispose();
      _initWithNewDocument();
    } else if (oldWidget.isDarkMode != widget.isDarkMode) {
      canvasCtrl.isDarkMode = widget.isDarkMode;
    }
  }

  void _initWithNewDocument() {
    audioCtrl = AudioController(
      document: widget.document,
      onSave: () => canvasCtrl.saveStrokes(),
      onIndicesUpdated: (oldIdx, newIdx) =>
          canvasCtrl.updateAudioIndices(oldIdx, newIdx),
      showMessage: (msg, {bool isError = false}) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: isError ? Colors.red : Colors.green,
            ),
          );
        }
      },
      onShare: (path, title) async {
        final box = context.findRenderObject() as RenderBox?;
        await Share.share(
          title,
          subject: title,
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        );
      },
    );

    canvasCtrl =
        CanvasController(
            document: widget.document,
            audioCtrl: audioCtrl,
            onSave: widget.onSave ?? (_) {},
            isDarkMode: widget.isDarkMode,
            onDarkModeToggle: widget.onDarkModeToggle,
            showMessage: (msg, {bool isError = false}) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: isError ? Colors.red : Colors.green,
                  ),
                );
              }
            },
            buildPageForExport: (index) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Material(
                  color: widget.isDarkMode
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  child: SizedBox(
                    width: 700,
                    height: 900,
                    child: _buildPageContent(index, isReadOnly: true),
                  ),
                ),
              );
            },
          )
          ..onShowPagesGridDialog = () {
            CanvasDialogs.showPagesGridDialog(
              context: context,
              canvasCtrl: canvasCtrl,
            );
          };
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([audioCtrl, canvasCtrl]),
      builder: (context, child) {
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.space) {
              if (event is KeyDownEvent) {
                if (!_isSpacePressed) setState(() => _isSpacePressed = true);
              } else if (event is KeyUpEvent) {
                if (_isSpacePressed) setState(() => _isSpacePressed = false);
              }
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            resizeToAvoidBottomInset:
                false, // Outer Scaffold (MainScreen) already handles keyboard avoidance
            backgroundColor: canvasCtrl.isDarkMode
                ? const Color(0xFF141414)
                : Colors.white,
            body: Listener(
              onPointerDown: (e) {
                bool isStylus =
                    (e.buttons & kSecondaryButton != 0) ||
                    (e.kind == PointerDeviceKind.stylus && e.buttons == 2);
                setState(() {
                  _pointerCount++;
                  if (isStylus) _isStylusButtonPressed = true;
                });
              },
              onPointerUp: (e) {
                setState(() {
                  _pointerCount--;
                  _isStylusButtonPressed = false;
                });
              },
              onPointerCancel: (e) {
                setState(() {
                  _pointerCount--;
                  _isStylusButtonPressed = false;
                });
              },
              child: RepaintBoundary(
                key: canvasCtrl.canvasRepaintKey,
                child: SizedBox.expand(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Display Layer (Canvas)
                      Positioned.fill(
                        child: ValueListenableBuilder<Matrix4>(
                          valueListenable: canvasCtrl.transformationController,
                          builder: (context, matrix, child) {
                            final scale = matrix.getMaxScaleOnAxis();
                            // Check if the current page has infinite canvas enabled
                            final idx = canvasCtrl.currentPageIndex;
                            final isInfinitePage =
                                canvasCtrl.pageTemplates.isNotEmpty &&
                                idx < canvasCtrl.pageTemplates.length &&
                                canvasCtrl.pageTemplates[idx].isInfinite;

                            if (isInfinitePage) {
                              // Center the infinite canvas the first time we enter infinite mode
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!_infiniteCentered) {
                                  _centerInfiniteCanvas();
                                }
                              });

                              return InteractiveViewer(
                                transformationController:
                                    canvasCtrl.transformationController,
                                minScale: 0.02,
                                maxScale: 20.0,
                                boundaryMargin: const EdgeInsets.all(
                                  double.infinity,
                                ),
                                panEnabled: _shouldNavigate,
                                panAxis: PanAxis.free,
                                scaleEnabled: true,
                                constrained: false,
                                child: SizedBox(
                                  width: _kInfiniteCanvasSize,
                                  height: _kInfiniteCanvasSize,
                                  child: _buildInfinitePage(idx),
                                ),
                              );
                            }

                            // Normal paged mode — reset transform to identity when returning from infinite
                            if (_infiniteCentered) {
                              _infiniteCentered = false;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                canvasCtrl.transformationController.value =
                                    Matrix4.identity();
                              });
                            }
                            final panAxis = scale <= 1.05
                                ? PanAxis.vertical
                                : PanAxis.free;
                            // Calculate minScale dynamically so the user cannot
                            // zoom out past the point where all pages are visible.
                            // Total ListView height = top(80) + pages*(900+40) + bottom(20)
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                // Save exact viewport size for zoom controls
                                // so they don't rely on the larger MediaQuery size.
                                canvasCtrl.viewportSize =
                                    Size(constraints.maxWidth, constraints.maxHeight);

                                final int pageCount =
                                    widget.document.pages.length;
                                final double totalContentH =
                                    16.0 + pageCount * 940.0 + 16.0;
                                final double minScaleH =
                                    constraints.maxHeight / totalContentH;
                                final double minScaleW =
                                    constraints.maxWidth / 700.0;
                                // Clamp: use whichever fits better, never below 0.05
                                final double computedMin =
                                    (minScaleH < minScaleW
                                            ? minScaleH
                                            : minScaleW)
                                        .clamp(0.05, 1.0);
                                return InteractiveViewer(
                                  transformationController:
                                      canvasCtrl.transformationController,
                                  minScale: computedMin,
                                  maxScale: 20.0,
                                  boundaryMargin: EdgeInsets.symmetric(
                                    horizontal: constraints.maxWidth,
                                    vertical: 0.0,
                                  ),
                                  panEnabled: _shouldNavigate || _pointerCount > 1,
                                  panAxis: panAxis,
                                  scaleEnabled: true,
                                  constrained: false,
                                  child: SizedBox(
                                    width: 700,
                                    child: ListView.builder(
                                      // InteractiveViewer (constrained:false) handles all
                                      // pan/scroll gestures — disable ListView scrolling
                                      // to prevent gesture conflicts.
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.only(
                                        top: 16,
                                        bottom: 16,
                                      ),
                                      controller: canvasCtrl.scrollController,
                                      itemCount: widget.document.pages.length,
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) =>
                                          _buildPage(index),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Ruler: rendered BELOW toolbars so toolbars are always accessible
                      if (canvasCtrl.isRulerVisible)
                        RulerWidget(
                          initialPosition: canvasCtrl.rulerPosition,
                          initialAngle: canvasCtrl.rulerAngle,
                          onChanged: canvasCtrl.updateRuler,
                          onClose: canvasCtrl.toggleRuler,
                          strokeLength: canvasCtrl.activeStrokeLength,
                          cursorLocalX: canvasCtrl.rulerCursorLocalX,
                          cursorEdge: canvasCtrl.rulerCursorEdge,
                        ),

                      ZoomBottomWindow(canvasCtrl: canvasCtrl),

                      if (canvasCtrl.activeEditingText == null)
                        CanvasToolPalette(
                          canvasCtrl: canvasCtrl,
                          audioCtrl: audioCtrl,
                        )
                      else
                        TextToolbarDock(canvasCtrl: canvasCtrl),

                      // Toolbars (should be on top)
                      CanvasTopToolbar(
                        canvasCtrl: canvasCtrl,
                        audioCtrl: audioCtrl,
                        onClose: widget.onClose,
                      ),

                      // Floating Settings
                      CanvasSettingsFloatingWindow(canvasCtrl: canvasCtrl),

                      // ---------------- Drop Zones for Toolbar ----------------
                      if (canvasCtrl.isDraggingPalette) ...[
                        // منطقة التقاط اليسار
                        Positioned(
                          left: 0,
                          top: 100,
                          bottom: 100,
                          width: 60,
                          child: DragTarget<String>(
                            onWillAcceptWithDetails: (d) =>
                                d.data == 'dock_tools' &&
                                canvasCtrl.toolbarPosition !=
                                    ToolbarPosition.left,
                            onAcceptWithDetails: (d) {
                              canvasCtrl.updateToolbarPosition(
                                ToolbarPosition.left,
                              );
                              canvasCtrl.setDraggingPalette(false);
                            },
                            builder: (ctx, candidate, _) => Container(
                              color: candidate.isNotEmpty
                                  ? Colors.blue.withAlpha(50)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        // منطقة التقاط اليمين
                        Positioned(
                          right: 0,
                          top: 100,
                          bottom: 100,
                          width: 60,
                          child: DragTarget<String>(
                            onWillAcceptWithDetails: (d) =>
                                d.data == 'dock_tools' &&
                                canvasCtrl.toolbarPosition !=
                                    ToolbarPosition.right,
                            onAcceptWithDetails: (d) {
                              canvasCtrl.updateToolbarPosition(
                                ToolbarPosition.right,
                              );
                              canvasCtrl.setDraggingPalette(false);
                            },
                            builder: (ctx, candidate, _) => Container(
                              color: candidate.isNotEmpty
                                  ? Colors.blue.withAlpha(50)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        // منطقة التقاط الأسفل
                        Positioned(
                          bottom: 0,
                          left: 100,
                          right: 100,
                          height: 80,
                          child: DragTarget<String>(
                            onWillAcceptWithDetails: (d) =>
                                d.data == 'dock_tools' &&
                                canvasCtrl.toolbarPosition !=
                                    ToolbarPosition.bottom,
                            onAcceptWithDetails: (d) {
                              canvasCtrl.updateToolbarPosition(
                                ToolbarPosition.bottom,
                              );
                              canvasCtrl.setDraggingPalette(false);
                            },
                            builder: (ctx, candidate, _) => Container(
                              color: candidate.isNotEmpty
                                  ? Colors.blue.withAlpha(50)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ],

                      if (audioCtrl.isAudioBarVisible)
                        AudioPlayerWindow(
                          audioCtrl: audioCtrl,
                          isDarkMode: canvasCtrl.isDarkMode,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Centers the TransformationController to the middle of the infinite canvas.
  void _centerInfiniteCanvas() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final viewportSize = renderBox.size;
    // We want the center of the 50000x50000 canvas to appear in the center of the screen.
    final centerOffset = Offset(
      _kInfiniteCanvasSize / 2 - viewportSize.width / 2,
      _kInfiniteCanvasSize / 2 - viewportSize.height / 2,
    );
    canvasCtrl.transformationController.value = Matrix4.identity()
      ..translate(-centerOffset.dx, -centerOffset.dy);
    _infiniteCentered = true;
  }

  /// Builds the infinite canvas as a full 50000x50000 surface
  Widget _buildInfinitePage(int index) {
    canvasCtrl.ensurePageExists(index);
    final template = canvasCtrl.pageTemplates[index];
    return Listener(
      onPointerDown: (event) {
        if (_shouldNavigate) return;
        if (canvasCtrl.penPalmRejection && event.radiusMajor > 20.0) return;

        canvasCtrl.currentPageIndex = index;
        if (canvasCtrl.isEraserMode) {
          canvasCtrl.addEraserPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
          );
        } else if (canvasCtrl.isLaserMode) {
          canvasCtrl.addLaserPoint(index, event.localPosition);
        } else if (canvasCtrl.isHighlighterMode) {
          canvasCtrl.addHighlighterPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
          );
          canvasCtrl.startHighlighterHoldTimer(index, event.localPosition);
        } else if (canvasCtrl.isShapeMode) {
          canvasCtrl.startShape(index, event.localPosition);
        } else if (canvasCtrl.isTableMode) {
          canvasCtrl.startTable(index, event.localPosition);
        } else if (canvasCtrl.isLassoMode) {
          if (!canvasCtrl.isPointInSelectionUI(event.localPosition)) {
            canvasCtrl.startLasso(event.localPosition);
          }
        } else if (canvasCtrl.isTextMode) {
          bool isHit = false;
          final expandedRectRadius = const EdgeInsets.all(50.0);
          for (var txt in canvasCtrl.getSyncedTexts(index)) {
            // Add a small 20px padding to the exact rect to generously catch taps on borders
            if (expandedRectRadius
                .inflateRect(txt.rect)
                .contains(event.localPosition)) {
              isHit = true;
              break;
            }
          }
          if (!isHit) canvasCtrl.addTextAt(index, event.localPosition);
        } else if (!canvasCtrl.isTextMode) {
          canvasCtrl.addPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
            pressure: event.pressure,
          );
          canvasCtrl.startPenHoldTimer(
            index,
            event.localPosition,
            globalPosition: event.position,
            pressure: event.pressure,
          );
        }
      },
      onPointerMove: (event) {
        if (_shouldNavigate) return;
        if (canvasCtrl.penPalmRejection && event.radiusMajor > 20.0) return;

        if (canvasCtrl.isEraserMode) {
          canvasCtrl.addEraserPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
          );
        } else if (canvasCtrl.isLaserMode) {
          canvasCtrl.addLaserPoint(index, event.localPosition);
        } else if (canvasCtrl.isHighlighterMode) {
          canvasCtrl.addHighlighterPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
          );
          canvasCtrl.startHighlighterHoldTimer(index, event.localPosition);
        } else if (canvasCtrl.isShapeMode) {
          canvasCtrl.updateShape(index, event.localPosition);
        } else if (canvasCtrl.isTableMode) {
          canvasCtrl.updateTable(index, event.localPosition);
        } else if (canvasCtrl.isLassoMode) {
          if (canvasCtrl.lassoPath != null) {
            canvasCtrl.updateLasso(event.localPosition);
          }
        } else if (!canvasCtrl.isTextMode) {
          canvasCtrl.addPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
            pressure: event.pressure,
          );
          canvasCtrl.startPenHoldTimer(
            index,
            event.localPosition,
            globalPosition: event.position,
            pressure: event.pressure,
          );
        }
      },
      onPointerUp: (event) {
        if (_shouldNavigate) return;
        if (canvasCtrl.penPalmRejection && event.radiusMajor > 20.0) return;

        if (canvasCtrl.isEraserMode) {
          canvasCtrl.addEraserPoint(index, null);
        } else if (canvasCtrl.isLaserMode) {
          canvasCtrl.addLaserPoint(index, null);
        } else if (canvasCtrl.isHighlighterMode) {
          canvasCtrl.highlighterHoldTimer?.cancel();
          canvasCtrl.isHighlighterHoldTriggered = false;
          canvasCtrl.addHighlighterPoint(index, null);
        } else if (canvasCtrl.isShapeMode) {
          canvasCtrl.endShape(index);
        } else if (canvasCtrl.isTableMode) {
          canvasCtrl.endTable(index);
        } else if (canvasCtrl.isLassoMode) {
          if (canvasCtrl.lassoPath != null) {
            canvasCtrl.finishLassoSelection(index);
          }
        } else if (!canvasCtrl.isTextMode) {
          canvasCtrl.penHoldTimer?.cancel();
          canvasCtrl.isPenHoldTriggered = false;
          canvasCtrl.addPoint(index, null);
        }
      },
      child: Stack(
        children: [
          // Infinite tiled background
          Positioned.fill(
            child: CustomPaint(
              painter: CanvasBackgroundPainter(
                template,
                isDarkMode: canvasCtrl.isDarkMode,
              ),
              size: const Size(_kInfiniteCanvasSize, _kInfiniteCanvasSize),
            ),
          ),
          // Strokes
          Positioned.fill(
            child: CustomPaint(
              painter: DrawingPainter(
                canvasCtrl.getSyncedPoints(index),
                template,
                isDarkMode: canvasCtrl.isDarkMode,
                version: canvasCtrl.contentVersion,
              ),
              size: const Size(_kInfiniteCanvasSize, _kInfiniteCanvasSize),
            ),
          ),
          // Shapes
          Positioned.fill(
            child: CustomPaint(
              painter: ShapePainter(
                canvasCtrl.getSyncedShapes(index),
                canvasCtrl.isShapeMode ? canvasCtrl.currentDrawingShape : null,
                template,
                isDarkMode: canvasCtrl.isDarkMode,
                version: canvasCtrl.contentVersion,
              ),
              size: const Size(_kInfiniteCanvasSize, _kInfiniteCanvasSize),
            ),
          ),
          // Lasso
          if (canvasCtrl.lassoPath != null &&
              canvasCtrl.currentPageIndex == index)
            Positioned.fill(
              child: CustomPaint(
                painter: LassoPainter(
                  canvasCtrl.lassoPath!,
                  version: canvasCtrl.contentVersion,
                ),
                size: const Size(_kInfiniteCanvasSize, _kInfiniteCanvasSize),
              ),
            ),
          // Laser
          Positioned.fill(
            child: CustomPaint(
              painter: LaserPainter(
                index < canvasCtrl.activeLaserStrokes.length
                    ? canvasCtrl.activeLaserStrokes[index]
                    : [],
                fadeDuration: canvasCtrl.laserFadeDuration,
                version: canvasCtrl.contentVersion,
              ),
              size: const Size(_kInfiniteCanvasSize, _kInfiniteCanvasSize),
            ),
          ),

          // Images
          ...canvasCtrl
              .getSyncedImages(index)
              .asMap()
              .entries
              .map(
                (entry) => Positioned(
                  key: ValueKey(
                    'infimg_${index}_${entry.key}_${entry.value.path}',
                  ),
                  left: entry.value.offset.dx,
                  top: entry.value.offset.dy,
                  child: _buildInteractiveImage(entry.value, index),
                ),
              ),
          // Shapes (interactive)
          ...canvasCtrl
              .getSyncedShapes(index)
              .asMap()
              .entries
              .map(
                (entry) => InteractiveShapeWidget(
                  key: ValueKey(
                    'infshape_${index}_${entry.key}_${entry.value.id}',
                  ),
                  shape: entry.value,
                  pageIndex: index,
                  onSave: canvasCtrl.saveStrokes,
                  readOnly: false,
                  onUpdate: canvasCtrl.notifyListeners,
                  onDelete: () => canvasCtrl.deleteShape(index, entry.value),
                ),
              ),
          // Tables (interactive)
          ...canvasCtrl
              .getSyncedTables(index)
              .asMap()
              .entries
              .map(
                (entry) => InteractiveTableWidget(
                  key: ValueKey(
                    'inftbl_${index}_${entry.key}_${entry.value.id}',
                  ),
                  table: entry.value,
                  pageIndex: index,
                  onSave: canvasCtrl.saveStrokes,
                  readOnly: false,
                  isDarkMode: canvasCtrl.isDarkMode,
                  onDelete: () => canvasCtrl.deleteTable(index, entry.value),
                ),
              ),
          // Texts (interactive)
          ...canvasCtrl
              .getSyncedTexts(index)
              .asMap()
              .entries
              .map(
                (entry) => InteractiveTextWidget(
                  key: ValueKey(
                    'inftxt_${index}_${entry.key}_${entry.value.id}',
                  ),
                  textData: entry.value,
                  isDarkMode: canvasCtrl.isDarkMode,
                  readOnly: false,
                  onSave: canvasCtrl.saveStrokes,
                  onDelete: () => canvasCtrl.deleteText(index, entry.value),
                  onSelect: () => canvasCtrl.currentPageIndex = index,
                  canvasCtrl: canvasCtrl,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    canvasCtrl.ensurePageExists(index);

    return Padding(
      key: ObjectKey(canvasCtrl.pagesScreenshotControllers[index]),
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: Container(
          width: 700,
          height: 900,
          decoration: BoxDecoration(
            color: canvasCtrl.isDarkMode ? Colors.black : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Screenshot(
            controller: canvasCtrl.pagesScreenshotControllers[index],
            child: _buildPageInteractionLayer(index),
          ),
        ),
      ),
    );
  }

  Widget _buildPageInteractionLayer(int index) {
    return Listener(
      onPointerDown: (event) {
        if (_shouldNavigate) return;
        if (canvasCtrl.penPalmRejection && event.radiusMajor > 20.0) return;

        canvasCtrl.currentPageIndex = index;
        if (canvasCtrl.isEraserMode) {
          canvasCtrl.addEraserPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
          );
        } else if (canvasCtrl.isLaserMode) {
          canvasCtrl.addLaserPoint(index, event.localPosition);
        } else if (canvasCtrl.isHighlighterMode) {
          canvasCtrl.addHighlighterPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
          );
          canvasCtrl.startHighlighterHoldTimer(index, event.localPosition);
        } else if (canvasCtrl.isShapeMode) {
          canvasCtrl.startShape(index, event.localPosition);
        } else if (canvasCtrl.isTableMode) {
          canvasCtrl.startTable(index, event.localPosition);
        } else if (canvasCtrl.isLassoMode) {
          if (!canvasCtrl.isPointInSelectionUI(event.localPosition)) {
            canvasCtrl.startLasso(event.localPosition);
          }
        } else if (canvasCtrl.isTextMode) {
          bool isHit = false;
          final expandedRectRadius = const EdgeInsets.all(50.0);
          for (var txt in canvasCtrl.getSyncedTexts(index)) {
            if (expandedRectRadius
                .inflateRect(txt.rect)
                .contains(event.localPosition)) {
              isHit = true;
              break;
            }
          }
          if (!isHit) canvasCtrl.addTextAt(index, event.localPosition);
        } else if (!canvasCtrl.isTextMode) {
          canvasCtrl.addPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
            pressure: event.pressure,
          );
          canvasCtrl.startPenHoldTimer(
            index,
            event.localPosition,
            globalPosition: event.position,
            pressure: event.pressure,
          );
        }
      },
      onPointerMove: (event) {
        if (_shouldNavigate) return;
        if (canvasCtrl.penPalmRejection && event.radiusMajor > 20.0) return;

        if (canvasCtrl.isEraserMode) {
          canvasCtrl.addEraserPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
          );
        } else if (canvasCtrl.isLaserMode) {
          canvasCtrl.addLaserPoint(index, event.localPosition);
        } else if (canvasCtrl.isHighlighterMode) {
          canvasCtrl.addHighlighterPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
          );
          canvasCtrl.startHighlighterHoldTimer(index, event.localPosition);
        } else if (canvasCtrl.isShapeMode) {
          canvasCtrl.updateShape(index, event.localPosition);
        } else if (canvasCtrl.isTableMode) {
          canvasCtrl.updateTable(index, event.localPosition);
        } else if (canvasCtrl.isLassoMode) {
          if (canvasCtrl.lassoPath != null) {
            canvasCtrl.updateLasso(event.localPosition);
          }
        } else if (!canvasCtrl.isTextMode) {
          canvasCtrl.addPoint(
            index,
            event.localPosition,
            globalPosition: event.position,
            pressure: event.pressure,
          );
          canvasCtrl.startPenHoldTimer(
            index,
            event.localPosition,
            globalPosition: event.position,
            pressure: event.pressure,
          );
        }
      },
      onPointerUp: (event) {
        if (_shouldNavigate) return;
        if (canvasCtrl.penPalmRejection && event.radiusMajor > 20.0) return;

        if (canvasCtrl.isEraserMode) {
          canvasCtrl.addEraserPoint(index, null);
        } else if (canvasCtrl.isLaserMode) {
          canvasCtrl.addLaserPoint(index, null);
        } else if (canvasCtrl.isHighlighterMode) {
          canvasCtrl.highlighterHoldTimer?.cancel();
          canvasCtrl.isHighlighterHoldTriggered = false;
          canvasCtrl.addHighlighterPoint(index, null);
        } else if (canvasCtrl.isShapeMode) {
          canvasCtrl.endShape(index);
        } else if (canvasCtrl.isTableMode) {
          canvasCtrl.endTable(index);
        } else if (canvasCtrl.isLassoMode) {
          if (canvasCtrl.lassoPath != null) {
            canvasCtrl.finishLassoSelection(index);
          }
        } else if (!canvasCtrl.isTextMode) {
          canvasCtrl.penHoldTimer?.cancel();
          canvasCtrl.isPenHoldTriggered = false;
          canvasCtrl.addPoint(index, null);
        }
      },
      child: _buildPageContent(index),
    );
  }

  Widget _buildPageContent(int index, {bool isReadOnly = false}) {
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
                      child: _buildReadOnlyImage(img),
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
                    ? _buildReadOnlyImage(entry.value)
                    : _buildInteractiveImage(entry.value, index),
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
        // Top-most Z-Index Layer: Interactive Selection Envelope
        if (!isReadOnly &&
            canvasCtrl.isLassoMode &&
            canvasCtrl.activeSelectionGroup?.pageIndex == index) ...[
          _buildSelectionBoundingBox(index),
          _buildSelectionContextMenu(index),
        ],
        ZoomTargetBox(canvasCtrl: canvasCtrl, pageIndex: index),
      ],
    );
  }

  Widget _buildReadOnlyImage(PageImage img) {
    return SizedBox(
      width: img.size.width,
      height: img.size.height,
      child: File(img.path).existsSync()
          ? Image.file(
              File(img.path),
              width: img.size.width,
              height: img.size.height,
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) =>
                  canvasCtrl.missingImagePlaceholder(img),
            )
          : canvasCtrl.missingImagePlaceholder(img),
    );
  }

  Widget _buildInteractiveImage(PageImage img, int index) {
    return Stack(
      children: [
        GestureDetector(
          onPanUpdate: (canvasCtrl.isPanZoomMode || canvasCtrl.isTextMode)
              ? null
              : (details) => canvasCtrl.updateImagePosition(img, details.delta),
          child: File(img.path).existsSync()
              ? Image.file(
                  File(img.path),
                  width: img.size.width,
                  height: img.size.height,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) =>
                      canvasCtrl.missingImagePlaceholder(img),
                )
              : canvasCtrl.missingImagePlaceholder(img),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.red, size: 20),
            onPressed: () => canvasCtrl.deleteImage(index, img),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onPanUpdate: (details) =>
                canvasCtrl.updateImageSize(img, details.delta),
            child: Container(
              color: Colors.blue.withAlpha(150),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                LucideIcons.maximize2,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionBoundingBox(int pageIndex) {
    final rect = canvasCtrl.getSelectionBoundingBox(pageIndex);
    if (rect == null) return const SizedBox.shrink();

    final group = canvasCtrl.activeSelectionGroup!;
    const double pad = 24.0;

    return Positioned(
      left: rect.left - pad,
      top: rect.top - pad,
      width: rect.width + (pad * 2),
      height: rect.height + (pad * 2),
      child: Transform.rotate(
        angle: group.currentRotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: pad,
              top: pad,
              right: pad,
              bottom: pad,
              child: GestureDetector(
                onPanUpdate: (details) {
                  canvasCtrl.translateSelection(details.delta);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    color: Colors.blueAccent.withAlpha(20),
                  ),
                ),
              ),
            ),
            // Delete Handle
            Positioned(
              top: pad - 15,
              left: pad - 15,
              child: GestureDetector(
                onTap: () => canvasCtrl.deleteSelection(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Rotate Handle
            Positioned(
              top: pad - 15,
              right: pad - 15,
              child: GestureDetector(
                onPanUpdate: (details) {
                  canvasCtrl.rotateSelection(details.delta.dx / 100.0);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    Icons.rotate_right,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Scale Handle
            Positioned(
              bottom: pad - 15,
              right: pad - 15,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final mag = (details.delta.dx + details.delta.dy) / 200.0;
                  canvasCtrl.scaleSelection(1.0 + mag);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.maximize2,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionContextMenu(int pageIndex) {
    final rect = canvasCtrl.getSelectionBoundingBox(pageIndex);
    if (rect == null) return const SizedBox.shrink();

    return Positioned(
      left: rect.left + (rect.width / 2),
      top: rect.top - 60,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: canvasCtrl.isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.scissors, size: 20),
                onPressed: () => canvasCtrl.cutSelection(),
                tooltip: 'Cut',
                color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 20),
                onPressed: () => canvasCtrl.copySelection(),
                tooltip: 'Copy',
                color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              IconButton(
                icon: const Icon(Icons.control_point_duplicate, size: 20),
                onPressed: () => canvasCtrl.duplicateSelection(),
                tooltip: 'Duplicate',
                color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              IconButton(
                icon: const Icon(Icons.document_scanner, size: 20),
                onPressed: () => canvasCtrl.performOCR(context),
                tooltip: 'Convert to Text',
                color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Builder(
                builder: (itemCtx) => IconButton(
                  icon: const Icon(LucideIcons.palette, size: 20),
                  onPressed: () {
                    DrawingToolsRow.showPopoverColorPicker(
                      context: itemCtx,
                      currentColor: canvasCtrl.selectedColor,
                      onColorChanged: (c) => canvasCtrl.recolorSelection(c),
                      canvasCtrl: canvasCtrl,
                    );
                  },
                  tooltip: 'Recolor',
                  color: canvasCtrl.isDarkMode ? Colors.white : Colors.black,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
