import 'package:flutter/material.dart';

enum LaserMode { trail, dot }

class LaserPoint {
  final Offset offset;
  final DateTime timestamp;

  LaserPoint(this.offset) : timestamp = DateTime.now();

  LaserPoint.withTime(this.offset, this.timestamp);
}

class LaserStroke {
  final List<LaserPoint> points;
  final Color color;
  DateTime creationTime;

  LaserStroke({
    required this.points,
    required this.color,
    required this.creationTime,
  });
}

enum CanvasBackgroundType {
  blank,
  ruled_college,
  ruled_narrow,
  grid,
  dotted,
  music,
  todo,
  custom,
}

class PageTemplate {
  final CanvasBackgroundType type;
  final Color paperColor;
  final Color lineColor;
  final double lineSpacing;
  final bool isLandscape;
  final bool isInfinite;
  final String? customAssetPath;
  final double canvasWidth;
  final double canvasHeight;

  const PageTemplate({
    this.type = CanvasBackgroundType.blank,
    this.paperColor = Colors.white,
    this.lineColor = const Color(0x33000000), // default subtle line color
    this.lineSpacing = 30.0,
    this.isLandscape = false,
    this.isInfinite = false,
    this.customAssetPath,
    this.canvasWidth = 700.0,
    this.canvasHeight = 900.0,
  });

  PageTemplate copyWith({
    CanvasBackgroundType? type,
    Color? paperColor,
    Color? lineColor,
    double? lineSpacing,
    bool? isLandscape,
    bool? isInfinite,
    String? customAssetPath,
    double? canvasWidth,
    double? canvasHeight,
  }) {
    return PageTemplate(
      type: type ?? this.type,
      paperColor: paperColor ?? this.paperColor,
      lineColor: lineColor ?? this.lineColor,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      isLandscape: isLandscape ?? this.isLandscape,
      isInfinite: isInfinite ?? this.isInfinite,
      customAssetPath: customAssetPath ?? this.customAssetPath,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
    );
  }
}

class PageImage {
  String path;
  Offset offset;
  Size size;
  final int timestamp;
  final int? audioIndex;

  PageImage(
    this.path,
    this.offset,
    this.size, {
    this.timestamp = 0,
    this.audioIndex,
  });

  Map<String, dynamic> toMap() => {
    'path': path,
    'dx': offset.dx,
    'dy': offset.dy,
    'width': size.width,
    'height': size.height,
    'timestamp': timestamp,
    'audioIndex': audioIndex,
  };

  factory PageImage.fromMap(Map<String, dynamic> map) {
    return PageImage(
      map['path'],
      Offset((map['dx'] ?? 50.0).toDouble(), (map['dy'] ?? 50.0).toDouble()),
      Size(
        (map['width'] ?? 200.0).toDouble(),
        (map['height'] ?? 200.0).toDouble(),
      ),
      timestamp: map['timestamp'] ?? 0,
      audioIndex: map['audioIndex'],
    );
  }
}

class PageText {
  String id;
  String text;
  Rect rect;
  Color color;
  double fontSize;
  String fontFamily;
  String textAlign; // 'left', 'center', 'right', 'justify'
  bool isBold;
  bool isItalic;
  bool isUnderline;
  bool isStrikethrough;
  Color fillColor;
  Color borderColor;
  double borderWidth;
  bool isEditing; // Keeping this for UI state even if not in toMap
  final int timestamp;
  final int? audioIndex;
  String? deltaJson;
  double angle;
  double borderRadius;

