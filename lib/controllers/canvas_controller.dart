import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:ui' as ui;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../models/note_document.dart';
import '../models/canvas_models.dart';
import '../painters/canvas_painters.dart';
import '../utils/shape_recognizer.dart';
import 'audio_controller.dart';

part 'canvas/tools_logic.dart';
part 'canvas/objects_logic.dart';
part 'canvas/io_logic.dart';
part 'canvas/drawing_logic.dart';

class CanvasController extends ChangeNotifier {
  int contentVersion = 0;
  void notifyContentChanged() {
    contentVersion++;
    notifyListeners();
  }
  final NoteDocument document;
  final AudioController audioCtrl;
  final Function(NoteDocument) onSave;
  final void Function(String message, {bool isError})? showMessage;
  final Widget Function(int)? buildPageForExport;

  // --- State Variables ---
  final GlobalKey canvasRepaintKey = GlobalKey();
  List<List<DrawingPoint?>> pagesPoints = [];
  List<List<DrawingPoint?>> redoPagesPoints = [];
  List<List<PageImage>> pagesImages = [];
  List<List<PageText>> pagesTexts = [];
  List<List<PageShape>> pagesShapes = [];
  List<List<PageTable>> pagesTables = [];
  List<List<LaserStroke>> activeLaserStrokes = [];
  Timer? _laserTimer;
  Timer? _thumbnailTimer; // مؤقت التقاط المصغرات
  List<ScreenshotController> pagesScreenshotControllers = [];
  List<bool> pagesBookmarks = [];
  List<String?> pagesOutlines = [];
  List<int?> pdfPageMapping = [];
  List<Uint8List?> pageThumbnails = [];

  int _currentPageIndex = 0;
  bool isTextMode = false;
  bool isLassoMode = false;
  bool isLaserMode = false;
  bool isPanZoomMode = false;
  bool isZoomSliderVisible = false;
  bool isRulerVisible = false;
  ToolbarPosition toolbarPosition = ToolbarPosition.bottom;
  bool isDarkMode;
  VoidCallback? onDarkModeToggle;
  VoidCallback? onShowPagesGridDialog;
  VoidCallback? onDocumentClose;
  Function(int)? onShowCustomColorPicker;

  // Global Text Editor State
  PageText? activeEditingText;
  quill.QuillController? activeQuillController;
  VoidCallback? toggleTextInspector;

  void startEditingText(PageText text, quill.QuillController controller, {VoidCallback? toggleInspector}) {
    activeEditingText = text;
    activeQuillController = controller;
    toggleTextInspector = toggleInspector;
    notifyListeners();
  }

  void stopEditingText() {
    activeEditingText?.isEditing = false;
    activeEditingText = null;
    activeQuillController = null;
    toggleTextInspector = null;
    notifyListeners();
  }

  void forceTextFocusReclamation() {
    notifyListeners();
  }

  final ScreenshotController screenshotController = ScreenshotController();
  Offset rulerPosition = const Offset(350, 450);
  double rulerAngle = 0.0;
  // Ruler cursor: position of pen on ruler edge while drawing (ruler-local X, and edge: -1=top, 0=none, 1=bottom)
  double? rulerCursorLocalX;
  int rulerCursorEdge = 0; // -1 = top, 0 = none, +1 = bottom
  // Stroke length tracking (non-null while actively drawing near the ruler)
  double? activeStrokeLength;
  Offset? _rulerLastSnappedPoint; // last snapped canvas point in this stroke

  final TransformationController transformationController =
      TransformationController();
  final ScrollController scrollController = ScrollController();
  List<PageTemplate> pageTemplates = [];

  // Pen settings
  PenType currentPenType = PenType.ball;
  bool holdToDrawShape = false;
  bool scribbleToErase = false;
  double pressureSensitivity = 3.0;
  double stabilization = 0.0;
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;
  List<double> strokeWidthPresets = [2.0, 5.0, 10.0];
  int activeStrokeWidthIndex = 1;
  LineType currentLineType = LineType.solid;

  // Advanced Pen Settings
  bool showAdvancedPenSettings = false;
  double penOpacity = 1.0;
  double penSmoothing = 0.5;
  bool penAutoFill = false;
  bool penPalmRejection = false;
  bool penPressureSensitivity = true;
  Offset advancedPenSettingsPosition = const Offset(-1, -1);

