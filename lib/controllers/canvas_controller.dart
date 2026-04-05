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
part 'canvas/audio_sync_logic.dart';
part 'canvas/page_management_logic.dart';
part 'canvas/geometry_logic.dart';
part 'canvas/lasso_drawing_logic.dart';
part 'canvas/export_logic.dart';
part 'canvas/ocr_logic.dart';
part 'canvas/selection_logic.dart';
part 'canvas/colors_logic.dart';
part 'canvas/scroll_logic.dart';

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
  bool isMultiTouchPan = false;
  
  void setMultiTouchPan(bool value) {
    if (isMultiTouchPan != value) {
      isMultiTouchPan = value;
      notifyListeners();
    }
  }

  bool isZoomSliderVisible = false;
  bool isRulerVisible = false;
  ToolbarPosition toolbarPosition = ToolbarPosition.bottom;
  bool isDarkMode;
  Size? viewportSize;
  VoidCallback? onDarkModeToggle;
  VoidCallback? onShowPagesGridDialog;
  VoidCallback? onDocumentClose;
  Function(int)? onShowCustomColorPicker;

  // Global Text Editor State
  PageText? activeEditingText;
  quill.QuillController? activeQuillController;
  VoidCallback? toggleTextInspector;
  BuildContext? activeEditingContext; // context of the text widget being edited

  void startEditingText(
    PageText text,
    quill.QuillController controller, {
    VoidCallback? toggleInspector,
    BuildContext? textContext,
  }) {
    activeEditingText = text;
    activeQuillController = controller;
    toggleTextInspector = toggleInspector;
    activeEditingContext = textContext;
    notifyListeners();
  }

  void stopEditingText() {
    activeEditingText?.isEditing = false;
    activeEditingText = null;
    activeQuillController = null;
    toggleTextInspector = null;
    activeEditingContext = null;
    notifyListeners();
  }

  /// Auto-scrolls the canvas (paged mode) so the active text box is visible
  /// above the keyboard. Call this whenever the keyboard height changes.

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
  Set<String> eraseFilters = {
    'pen',
    'highlighter',
    'shapes',
    'images',
    'texts',
    'tables',
  };
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
  Offset? textStartPos;
  Rect? currentDrawingTextRect;
  bool isAudioBarVisible = false;

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
  List<Color> defaultTextColors = [Colors.black, Colors.white, Colors.red, Colors.blue];
  List<Color> customTextColors = [];
  Color defaultTextColor = Colors.black;
  Color defaultTextFillColor = Colors.transparent;
  Color defaultTextBorderColor = Colors.transparent;

  // Laser settings
  int laserFadeDuration = 2; // Default to 2 seconds
  bool isLaserDot = false;
  Color laserColor = Colors.red;
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
    loadTextColors();
    audioCtrl.addListener(notifyContentChanged);
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
      final RenderBox? renderBox =
          dockedSettingsKey.currentContext?.findRenderObject() as RenderBox?;
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
  List<Color> defaultPenColors = [Colors.black, Colors.red, Colors.green];
  List<Color> customPenColors = [];










  // --- Highlighter Colors Logic ---
  List<Color> defaultHighlighterColors = [
    Colors.yellow,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
  ];
  List<Color> customHighlighterColors = [];








  // --- Laser Colors Logic ---
  List<Color> defaultLaserColors = [Colors.red, Colors.green, Colors.blue];
  List<Color> customLaserColors = [];










  // --- Logic Methods ---
}

extension TransformationControllerExtensions on TransformationController {
  Offset toScene(Offset screenPoint) {
    final Matrix4 inverted = Matrix4.copy(value)..invert();
    return MatrixUtils.transformPoint(inverted, screenPoint);
  }
}