  PageText({
    required this.id,
    required this.text,
    required this.rect,
    required this.color,
    required this.fontSize,
    this.fontFamily = 'sans-serif',
    this.textAlign = 'left',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.fillColor = Colors.transparent,
    this.borderColor = Colors.transparent,
    this.borderWidth = 1.0,
    this.isEditing = false,
    this.timestamp = 0,
    this.audioIndex,
    this.deltaJson,
    this.angle = 0.0,
    this.borderRadius = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'left': rect.left,
    'top': rect.top,
    'width': rect.width,
    'height': rect.height,
    'color': color.toARGB32(),
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'textAlign': textAlign,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderline': isUnderline,
    'isStrikethrough': isStrikethrough,
    'fillColor': fillColor.toARGB32(),
    'borderColor': borderColor.toARGB32(),
    'borderWidth': borderWidth,
    'timestamp': timestamp,
    'audioIndex': audioIndex,
    'deltaJson': deltaJson,
    'angle': angle,
    'borderRadius': borderRadius,
  };

  factory PageText.fromMap(Map<String, dynamic> map) {
    // دعم التوافقية مع البيانات القديمة التي كانت تستخدم dx و dy
    double left = (map['left'] ?? map['dx'] ?? 50.0).toDouble();
    double top = (map['top'] ?? map['dy'] ?? 50.0).toDouble();
    double width = (map['width'] ?? 250.0).toDouble();
    double height = (map['height'] ?? 100.0).toDouble();

    return PageText(
      id: map['id'] ?? UniqueKey().toString(),
      text: map['text'] ?? '',
      rect: Rect.fromLTWH(left, top, width, height),
      color: Color(map['color'] ?? 0xFF000000),
      fontSize: (map['fontSize'] ?? 24.0).toDouble(),
      fontFamily: map['fontFamily'] ?? 'sans-serif',
      textAlign: map['textAlign'] ?? 'left',
      isBold: map['isBold'] ?? false,
      isItalic: map['isItalic'] ?? false,
      isUnderline: map['isUnderline'] ?? false,
      isStrikethrough: map['isStrikethrough'] ?? false,
      fillColor: Color(map['fillColor'] ?? 0x00000000),
      borderColor: Color(map['borderColor'] ?? 0x00000000),
      borderWidth: (map['borderWidth'] ?? 1.0).toDouble(),
      timestamp: map['timestamp'] ?? 0,
      audioIndex: map['audioIndex'],
      deltaJson: map['deltaJson'],
      angle: (map['angle'] ?? 0.0).toDouble(),
      borderRadius: (map['borderRadius'] ?? 0.0).toDouble(),
    );
  }
}

class PageShape {
  String id;
  String type; // 'rectangle', 'circle', 'line'
  Rect rect;
  double borderWidth;
  Color borderColor;
  Color fillColor;
  int lineType; // 0 for solid, 1 for dashed
  final int timestamp;
  final int? audioIndex;

  PageShape({
    required this.id,
    required this.type,
    required this.rect,
    this.borderWidth = 2.0,
    this.borderColor = Colors.black,
    this.fillColor = Colors.transparent,
    this.lineType = 0,
    this.timestamp = 0,
    this.audioIndex,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'left': rect.left,
    'top': rect.top,
    'width': rect.width,
    'height': rect.height,
    'borderWidth': borderWidth,
    'borderColor': borderColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'lineType': lineType,
    'timestamp': timestamp,
    'audioIndex': audioIndex,
  };

  factory PageShape.fromMap(Map<String, dynamic> map) {
    return PageShape(
      id: map['id'] ?? UniqueKey().toString(),
      type: map['type'],
      rect: Rect.fromLTWH(map['left'], map['top'], map['width'], map['height']),
      borderWidth: map['borderWidth'],
      borderColor: Color(map['borderColor']),
      fillColor: Color(map['fillColor']),
      lineType: map['lineType'],
      timestamp: map['timestamp'] ?? 0,
      audioIndex: map['audioIndex'],
    );
  }
}

class PageTable {
  String id;
  Rect rect;
  int rows;
  int columns;
  bool hasHeaderRow;
  bool hasHeaderCol;
  double borderWidth;
  Color borderColor;
  Color fillColor;
  Map<String, String> cellTexts; // index like "0,0"
  Map<String, dynamic> cellStyles;
  final int timestamp;
  final int? audioIndex;

