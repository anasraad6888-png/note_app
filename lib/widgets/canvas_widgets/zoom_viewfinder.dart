import 'dart:io';
import 'package:flutter/material.dart';
import '../../painters/canvas_painters.dart';
import '../../controllers/canvas_controller.dart';
import '../interactive_text_widget.dart';

// 1. الإطار الأزرق (يوضع داخل الصفحة ليلتصق بها ويقرأ إحداثياتها بدقة)
class ZoomTargetBox extends StatelessWidget {
  final CanvasController canvasCtrl;
  final int pageIndex;

  const ZoomTargetBox({super.key, required this.canvasCtrl, required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    if (!canvasCtrl.isZoomWindowVisible || canvasCtrl.currentPageIndex != pageIndex) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: canvasCtrl.zoomTargetRect.left - 10,
      top: canvasCtrl.zoomTargetRect.top - 10,
      width: canvasCtrl.zoomTargetRect.width + 20,
      height: canvasCtrl.zoomTargetRect.height + 20,
      child: Stack(
        children: [
          Positioned(
            left: 10, top: 10,
            width: canvasCtrl.zoomTargetRect.width,
            height: canvasCtrl.zoomTargetRect.height,
            child: GestureDetector(
              onPanUpdate: (details) {
                canvasCtrl.updateZoomTargetRect(canvasCtrl.zoomTargetRect.shift(details.delta));
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: canvasCtrl.isDarkMode ? Colors.amber : const Color(0xFFFF7F6A), width: 2),
                  color: canvasCtrl.isDarkMode ? Colors.amber.withAlpha(30) : const Color(0xFFFF7F6A).withAlpha(30),
                ),
                child: Center(
                  child: Icon(Icons.open_with, color: canvasCtrl.isDarkMode ? Colors.amber : const Color(0xFFFF7F6A), size: 20),
                ),
              ),
            ),
          ),
          // مقابض الزوايا للتحكم بالحجم (يحافظ على النسبة والتناسب)
          _buildZoomHandle(top: 0, left: 0, onPanUpdate: (d) => _handleZoomResize(d, context, left: true)),
          _buildZoomHandle(top: 0, right: 0, onPanUpdate: (d) => _handleZoomResize(d, context, right: true)),
          _buildZoomHandle(bottom: 0, left: 0, onPanUpdate: (d) => _handleZoomResize(d, context, left: true)),
          _buildZoomHandle(bottom: 0, right: 0, onPanUpdate: (d) => _handleZoomResize(d, context, right: true)),
        ],
      ),
    );
  }

  Widget _buildZoomHandle({double? top, double? bottom, double? left, double? right, required Function(DragUpdateDetails) onPanUpdate}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        child: Container(
          width: 30, height: 30, color: Colors.transparent,
          child: Center(
            child: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: canvasCtrl.isDarkMode ? Colors.amber : const Color(0xFFFF7F6A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleZoomResize(DragUpdateDetails details, BuildContext context, {bool left = false, bool right = false}) {
    double screenWidth = MediaQuery.of(context).size.width;
    double aspectRatio = 220.0 / screenWidth; // نسبة ارتفاع النافذة إلى عرض الشاشة (Locked Aspect Ratio)

    double newLeft = canvasCtrl.zoomTargetRect.left;
    double newTop = canvasCtrl.zoomTargetRect.top;
    double newWidth = canvasCtrl.zoomTargetRect.width;

    if (left) {
      double diff = details.delta.dx;
      if (newWidth - diff > 100) {
        newLeft += diff;
        newWidth -= diff;
      }
    }
    if (right) {
      newWidth = (newWidth + details.delta.dx).clamp(100.0, 700.0);
    }

    // إجبار الطول على التوافق التام مع نسبة التكبير لكي لا تخرج الحدود أبداً!
    double newHeight = newWidth * aspectRatio;
    canvasCtrl.updateZoomTargetRect(Rect.fromLTWH(newLeft, newTop, newWidth, newHeight));
  }
}

// 2. النافذة السفلية (توضع في الشاشة الرئيسية)
class ZoomBottomWindow extends StatelessWidget {
  final CanvasController canvasCtrl;

  const ZoomBottomWindow({super.key, required this.canvasCtrl});

  @override
  Widget build(BuildContext context) {
    if (!canvasCtrl.isZoomWindowVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: 0, 
      left: 0, right: 0, height: 220,
      child: Container(
        decoration: BoxDecoration(
          color: canvasCtrl.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          boxShadow: [BoxShadow(color: canvasCtrl.isDarkMode ? Colors.black45 : Colors.black26, blurRadius: 10, offset: const Offset(0, -2))],
          border: Border(top: BorderSide(color: canvasCtrl.isDarkMode ? Colors.amber : const Color(0xFFFF7F6A), width: 3)),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
             if (!canvasCtrl.isZoomWindowVisible) return;
             double expectedHeight = canvasCtrl.zoomTargetRect.width * (constraints.maxHeight / constraints.maxWidth);
             if ((canvasCtrl.zoomTargetRect.height - expectedHeight).abs() > 1.0) {
                canvasCtrl.updateZoomTargetRect(Rect.fromLTWH(
                    canvasCtrl.zoomTargetRect.left,
                    canvasCtrl.zoomTargetRect.top,
                    canvasCtrl.zoomTargetRect.width,
                    expectedHeight
                ));
             }
          });

          return Stack(
            children: [
              CustomPaint(size: Size.infinite, painter: ZoomBackgroundPainter(isDarkMode: canvasCtrl.isDarkMode)),
              ClipRect(
                child: Transform(
                  transform: Matrix4.identity()
                    ..scale(constraints.maxWidth / canvasCtrl.zoomTargetRect.width)
                    ..translate(-canvasCtrl.zoomTargetRect.left, -canvasCtrl.zoomTargetRect.top),
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 4000,
                      height: 4000,
                      child: Stack(
                        children: [
                          // Shapes
                          CustomPaint(
                            size: const Size(4000, 4000),
                            painter: ShapePainter(
                              canvasCtrl.getSyncedShapes(canvasCtrl.currentPageIndex),
                              null,
                              canvasCtrl.pageTemplates[canvasCtrl.currentPageIndex],
                              isDarkMode: canvasCtrl.isDarkMode,
                              version: canvasCtrl.contentVersion,
                            ),
                          ),
                          // Tables
                          CustomPaint(
                            size: const Size(4000, 4000),
                            painter: TablePainter(
                              tables: canvasCtrl.getSyncedTables(canvasCtrl.currentPageIndex),
                              currentTable: null,
                            ),
                          ),
                          // Images and Texts (which don't have native painters)
                          ...canvasCtrl.getSyncedImages(canvasCtrl.currentPageIndex).map(
                                (img) => Positioned(
                                  key: ValueKey('zoom_img_${img.path}'),
                                  left: img.offset.dx,
                                  top: img.offset.dy,
                                  child: SizedBox(
                                    width: img.size.width,
                                    height: img.size.height,
                                    child: File(img.path).existsSync()
                                        ? Image.file(
                                            File(img.path),
                                            width: img.size.width,
                                            height: img.size.height,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, _, _) => canvasCtrl.missingImagePlaceholder(img),
                                          )
                                        : canvasCtrl.missingImagePlaceholder(img),
                                  ),
                                ),
                              ),
                          ...canvasCtrl.getSyncedTexts(canvasCtrl.currentPageIndex).map(
                                (txt) => InteractiveTextWidget(
                                  key: ValueKey('zoom_text_${txt.id}'),
                                  textData: txt,
                                  isDarkMode: canvasCtrl.isDarkMode,
                                  onSave: canvasCtrl.saveStrokes,
                                  readOnly: true,
                                  onDelete: () {},
                                  canvasCtrl: canvasCtrl,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              CustomPaint(
                size: Size.infinite,
                painter: ZoomWindowPainter(
                  canvasCtrl.audioCtrl.isPlaying || canvasCtrl.audioCtrl.isRecording 
                      ? canvasCtrl.getSyncedPoints(canvasCtrl.currentPageIndex)
                      : canvasCtrl.pagesPoints[canvasCtrl.currentPageIndex],
                  canvasCtrl.zoomTargetRect,
                  isDarkMode: canvasCtrl.isDarkMode
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  canvasCtrl.addZoomPoint(details.localPosition, constraints.biggest);
                  canvasCtrl.notifyListeners();
                },
                onPanUpdate: (details) {
                  canvasCtrl.addZoomPoint(details.localPosition, constraints.biggest);
                  canvasCtrl.notifyListeners();
                },
                onPanEnd: (_) {
                  canvasCtrl.pagesPoints[canvasCtrl.currentPageIndex].add(null);
                  canvasCtrl.saveStrokes();
                  canvasCtrl.notifyListeners();
                },
                child: const SizedBox.expand(),
              ),
              Positioned(
                left: 10, top: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: canvasCtrl.isDarkMode ? Colors.black.withAlpha(150) : Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: canvasCtrl.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300)
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.arrow_back, color: canvasCtrl.isDarkMode ? Colors.white70 : Colors.black87), tooltip: 'تقدم (لليسار)', onPressed: () => canvasCtrl.updateZoomTargetRect(canvasCtrl.zoomTargetRect.translate(-canvasCtrl.zoomTargetRect.width * 0.6, 0))),
                      IconButton(icon: Icon(Icons.arrow_forward, color: canvasCtrl.isDarkMode ? Colors.white70 : Colors.black87), tooltip: 'تراجع (لليمين)', onPressed: () => canvasCtrl.updateZoomTargetRect(canvasCtrl.zoomTargetRect.translate(canvasCtrl.zoomTargetRect.width * 0.6, 0))),
                      IconButton(icon: Icon(Icons.keyboard_return, color: canvasCtrl.isDarkMode ? Colors.white70 : Colors.black87), tooltip: 'سطر جديد', onPressed: () => canvasCtrl.updateZoomTargetRect(Rect.fromLTWH(700 - canvasCtrl.zoomTargetRect.width - 20, canvasCtrl.zoomTargetRect.top + canvasCtrl.zoomTargetRect.height, canvasCtrl.zoomTargetRect.width, canvasCtrl.zoomTargetRect.height))),
                      IconButton(icon: const Icon(Icons.close, color: Colors.red), tooltip: 'إغلاق', onPressed: () => canvasCtrl.toggleZoomWindow()),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
