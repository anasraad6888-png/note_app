import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'models/note_document.dart';
import 'models/canvas_models.dart';
import 'painters/canvas_painters.dart';
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

class _DrawingCanvasState extends State<DrawingCanvas>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AudioController audioCtrl;
  late CanvasController canvasCtrl;
  int _pointerCount = 0;
  bool _hasMultiTouchInCurrentGesture = false;
  bool _isSpacePressed = false;
  bool _isStylusButtonPressed = false;
  bool _isFirstLayout = true;

  /// True while the user is actively drawing on the canvas (pen/finger down in draw mode).
  /// When true, the InteractiveViewer pan is disabled so the canvas never moves while drawing.
  bool _isDrawing = false;

  /// Determines if the current input should explicitly trigger navigation rather than drawing.
  bool get _shouldNavigate {
    return canvasCtrl.isPanZoomMode ||
        _pointerCount > 1 ||
        _hasMultiTouchInCurrentGesture ||
        _isSpacePressed ||
        _isStylusButtonPressed;
  }

  /// Determines if the InteractiveViewer is allowed to pan. 
  /// Enables native trackpad scrolling when not actively drawing.
  bool get _isPanEnabled {
    if (_shouldNavigate) return true;
    return !_isDrawing;
  }

  // --- Spring-back (Bouncing Physics) ---
  // Uses a persistent Ticker that checks every frame if out of bounds.
  // When the canvas is out-of-bounds AND no pointer is down, it springs back immediately.
  late final Ticker _springTicker;
  late final AnimationController _bounceController;
  Animation<Matrix4>? _bounceAnimation;
  bool _isBouncing = false;         // spring back is active
  bool _interacting = false;         // finger/trackpad is touching right now
  int _releaseTimestamp = 0;        // epoch ms when interaction ended

  // --- Pull to Add Page ---
  static const double _kPullThreshold = 120.0; // px past bottom edge to trigger
  late final AnimationController _pullIndicatorController;
  bool _isPullingPastBottom = false;
  bool _isPullReadyToRelease = false; // crossed threshold
  double _pullOverscrollAmount = 0.0; // How far past the bottom edge we've pulled
  bool _pageAddedByPull = false; // prevents double-firing

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() {
        if (_bounceAnimation != null) {
          canvasCtrl.transformationController.value = _bounceAnimation!.value;
        }
      })
    ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _isBouncing = false;
        }
      });

    _pullIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Ticker that runs every frame and triggers spring-back after a short
    // settle delay once the user lifts their finger.
    _springTicker = createTicker((_) {
      if (!_interacting && !_isBouncing) {
        // Wait 150ms after release before springing back — gives the canvas
        // time to coast naturally and avoids instant snapping.
        final int now = DateTime.now().millisecondsSinceEpoch;
        if (now - _releaseTimestamp >= 250) {
          _enforceBoundsIfNeeded();
        }
      }
    });
    _springTicker.start();

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
    _springTicker.dispose();
    _boundsCheckTimer?.cancel();
    _pullIndicatorController.dispose();
    _bounceController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    audioCtrl.dispose();
    canvasCtrl.dispose();
    super.dispose();
  }

  // ── Pull-to-Add-Page helpers ──────────────────────────────────────────────

  /// Called every frame during onInteractionUpdate to measure bottom overscroll.
  void _updatePullState() {
    if (canvasCtrl.viewportSize?.isEmpty ?? true) return;

    final matrix = canvasCtrl.transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final viewportH = canvasCtrl.viewportSize!.height;
    final int pageCount =
        widget.document.pages.isNotEmpty ? widget.document.pages.length : 1;
    final double documentHeight = (16.0 + pageCount * 940.0 + 16.0) * scale;

    // y translation: negative means we've scrolled down
    final double currentY = matrix.getTranslation().y;
    // The max upward scroll before overscrolling bottom
    final double minY = viewportH - documentHeight;

    final double bottomOverscroll = currentY < minY ? (minY - currentY) : 0.0;

    final bool pulling = bottomOverscroll > 1.0;
    final bool ready = bottomOverscroll >= _kPullThreshold;

    // Trigger haptic once when threshold is crossed
    if (ready && !_isPullReadyToRelease) {
      HapticFeedback.mediumImpact();
    }

    if (pulling != _isPullingPastBottom ||
        ready != _isPullReadyToRelease ||
        (bottomOverscroll - _pullOverscrollAmount).abs() > 1.0) {
      setState(() {
        _isPullingPastBottom = pulling;
        _isPullReadyToRelease = ready;
        _pullOverscrollAmount = bottomOverscroll;
        if (pulling) {
          _pageAddedByPull = false; // reset if user starts pulling again
        }
      });
    }
  }

  /// Called by the user releases (onInteractionEnd) while in pull state.
  void _onPullReleased() {
    if (!_isPullingPastBottom) return;
    if (_isPullReadyToRelease && !_pageAddedByPull) {
      _pageAddedByPull = true;
      HapticFeedback.heavyImpact();
      canvasCtrl.addPage();
    }
    // Reset pull state
    setState(() {
      _isPullingPastBottom = false;
      _isPullReadyToRelease = false;
      _pullOverscrollAmount = 0.0;
    });
  }

  // ── Rubber Band Physics ───────────────────────────────────────────────────

  /// Apple's rubber-band formula: converts a raw overscroll distance into
  /// a dampened displacement. The further you pull, the heavier it feels.
  /// `overscroll` = how far past the boundary, `dimension` = viewport height or width.
  double _rubberBandResist(double overscroll, double dimension) {
    if (overscroll <= 0) return 0;
    // f(x) = (1 - (1 / ((x * 0.55 / d) + 1))) * d
    // at x=0 → 0, at x→∞ → d. Derivative at 0 = 0.55 (55% resistance start)
    const double kCoefficient = 0.55;
    return (1.0 - (1.0 / ((overscroll * kCoefficient / dimension) + 1.0))) *
        dimension;
  }

  /// Called every update frame. If the canvas is out of bounds, replace the
  /// raw InteractiveViewer translation with a rubber-banded equivalent so that
  /// the further the user pulls, the heavier it feels.
  void _applyRubberBandFriction() {
    if (canvasCtrl.viewportSize?.isEmpty ?? true) return;

    final matrix = canvasCtrl.transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final viewportW = canvasCtrl.viewportSize!.width;
    final viewportH = canvasCtrl.viewportSize!.height;

    final double documentWidth = 700.0 * scale;
    final int pageCount =
        widget.document.pages.isNotEmpty ? widget.document.pages.length : 1;
    final double documentHeight = (16.0 + pageCount * 940.0 + 16.0) * scale;

    final double currentX = matrix.getTranslation().x;
    final double currentY = matrix.getTranslation().y;

    // Compute the "in-bounds" limits
    double minX, maxX, maxY;
    if (documentWidth < viewportW) {
      final double centeredX = (viewportW - documentWidth) / 2.0;
      minX = maxX = centeredX;
    } else {
      minX = viewportW - documentWidth;
      maxX = 0.0;
    }
    if (documentHeight < viewportH) {
      maxY = (viewportH - documentHeight) / 2.0;
    } else {
      maxY = 0.0;
    }

    double newX = currentX;
    double newY = currentY;
    bool modified = false;

    // X rubber band
    if (currentX > maxX) {
      // Over the right/top edge
      final double raw = currentX - maxX;
      final double dampened = _rubberBandResist(raw, viewportW);
      newX = maxX + dampened;
      modified = true;
    } else if (currentX < minX) {
      final double raw = minX - currentX;
      final double dampened = _rubberBandResist(raw, viewportW);
      newX = minX - dampened;
      modified = true;
    }

    // Y rubber band — top overscroll only.
    // Bottom overscroll (currentY < minY) is intentionally NOT dampened here
    // so that _updatePullState can measure the raw distance for pull-to-add-page.
    if (currentY > maxY) {
      // Past the TOP (first page) — apply full rubber band
      final double raw = currentY - maxY;
      final double dampened = _rubberBandResist(raw, viewportH);
      newY = maxY + dampened;
      modified = true;
    }
    // Note: currentY < minY (bottom) is left untouched — free movement.

    if (modified && ((newX - currentX).abs() > 0.1 || (newY - currentY).abs() > 0.1)) {
      final Matrix4 corrected = matrix.clone()
        ..setTranslationRaw(newX, newY, 0.0);
      canvasCtrl.transformationController.value = corrected;
    }
  }

  // ── Bounds helpers ────────────────────────────────────────────────────────

  /// Computes the target (clamped) translation for the current matrix.
  /// Returns null if already within bounds (no correction needed).
  ({double x, double y})? _computeTargetTranslation() {
    if (canvasCtrl.viewportSize?.isEmpty ?? true) return null;

    final matrix = canvasCtrl.transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final viewportW = canvasCtrl.viewportSize!.width;
    final viewportH = canvasCtrl.viewportSize!.height;

    final double documentWidth = 700.0 * scale;
    final int pageCount =
        widget.document.pages.isNotEmpty ? widget.document.pages.length : 1;
    final double documentHeight = (16.0 + pageCount * 940.0 + 16.0) * scale;

    final double currentX = matrix.getTranslation().x;
    final double currentY = matrix.getTranslation().y;

    double targetX;
    double targetY;

    // Horizontal
    if (documentWidth < viewportW) {
      targetX = (viewportW - documentWidth) / 2.0;
    } else {
      targetX = currentX.clamp(viewportW - documentWidth, 0.0);
    }

    // Vertical
    if (documentHeight < viewportH) {
      targetY = (viewportH - documentHeight) / 2.0;
    } else {
      targetY = currentY.clamp(viewportH - documentHeight, 0.0);
    }

    if ((targetX - currentX).abs() < 0.5 && (targetY - currentY).abs() < 0.5) {
      return null; // already in bounds
    }

    return (x: targetX, y: targetY);
  }

  /// Called every frame by _springTicker when not interacting and not bouncing.
  /// Starts the spring-back animation the moment the user lifts their finger.
  void _enforceBoundsIfNeeded() {
    if (!mounted) return;
    final target = _computeTargetTranslation();
    if (target == null) return; // in bounds — nothing to do

    final matrix = canvasCtrl.transformationController.value;
    final Matrix4 targetMatrix = matrix.clone()
      ..setTranslationRaw(target.x, target.y, 0.0);

    _isBouncing = true;
    _bounceAnimation = Matrix4Tween(
      begin: matrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOutCubic,
    ));
    _bounceController.forward(from: 0.0);
  }

  /// Instant (no animation) snap — only for the very first layout frame.
  void _enforceBounds({bool animate = false}) {
    final target = _computeTargetTranslation();
    if (target == null) return;

    final matrix = canvasCtrl.transformationController.value;
    final Matrix4 targetMatrix = matrix.clone()
      ..setTranslationRaw(target.x, target.y, 0.0);

    if (animate) {
      _isBouncing = true;
      _bounceAnimation = Matrix4Tween(begin: matrix, end: targetMatrix).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic),
      );
      _bounceController.forward(from: 0.0);
    } else {
      canvasCtrl.transformationController.value = targetMatrix;
    }
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

  Timer? _boundsCheckTimer;

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
    
    canvasCtrl.transformationController.removeListener(_onCanvasTransformChanged);
    canvasCtrl.transformationController.addListener(_onCanvasTransformChanged);

    setState(() {});
  }

  // No longer needed — replaced by _springTicker + _enforceBoundsIfNeeded
  void _onCanvasTransformChanged() {}

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
                if (_pointerCount > 1) {
                  _hasMultiTouchInCurrentGesture = true;
                  canvasCtrl.setMultiTouchPan(true);
                }
              },
              onPointerUp: (e) {
                setState(() {
                  _pointerCount--;
                  _isStylusButtonPressed = false;
                  if (_pointerCount == 0) {
                    _hasMultiTouchInCurrentGesture = false;
                  }
                });
                if (_pointerCount <= 1 && !_hasMultiTouchInCurrentGesture) {
                  canvasCtrl.setMultiTouchPan(false);
                } else if (_pointerCount == 0) {
                  canvasCtrl.setMultiTouchPan(false);
                }
              },
              onPointerCancel: (e) {
                setState(() {
                  _pointerCount--;
                  _isStylusButtonPressed = false;
                  if (_pointerCount == 0) {
                    _hasMultiTouchInCurrentGesture = false;
                  }
                });
                if (_pointerCount <= 1 && !_hasMultiTouchInCurrentGesture) {
                  canvasCtrl.setMultiTouchPan(false);
                } else if (_pointerCount == 0) {
                  canvasCtrl.setMultiTouchPan(false);
                }
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

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                canvasCtrl.viewportSize = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );

                                final int pageCount =
                                    widget.document.pages.isNotEmpty ? widget.document.pages.length : 1;
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

                                if (_isFirstLayout) {
                                  _isFirstLayout = false;
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) _enforceBounds(animate: false);
                                  });
                                }

                                final bool pageWiderThanViewport = 700.0 * scale >= constraints.maxWidth;
                                final PanAxis effectivePanAxis =
                                    pageWiderThanViewport ? PanAxis.free : PanAxis.vertical;

                                return Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: InteractiveViewer(
                                    transformationController:
                                        canvasCtrl.transformationController,
                                    onInteractionStart: (details) {
                                      _interacting = true;
                                      _isBouncing = false;
                                      _bounceController.stop();
                                    },
                                    onInteractionUpdate: (details) {
                                      _applyRubberBandFriction();
                                      _updatePullState();
                                    },
                                    onInteractionEnd: (details) {
                                      _interacting = false;
                                      _releaseTimestamp = DateTime.now().millisecondsSinceEpoch;
                                      _onPullReleased();
                                      // Spring-back is handled by _springTicker next frame
                                    },
                                    minScale: computedMin,
                                    maxScale: 20.0,
                                    alignment: null,
                                    boundaryMargin: const EdgeInsets.all(150.0), // Allow 150px spring beyond edges before snapping back
                                    panEnabled: _isPanEnabled,
                                    panAxis: effectivePanAxis,
                                    scaleEnabled: true,
                                    constrained: false,
                                    child: Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: SizedBox(
                                        width: 700,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListView.builder(
                                              // InteractiveViewer (constrained:false) handles all
                                              // pan/scroll gestures — disable ListView scrolling
                                              // to prevent gesture conflicts.
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
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
                                            // ── Pull-to-Add indicator ──
                                            _PullToAddIndicator(
                                              overscroll: _pullOverscrollAmount,
                                              threshold: _kPullThreshold,
                                              isReadyToRelease: _isPullReadyToRelease,
                                              isDarkMode: canvasCtrl.isDarkMode,
                                            ),
                                          ],
                                        ),
                                      ),
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
                        Positioned(
                          left: 0,
                          top: 0,
                          child: CompositedTransformFollower(
                            link: audioCtrl.audioWindowLink,
                            targetAnchor: Alignment.bottomCenter,
                            followerAnchor: Alignment.topCenter,
                            offset: const Offset(0, 8),
                            child: AudioPlayerWindow(
                              audioCtrl: audioCtrl,
                              isDarkMode: canvasCtrl.isDarkMode,
                            ),
                          ),
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
            color: canvasCtrl.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: canvasCtrl.isDarkMode
                    ? Colors.white.withAlpha(5)
                    : Colors.black.withAlpha(15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: canvasCtrl.isDarkMode
                ? Border.all(color: Colors.white12, width: 0.5)
                : Border.all(color: Colors.black.withAlpha(10), width: 0.5),
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
        // Because the inner Listener receives onPointerDown BEFORE the outer Listener,
        // _pointerCount here does NOT yet include the newly placed finger.
        // Therefore, if _pointerCount > 0, we already have another finger on the screen!
        if (_pointerCount > 0 || _hasMultiTouchInCurrentGesture) {
          canvasCtrl.cancelCurrentStroke(index);
          return;
        }
        if (_shouldNavigate) return;
        if (canvasCtrl.penPalmRejection && event.radiusMajor > 20.0) return;

        setState(() {
          _isDrawing = true;
        });

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
          if (!isHit) canvasCtrl.startText(index, event.localPosition);
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
        if (_pointerCount > 1 || _hasMultiTouchInCurrentGesture) {
          canvasCtrl.cancelCurrentStroke(index);
          return;
        }
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
        } else if (canvasCtrl.isTextMode) {
          canvasCtrl.updateText(index, event.localPosition);
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
        if (_pointerCount > 1 || _hasMultiTouchInCurrentGesture) {
          canvasCtrl.cancelCurrentStroke(index);
          return;
        }
        if (_shouldNavigate) return;
        if (canvasCtrl.penPalmRejection && event.radiusMajor > 20.0) return;

        setState(() {
          _isDrawing = false;
        });

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
        } else if (canvasCtrl.isTextMode) {
          canvasCtrl.endText(index);
        } else if (!canvasCtrl.isTextMode) {
          canvasCtrl.penHoldTimer?.cancel();
          canvasCtrl.isPenHoldTriggered = false;
          canvasCtrl.addPoint(index, null);
        }
      },
      onPointerCancel: (event) {
        if (_isDrawing) {
          setState(() {
            _isDrawing = false;
          });
          canvasCtrl.cancelCurrentStroke(index);
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
        // ── Text box drag preview ─────────────────────────────────────
        if (!isReadOnly &&
            canvasCtrl.isTextMode &&
            canvasCtrl.currentPageIndex == index &&
            canvasCtrl.currentDrawingTextRect != null)
          Positioned.fill(
            child: CustomPaint(
              painter: _TextBoxPreviewPainter(
                rect: canvasCtrl.currentDrawingTextRect!,
                accentColor: const Color(0xFFFF7F6A),
              ),
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
                    showPopoverColorPicker(
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

// ─────────────────────────────────────────────────────────────────────────────
// Pull-to-Add-Page indicator widget
// Sits below the last page inside the InteractiveViewer content.
// Shows as the user drags past the bottom boundary.
// ─────────────────────────────────────────────────────────────────────────────
class _PullToAddIndicator extends StatelessWidget {
  final double overscroll;
  final double threshold;
  final bool isReadyToRelease;
  final bool isDarkMode;

  const _PullToAddIndicator({
    required this.overscroll,
    required this.threshold,
    required this.isReadyToRelease,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (overscroll <= 0) return const SizedBox.shrink();

    final double progress = (overscroll / threshold).clamp(0.0, 1.0);

    // Colors
    final Color accentColor = isReadyToRelease
        ? const Color(0xFF34C759) // Apple green when ready
        : const Color(0xFF5E4AE3); // Indigo violet while pulling
    final Color bgColor = isDarkMode
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);
    final Color textColor = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.6);

    // The pill height grows with pull distance, capped at 80
    final double height = (progress * 80.0).clamp(0.0, 80.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: 700,
      height: height,
      child: height < 8
          ? const SizedBox.shrink()
          : Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: accentColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Icon(
                        isReadyToRelease
                            ? LucideIcons.check   // simple ✓ not a circle
                            : LucideIcons.arrowDown,
                        key: ValueKey(isReadyToRelease),
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        isReadyToRelease ? 'أفلت لإضافة صفحة' : 'اسحب لإضافة صفحة',
                        key: ValueKey(isReadyToRelease),
                        style: TextStyle(
                          fontFamily: 'SF Pro Text',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          letterSpacing: 0.2,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    // Progress arc — collapses entirely when threshold reached
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: isReadyToRelease
                          ? const SizedBox.shrink()
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 2.0,
                                    backgroundColor:
                                        accentColor.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        accentColor),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Draws a live dashed-border rectangle preview while the user drags to
/// define the size of a new text box.
class _TextBoxPreviewPainter extends CustomPainter {
  final Rect rect;
  final Color accentColor;

  const _TextBoxPreviewPainter({required this.rect, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final normalizedRect = Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.left > rect.right ? rect.left : rect.right,
      rect.top > rect.bottom ? rect.top : rect.bottom,
    );

    if (normalizedRect.width < 4 && normalizedRect.height < 4) return;

    // Fill
    canvas.drawRect(
      normalizedRect,
      Paint()..color = accentColor.withAlpha(18),
    );

    // Dashed border
    final Paint borderPaint = Paint()
      ..color = accentColor.withAlpha(200)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashLen = 8;
    const double gapLen = 5;

    void drawDashedLine(Offset start, Offset end) {
      final double dx = end.dx - start.dx;
      final double dy = end.dy - start.dy;
      final double length = (Offset(dx, dy)).distance;
      final double stepLen = dashLen + gapLen;
      double drawn = 0;
      while (drawn < length) {
        final double t1 = drawn / length;
        final double t2 = ((drawn + dashLen) / length).clamp(0.0, 1.0);
        canvas.drawLine(
          Offset(start.dx + dx * t1, start.dy + dy * t1),
          Offset(start.dx + dx * t2, start.dy + dy * t2),
          borderPaint,
        );
        drawn += stepLen;
      }
    }

    drawDashedLine(normalizedRect.topLeft, normalizedRect.topRight);
    drawDashedLine(normalizedRect.topRight, normalizedRect.bottomRight);
    drawDashedLine(normalizedRect.bottomRight, normalizedRect.bottomLeft);
    drawDashedLine(normalizedRect.bottomLeft, normalizedRect.topLeft);

    // Corner handles
    final Paint handlePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    for (final corner in [
      normalizedRect.topLeft,
      normalizedRect.topRight,
      normalizedRect.bottomLeft,
      normalizedRect.bottomRight,
    ]) {
      canvas.drawCircle(corner, 4, handlePaint);
    }

    // Size label
    if (normalizedRect.width > 40 && normalizedRect.height > 20) {
      final label =
          '${normalizedRect.width.round()} × ${normalizedRect.height.round()}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: accentColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          normalizedRect.left + 6,
          normalizedRect.top + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_TextBoxPreviewPainter old) =>
      old.rect != rect || old.accentColor != accentColor;
}