  // Highlighter settings
  bool isHighlighterMode = false;
  bool isEraserMode = false;
  bool eraseEntireObject = false;
  bool showEraserSettingsRow = false;
  Set<String> eraseFilters = {'pen', 'highlighter', 'shapes', 'images', 'texts', 'tables'};
  List<double> eraserWidthPresets = [10.0, 20.0, 40.0];
  int activeEraserWidthIndex = 1;

  double get eraserWidth => eraserWidthPresets[activeEraserWidthIndex];
  StraightLineMode highlighterLineMode = StraightLineMode.holdToDraw;
  StrokeCap highlighterTip = StrokeCap.round;
  double highlighterThickness = 40.0;
  double highlighterOpacity = 0.4;
  Color highlighterColor = Colors.yellow;

  // Shapes settings
  bool isShapeMode = false;
  PageShape? currentDrawingShape;
  String selectedShapeType = 'rectangle';
  double shapeBorderWidth = 5.0;
  Color shapeBorderColor = Colors.red;
  Color shapeFillColor = Colors.transparent;
  int shapeLineType = 0;
  Offset? shapeStartPoint;

  // Tables settings
  bool isTableMode = false;
  int tableRows = 3;
  int tableCols = 3;
  bool tableHeaderRow = true;
  bool tableHeaderCol = false;
  double tableBorderWidth = 2.0;
  Color tableBorderColor = Colors.grey;
  Color tableFillColor = Colors.transparent;
  PageTable? currentDrawingTable;
  Offset? tableStartPoint;

  // Refactored fields returned to main class:
  Offset? shapeStartPos;
  Offset? tableStartPos;
  bool isAudioBarVisible = false;

  void jumpToPage(int index) {
    if (index < 0 || index >= document.pages.length) return;
    
    currentPageIndex = index;
    
    // Calculate the scroll position
    // ListView padding top: 140, page padding vertical: 20*2=40, page height: 900
    double scrollPosition = 140.0 + (index * 940.0);
    
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    
    // notifyListeners() is called by the currentPageIndex setter
  }

  // Pen Auto-Shapes internal state
  Timer? penHoldTimer;
  bool isPenHoldTriggered = false;

  // Highlighter internal drawing state
  bool _isDisposed = false;
  Offset? hlStartPoint;
  Timer? highlighterHoldTimer;
  bool isHighlighterHoldTriggered = false;
  int? highlighterStrokeStartIndex;
  Offset? highlighterDragStartPoint;

  Map<int, List<Rect>> pdfTextBounds = {};
  int? _currentlyExtractingPage;

  List<Offset>? lassoPath;
  CanvasSelectionGroup? activeSelectionGroup;
  CanvasSelectionGroup? clipboardGroup;
  bool showLassoSettingsRow = false;

  // Lasso Filters
  bool lassoSelectHandwriting = true;
  bool lassoSelectHighlighter = true;
  bool lassoSelectImages = true;
  bool lassoSelectTexts = true;
  bool lassoSelectShapes = true;
  bool lassoSelectTables = true;

  void copySelection() {
    if (activeSelectionGroup != null) {
      clipboardGroup = activeSelectionGroup!.clone();
      showMessage?.call("تم نسخ العناصر");
    }
  }

  void cutSelection() {
    if (activeSelectionGroup != null) {
      clipboardGroup = activeSelectionGroup!.clone();
      deleteSelection();
      showMessage?.call("تم قص العناصر");
    }
  }

  void pasteClipboard(int pageIndex, Offset position) {
    if (clipboardGroup == null) return;
    saveStrokes(); // For undo
    
    final clone = clipboardGroup!.clone();
    clone.pageIndex = pageIndex;
    
    final rect = clone.initialBoundingBox;
    if (rect != null) {
       final offset = position - rect.center;
       clone.currentTranslation += offset;
    }
    
    if (activeSelectionGroup != null) commitSelection();
    activeSelectionGroup = clone;
    
    disableAllTools();
    isLassoMode = true;
    showLassoSettingsRow = true;
    
    notifyContentChanged();
  }