  PageTable({
    required this.id,
    required this.rect,
    this.rows = 3,
    this.columns = 3,
    this.hasHeaderRow = true,
    this.hasHeaderCol = false,
    this.borderWidth = 2.0,
    this.borderColor = Colors.grey,
    this.fillColor = Colors.transparent,
    Map<String, String>? cellTexts,
    Map<String, dynamic>? cellStyles,
    this.timestamp = 0,
    this.audioIndex,
  }) : cellTexts = cellTexts ?? {},
       cellStyles = cellStyles ?? {};

  Map<String, dynamic> toMap() => {
    'id': id,
    'left': rect.left,
    'top': rect.top,
    'width': rect.width,
    'height': rect.height,
    'rows': rows,
    'columns': columns,
    'hasHeaderRow': hasHeaderRow,
    'hasHeaderCol': hasHeaderCol,
    'borderWidth': borderWidth,
    'borderColor': borderColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'cellTexts': cellTexts,
    'cellStyles': cellStyles,
    'timestamp': timestamp,
    'audioIndex': audioIndex,
  };

  factory PageTable.fromMap(Map<String, dynamic> map) {
    final rawCellStyles = Map<String, dynamic>.from(map['cellStyles'] ?? {});
    final normalizedCellStyles = rawCellStyles.map((cellKey, styleValue) {
      if (styleValue is Map) {
        return MapEntry(cellKey, Map<String, dynamic>.from(styleValue));
      }
      return MapEntry(cellKey, styleValue);
    });

    return PageTable(
      id: map['id'] ?? UniqueKey().toString(),
      rect: Rect.fromLTWH(map['left'], map['top'], map['width'], map['height']),
      rows: map['rows'],
      columns: map['columns'],
      hasHeaderRow: map['hasHeaderRow'] ?? true,
      hasHeaderCol: map['hasHeaderCol'] ?? false,
      borderWidth: map['borderWidth'],
      borderColor: Color(map['borderColor']),
      fillColor: Color(map['fillColor']),
      timestamp: map['timestamp'] ?? 0,
      audioIndex: map['audioIndex'],
      cellTexts: Map<String, String>.from(map['cellTexts'] ?? {}),
      cellStyles: normalizedCellStyles,
    );
  }
}

enum PenType {
  fountain,
  ball,
  brush,
  perfect,
  velocity,
  pencil,
  highlighter,
  eraserPen,
  eraserHighlighter,
  eraserBoth,
}

enum LineType {
  solid,
  dashed,
  dotted,
}

enum StraightLineMode { holdToDraw, always, never }

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  final double pressure;
  final PenType? penType;
  final int timestamp; // الوقت بالملي ثانية الذي رُسمت فيه النقطة
  final int? audioIndex; // مؤشر التسجيل الصوتي المرتبط بهذه النقطة
  final LineType lineType;
  final double smoothing;
  final bool autoFill;
  final bool simulatePressure;

  DrawingPoint(
    this.offset,
    this.paint, {
    this.pressure = 0.5,
    this.penType,
    this.timestamp = 0,
    this.audioIndex,
    this.lineType = LineType.solid,
    this.smoothing = 0.5,
    this.autoFill = false,
    this.simulatePressure = true,
  });
}

Color getSmartColor(Color c, bool isDark) {
  if (!isDark || c.toARGB32() == Colors.transparent.toARGB32()) return c;

  // نغير اللون فقط إذا كان قريباً جداً من الأسود أو الأبيض تماماً
  // لأن ألوان مثل البنفسجي الغامق قد يكون لها luminance منخفض ولكنها تظل مرئية

  // إذا كان اللون أسود أو قريباً جداً منه (أقل من رمادي داكن)
  if (c.r * 255 < 20 && c.g * 255 < 20 && c.b * 255 < 20) {
    return Colors.white.withValues(alpha: c.a);
  }

  // إذا كان اللون أبيض أو قريباً جداً منه
  if (c.r * 255 > 240 && c.g * 255 > 240 && c.b * 255 > 240) {
    return const Color(0xFF2C2C2E).withValues(alpha: c.a);
  }

  return c;
}

enum ToolbarPosition { top, bottom, left, right }

class CanvasSelectionGroup {
  int pageIndex;
  List<DrawingPoint?> strokes = [];
  List<PageImage> images = [];
  List<PageText> texts = [];
  List<PageShape> shapes = [];
  List<PageTable> tables = [];