  void duplicateSelection() {
    if (activeSelectionGroup == null) return;
    
    final clone = activeSelectionGroup!.clone();
    commitSelection(); // Bake the original elements natively into the page
    
    clone.currentTranslation += const Offset(20, 20); // Append slight interaction offset
    activeSelectionGroup = clone;
    
    notifyContentChanged();
  }

  void recolorSelection(Color color) {
    if (activeSelectionGroup == null) return;
    final group = activeSelectionGroup!;
    
    final newStrokes = <DrawingPoint?>[];
    for (var p in group.strokes) {
      if (p == null) {
        newStrokes.add(null);
      } else {
        final newPaint = Paint()
          ..color = color
          ..strokeWidth = p.paint.strokeWidth
          ..strokeCap = p.paint.strokeCap
          ..strokeJoin = p.paint.strokeJoin
          ..style = p.paint.style
          ..blendMode = p.paint.blendMode;
        newStrokes.add(DrawingPoint(p.offset, newPaint, pressure: p.pressure, penType: p.penType, timestamp: p.timestamp, audioIndex: p.audioIndex));
      }
    }
    group.strokes = newStrokes;
    
    for (var shape in group.shapes) {
      shape.borderColor = color;
    }
    for (var text in group.texts) {
      text.color = color;
    }
    for (var table in group.tables) {
       table.borderColor = color;
    }
    
    notifyContentChanged();
  }

  Future<void> extractTextForPage(int pageIndex) async {
    if (pdfDocument == null) return;
    if (pdfTextBounds.containsKey(pageIndex)) return;
    if (_currentlyExtractingPage == pageIndex) return;

    _currentlyExtractingPage = pageIndex;
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      final doc = pdfDocument!;
      if (pageIndex >= doc.pagesCount) return;

      final page = await doc.getPage(pageIndex + 1);
      final scale = 700 / page.width;
      final renderW = page.width * scale * 2;
      final renderH = page.height * scale * 2;
      final image = await page.render(width: renderW, height: renderH, format: PdfPageImageFormat.jpeg, quality: 90);
      await page.close();
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/pdf_temp_ocr_$pageIndex.jpg');
      await tempFile.writeAsBytes(image!.bytes);
      
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      List<Rect> boxes = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
           final rect = line.boundingBox;
           boxes.add(Rect.fromLTRB(rect.left / 2, rect.top / 2, rect.right / 2, rect.bottom / 2));
        }
      }
      
      pdfTextBounds[pageIndex] = boxes;
      tempFile.deleteSync();
    } catch (e) {
      debugPrint("OCR extraction failed for page $pageIndex: $e");
    } finally {
      if (_currentlyExtractingPage == pageIndex) _currentlyExtractingPage = null;
      await textRecognizer.close();
      notifyListeners();
    }
  }

  Future<void> performOCR(BuildContext context) async {
    if (activeSelectionGroup == null || activeSelectionGroup!.strokes.isEmpty) {
      showMessage?.call("لا يوجد حبر مكتوب بالتحديد لقراءته!");
      return;
    }

    try {
      final group = activeSelectionGroup!;
      final bounds = group.initialBoundingBox!;
      final width = bounds.width;
      final height = bounds.height;
      if (width <= 0 || height <= 0) return;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
      
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);
      canvas.translate(-bounds.left, -bounds.top);
      
      final painter = DrawingPainter(group.strokes, pageTemplates[currentPageIndex], isDarkMode: false, version: contentVersion);
      painter.paint(canvas, Size(bounds.right, bounds.bottom));

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      final inputImage = InputImage.fromFilePath(file.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final text = recognizedText.text.trim();
      file.deleteSync();

      if (text.isEmpty) {
        showMessage?.call("لم يتم التعرف على أية نصوص.");
        return;
      }

      final pageIndex = group.pageIndex;
      final txtData = PageText(
        id: UniqueKey().toString(),
        text: text,
        rect: Rect.fromLTWH(bounds.left, bounds.bottom + 10, math.max(200, bounds.width), math.max(60, bounds.height)),
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: 24.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      
      pagesTexts[pageIndex].add(txtData);
      saveStrokes();
      notifyListeners();
      showMessage?.call("تم تحويل النص بنجاح!");

    } catch (e) {
      showMessage?.call("خطأ أثناء قراءة النص: $e", isError: true);
    }
  }

  void translateSelection(Offset delta) {
    if (activeSelectionGroup == null) return;
    activeSelectionGroup!.currentTranslation += delta;
    notifyContentChanged();
  }

  void scaleSelection(double scaleFactor) {
    if (activeSelectionGroup == null) return;
    activeSelectionGroup!.currentScale *= scaleFactor;
    notifyContentChanged();
  }

  void rotateSelection(double angleDelta) {
    if (activeSelectionGroup == null) return;
    activeSelectionGroup!.currentRotation += angleDelta;
    notifyContentChanged();
  }

  void commitSelection() {
    if (activeSelectionGroup == null) return;
    final group = activeSelectionGroup!;
    
    final double tx = group.currentTranslation.dx;
    final double ty = group.currentTranslation.dy;
    final double scale = group.currentScale;
    final double rot = group.currentRotation;
    final Offset center = group.initialBoundingBox?.center ?? Offset.zero;

    Offset applyTransform(Offset pt) {
      double dx = pt.dx - center.dx;
      double dy = pt.dy - center.dy;
      dx *= scale;
      dy *= scale;
      if (rot != 0) {
        final rdx = dx * math.cos(rot) - dy * math.sin(rot);
        final rdy = dx * math.sin(rot) + dy * math.cos(rot);
        dx = rdx;
        dy = rdy;
      }
      return Offset(center.dx + dx + tx, center.dy + dy + ty);
    }

    final bakedStrokes = group.strokes.map((stroke) {
      if (stroke == null) return null;
      final newPaint = Paint()
        ..color = stroke.paint.color
        ..strokeWidth = math.max(0.1, stroke.paint.strokeWidth * scale)
        ..strokeCap = stroke.paint.strokeCap
        ..strokeJoin = stroke.paint.strokeJoin
        ..style = stroke.paint.style;
      return DrawingPoint(
        applyTransform(stroke.offset),
        newPaint,
        pressure: stroke.pressure,
        penType: stroke.penType,
        timestamp: stroke.timestamp,
        audioIndex: stroke.audioIndex,
      );
    }).toList();

    for (var img in group.images) {
      final imgCenter = Rect.fromLTWH(img.offset.dx, img.offset.dy, img.size.width, img.size.height).center;
      final newCenter = applyTransform(imgCenter);
      img.size = Size(img.size.width * scale, img.size.height * scale);
      img.offset = Offset(newCenter.dx - img.size.width / 2, newCenter.dy - img.size.height / 2);
    }
    
    for (var txt in group.texts) {
      final newCenter = applyTransform(txt.rect.center);
      txt.rect = Rect.fromCenter(center: newCenter, width: txt.rect.width * scale, height: txt.rect.height * scale);
      txt.fontSize *= scale;
      txt.angle += rot;
    }
    
    for (var shp in group.shapes) {
      final newCenter = applyTransform(shp.rect.center);
      shp.rect = Rect.fromCenter(center: newCenter, width: shp.rect.width * scale, height: shp.rect.height * scale);
    }
    
    for (var tab in group.tables) {
      final newCenter = applyTransform(tab.rect.center);
      tab.rect = Rect.fromCenter(center: newCenter, width: tab.rect.width * scale, height: tab.rect.height * scale);
    }
    
    pagesPoints[group.pageIndex].addAll(bakedStrokes);
    pagesImages[group.pageIndex].addAll(group.images);
    pagesTexts[group.pageIndex].addAll(group.texts);
    pagesShapes[group.pageIndex].addAll(group.shapes);
    pagesTables[group.pageIndex].addAll(group.tables);
    
    activeSelectionGroup = null;
    notifyContentChanged();
  }

  bool get canUndo =>
      currentPageIndex < pagesPoints.length &&
      pagesPoints[currentPageIndex].isNotEmpty;
  bool get canRedo =>
      currentPageIndex < redoPagesPoints.length &&
      redoPagesPoints[currentPageIndex].isNotEmpty;

  bool showPenSettingsRow = false;
  bool showHighlighterSettingsRow = false;
  bool showLaserSettingsRow = false;
  bool showTextSettingsRow = false;
  bool showAddSettingsRow = false;

  // Default Text Settings
  bool defaultTextBold = false;
  bool defaultTextItalic = false;
  bool defaultTextUnderline = false;
  bool defaultTextStrikethrough = false;
  String defaultTextAlign = 'left';
  double defaultFontSize = 24.0;
  Color defaultTextColor = Colors.black;
  Color defaultTextFillColor = Colors.transparent;
  Color defaultTextBorderColor = Colors.transparent;

  // Laser settings
  int laserFadeDuration = 2; // Default to 2 seconds
  bool isLaserDot = false;
  Color laserColor = Colors.redAccent;
  LaserStroke? currentLaserStroke;
  int? _lastPointTime;
  Offset? _lastPointOffset;

  Rect zoomTargetRect = const Rect.fromLTWH(350, 100, 300, 100);
  bool isZoomWindowVisible = false;

  PdfDocument? pdfDocument;
  final Map<int, Size> pdfPageSizes = {};

  CanvasController({
    required this.document,
    required this.audioCtrl,
    required this.onSave,
    this.isDarkMode = false,
    this.onDarkModeToggle,
    this.showMessage,
    this.buildPageForExport,
  }) {
    // Eagerly initialize all page data structures
    for (int i = 0; i < document.pages.length; i++) {
      ensurePageExists(i);
    }
    loadPdfIfAny();
    loadStrokes();
    loadPenColors();
    loadHighlighterColors();
    loadLaserColors();
    audioCtrl.addListener(notifyListeners);
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    if (onDarkModeToggle != null) onDarkModeToggle!();
    notifyListeners();
  }

  void updateToolbarPosition(ToolbarPosition position) {
    toolbarPosition = position;
    try {
      final box = Hive.box('settingsBox');
      box.put('toolbarPosition_${document.id}', position.index);
    } catch (_) {}
    notifyListeners();
  }

  bool isDraggingPalette = false;
  
  // Floating Windows
  Offset settingsWindowPosition = const Offset(100, 100);
  bool isSettingsMagnetActive = true;
  final GlobalKey dockedSettingsKey = GlobalKey();
  void setDraggingPalette(bool dragging) {
    isDraggingPalette = dragging;
    notifyListeners();
  }

  void updateSettingsWindowPosition(Offset delta) {
    settingsWindowPosition += delta;
    notifyListeners();
  }

  void toggleSettingsMagnet() {
    if (isSettingsMagnetActive && dockedSettingsKey.currentContext != null) {
      final RenderBox? renderBox = dockedSettingsKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        settingsWindowPosition = renderBox.localToGlobal(Offset.zero);
      }
    }
    isSettingsMagnetActive = !isSettingsMagnetActive;
    savePenColors(); // Hive generic save binding
    notifyListeners();
  }

  double selectedFontSize = 24.0;
  void updateFontSize(double size) {
    selectedFontSize = size.clamp(12.0, 72.0);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _laserTimer?.cancel();
    _thumbnailTimer?.cancel();
    scrollController.dispose();
    transformationController.dispose();
    highlighterHoldTimer?.cancel();
    try {
      audioCtrl.removeListener(notifyListeners);
    } catch (_) {}
    super.dispose();
  }

  // --- Getters ---
  int get currentPageIndex => _currentPageIndex;
  set currentPageIndex(int value) {
    if (_currentPageIndex != value) {
      _currentPageIndex = value;
      notifyListeners();
      extractTextForPage(value);
    }
  }

  // --- Pen Colors Logic ---
  List<Color> defaultPenColors = [
    Colors.black,
    Colors.red,
    Colors.green,
  ];
  List<Color> customPenColors = [];

  void loadPenColors() {
    try {
      final box = Hive.box('settingsBox');
      final defColors = box.get('defaultPenColors');
      if (defColors != null && defColors is List) {
        defaultPenColors = defColors.map((c) => Color(c as int)).toList();
      }
      final custColors = box.get('customPenColors');
      if (custColors != null && custColors is List) {
        customPenColors = custColors.map((c) => Color(c as int)).toList();
      }
      final widths = box.get('strokeWidthPresets');
      if (widths != null && widths is List) {
        strokeWidthPresets = widths.map((w) => (w as num).toDouble()).toList();
      }
      activeStrokeWidthIndex = box.get('activeStrokeWidthIndex', defaultValue: 1);
      
      if (activeStrokeWidthIndex >= 0 && activeStrokeWidthIndex < strokeWidthPresets.length) {
        strokeWidth = strokeWidthPresets[activeStrokeWidthIndex];
      }
      isSettingsMagnetActive = box.get('isSettingsMagnetActive', defaultValue: true);
      
      final posIndex = box.get('toolbarPosition_${document.id}', defaultValue: ToolbarPosition.bottom.index);
      toolbarPosition = ToolbarPosition.values[posIndex as int];
    } catch (_) {}
  }

  void savePenColors() {
    try {
      final box = Hive.box('settingsBox');
      box.put('defaultPenColors', defaultPenColors.map((c) => c.toARGB32()).toList());
      box.put('customPenColors', customPenColors.map((c) => c.toARGB32()).toList());
      box.put('strokeWidthPresets', strokeWidthPresets);
      box.put('activeStrokeWidthIndex', activeStrokeWidthIndex);
      box.put('isSettingsMagnetActive', isSettingsMagnetActive);
    } catch (_) {}
  }

  void selectStrokeWidthPreset(int index) {
    if (index >= 0 && index < strokeWidthPresets.length) {
      activeStrokeWidthIndex = index;
      strokeWidth = strokeWidthPresets[index];
      savePenColors();
      notifyListeners();
    }
  }

  void updateStrokeWidthPreset(int index, double newWidth) {
    if (index >= 0 && index < strokeWidthPresets.length) {
      strokeWidthPresets[index] = newWidth;
      if (activeStrokeWidthIndex == index) {
        strokeWidth = newWidth;
      }
      savePenColors();
      notifyListeners();
    }
  }

  void changeDefaultPenColor(int index, Color newColor) {
    if (index >= 0 && index < defaultPenColors.length) {
      defaultPenColors[index] = newColor;
      if (selectedColor == defaultPenColors[index]) selectedColor = newColor;
      savePenColors();
      notifyListeners();
    }
  }

  void addCustomPenColor(Color color) {
    if (customPenColors.length < 7) {
      customPenColors.add(color);
      selectedColor = color;
      savePenColors();
      notifyListeners();
    }
  }

  void changeCustomPenColor(int index, Color newColor) {
    if (index >= 0 && index < customPenColors.length) {
      customPenColors[index] = newColor;
      if (selectedColor == customPenColors[index]) selectedColor = newColor;
      savePenColors();
      notifyListeners();
    }
  }

  void deleteCustomPenColor(int index) {
    if (index >= 0 && index < customPenColors.length) {
      if ((defaultPenColors.length + customPenColors.length) > 3) {
        customPenColors.removeAt(index);
        savePenColors();
        notifyListeners();
      }
    }
  }


  void deleteDefaultPenColor(int index) {
    if (index >= 0 && index < defaultPenColors.length) {
      if ((defaultPenColors.length + customPenColors.length) > 3) {
        defaultPenColors.removeAt(index);
        savePenColors();
        notifyListeners();
      }
    }
  }

  // --- Highlighter Colors Logic ---
  List<Color> defaultHighlighterColors = [
    Colors.yellow,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
  ];
  List<Color> customHighlighterColors = [];

  void loadHighlighterColors() {
    try {
      final box = Hive.box('settingsBox');
      final defColors = box.get('defaultHighlighterColors');
      if (defColors != null && defColors is List) {
        defaultHighlighterColors = defColors.map((c) => Color(c as int)).toList();
      }
      final custColors = box.get('customHighlighterColors');
      if (custColors != null && custColors is List) {
        customHighlighterColors = custColors.map((c) => Color(c as int)).toList();
      }
    } catch (_) {}
  }

  void saveHighlighterColors() {
    try {
      final box = Hive.box('settingsBox');
      box.put('defaultHighlighterColors', defaultHighlighterColors.map((c) => c.toARGB32()).toList());
      box.put('customHighlighterColors', customHighlighterColors.map((c) => c.toARGB32()).toList());
    } catch (_) {}
  }

  void changeDefaultHighlighterColor(int index, Color newColor) {
    if (index >= 0 && index < defaultHighlighterColors.length) {
      defaultHighlighterColors[index] = newColor;
      if (highlighterColor == defaultHighlighterColors[index]) highlighterColor = newColor;
      saveHighlighterColors();
      notifyListeners();
    }
  }

  void addCustomHighlighterColor(Color color) {
    if (customHighlighterColors.length < 7) {
      customHighlighterColors.add(color);
      highlighterColor = color;
      saveHighlighterColors();
      notifyListeners();
    }
  }

  void changeCustomHighlighterColor(int index, Color newColor) {
    if (index >= 0 && index < customHighlighterColors.length) {
      customHighlighterColors[index] = newColor;
      if (highlighterColor == customHighlighterColors[index]) highlighterColor = newColor;
      saveHighlighterColors();
      notifyListeners();
    }
  }

  void deleteCustomHighlighterColor(int index) {
    if (index >= 0 && index < customHighlighterColors.length) {
      if ((defaultHighlighterColors.length + customHighlighterColors.length) > 3) {
        customHighlighterColors.removeAt(index);
        saveHighlighterColors();
        notifyListeners();
      }
    }
  }

  void deleteDefaultHighlighterColor(int index) {
    if (index >= 0 && index < defaultHighlighterColors.length) {
      if ((defaultHighlighterColors.length + customHighlighterColors.length) > 3) {
        defaultHighlighterColors.removeAt(index);
        saveHighlighterColors();
        notifyListeners();
      }
    }
  }

  // --- Laser Colors Logic ---
  List<Color> defaultLaserColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
  ];
  List<Color> customLaserColors = [];

  void loadLaserColors() {
    try {
      final box = Hive.box('settingsBox');
      final defColors = box.get('defaultLaserColors');
      if (defColors != null && defColors is List) {
        defaultLaserColors = defColors.map((c) => Color(c as int)).toList();
      }
      final custColors = box.get('customLaserColors');
      if (custColors != null && custColors is List) {
        customLaserColors = custColors.map((c) => Color(c as int)).toList();
      }
    } catch (_) {}
  }

  void saveLaserColors() {
    try {
      final box = Hive.box('settingsBox');
      box.put('defaultLaserColors', defaultLaserColors.map((c) => c.toARGB32()).toList());
      box.put('customLaserColors', customLaserColors.map((c) => c.toARGB32()).toList());
    } catch (_) {}
  }

  void changeDefaultLaserColor(int index, Color newColor) {
    if (index >= 0 && index < defaultLaserColors.length) {
      defaultLaserColors[index] = newColor;
      if (laserColor == defaultLaserColors[index]) laserColor = newColor;
      saveLaserColors();
      notifyListeners();
    }
  }

  void addCustomLaserColor(Color color) {
    if (customLaserColors.length < 7) {
      customLaserColors.add(color);
      laserColor = color;
      saveLaserColors();
      notifyListeners();
    }
  }

  void changeCustomLaserColor(int index, Color newColor) {
    if (index >= 0 && index < customLaserColors.length) {
      customLaserColors[index] = newColor;
      if (laserColor == customLaserColors[index]) laserColor = newColor;
      saveLaserColors();
      notifyListeners();
    }
  }

  void deleteCustomLaserColor(int index) {
    if (index >= 0 && index < customLaserColors.length) {
      if ((defaultLaserColors.length + customLaserColors.length) > 3) {
        customLaserColors.removeAt(index);
        saveLaserColors();
        notifyListeners();
      }
    }
  }

  void deleteDefaultLaserColor(int index) {
    if (index >= 0 && index < defaultLaserColors.length) {
      if ((defaultLaserColors.length + customLaserColors.length) > 3) {
        defaultLaserColors.removeAt(index);
        saveLaserColors();
        notifyListeners();
      }
    }
  }


  List<Color> get colors => [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.grey,
    Colors.white,
  ];

  // --- Logic Methods ---

}

extension TransformationControllerExtensions on TransformationController {
  Offset toScene(Offset screenPoint) {
    final Matrix4 inverted = Matrix4.copy(value)..invert();
    return MatrixUtils.transformPoint(inverted, screenPoint);
  }
}