  Rect? initialBoundingBox;
  Offset currentTranslation = Offset.zero;
  double currentScale = 1.0;
  double currentRotation = 0.0;

  CanvasSelectionGroup(this.pageIndex);

  bool get isEmpty =>
      strokes.isEmpty &&
      images.isEmpty &&
      texts.isEmpty &&
      shapes.isEmpty &&
      tables.isEmpty;
  bool get isNotEmpty => !isEmpty;

  CanvasSelectionGroup clone() {
    final group = CanvasSelectionGroup(pageIndex);
    group.initialBoundingBox = initialBoundingBox;
    group.currentTranslation = currentTranslation;
    group.currentScale = currentScale;
    group.currentRotation = currentRotation;

    group.strokes = strokes.map((p) {
      if (p == null) return null;
      final newPaint = Paint()
        ..color = p.paint.color
        ..strokeWidth = p.paint.strokeWidth
        ..strokeCap = p.paint.strokeCap
        ..strokeJoin = p.paint.strokeJoin
        ..style = p.paint.style
        ..blendMode = p.paint.blendMode;
      return DrawingPoint(
        p.offset,
        newPaint,
        pressure: p.pressure,
        penType: p.penType,
        timestamp: p.timestamp,
        audioIndex: p.audioIndex,
      );
    }).toList();

    group.images = images
        .map(
          (img) => PageImage(
            img.path,
            img.offset,
            img.size,
            timestamp: img.timestamp,
            audioIndex: img.audioIndex,
          ),
        )
        .toList();

    group.texts = texts
        .map(
          (txt) => PageText(
            id: UniqueKey().toString(),
            text: txt.text,
            rect: txt.rect,
            color: txt.color,
            fontSize: txt.fontSize,
            fontFamily: txt.fontFamily,
            textAlign: txt.textAlign,
            isBold: txt.isBold,
            isItalic: txt.isItalic,
            isUnderline: txt.isUnderline,
            isStrikethrough: txt.isStrikethrough,
            fillColor: txt.fillColor,
            borderColor: txt.borderColor,
            borderWidth: txt.borderWidth,
            isEditing: false,
            timestamp: txt.timestamp,
            audioIndex: txt.audioIndex,
            deltaJson: txt.deltaJson,
            angle: txt.angle,
            borderRadius: txt.borderRadius,
          ),
        )
        .toList();

    group.shapes = shapes
        .map(
          (shp) => PageShape(
            id: UniqueKey().toString(),
            type: shp.type,
            rect: shp.rect,
            borderWidth: shp.borderWidth,
            borderColor: shp.borderColor,
            fillColor: shp.fillColor,
            lineType: shp.lineType,
            timestamp: shp.timestamp,
            audioIndex: shp.audioIndex,
          ),
        )
        .toList();

    group.tables = tables
        .map(
          (tbl) => PageTable(
            id: UniqueKey().toString(),
            rect: tbl.rect,
            rows: tbl.rows,
            columns: tbl.columns,
            hasHeaderRow: tbl.hasHeaderRow,
            hasHeaderCol: tbl.hasHeaderCol,
            borderWidth: tbl.borderWidth,
            borderColor: tbl.borderColor,
            fillColor: tbl.fillColor,
            cellTexts: Map.from(tbl.cellTexts),
            cellStyles: Map.from(tbl.cellStyles),
            timestamp: tbl.timestamp,
            audioIndex: tbl.audioIndex,
          ),
        )
        .toList();

    return group;
  }
}
