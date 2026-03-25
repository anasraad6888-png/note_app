
class NoteFolder {
  final String id;
  String title;
  int? color; // خاصية اللون
  String? parentId; // دعم المجلدات المتداخلة

  NoteFolder({
    required this.id,
    required this.title,
    this.color,
    this.parentId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'color': color,
    'parentId': parentId,
  };

  factory NoteFolder.fromMap(Map<dynamic, dynamic> map) {
    return NoteFolder(
      id: map['id'],
      title: map['title'],
      color: map['color'],
      parentId: map['parentId'],
    );
  }
}

// نموذج البيانات مع دوال التحويل ليناسب قاعدة البيانات
class NoteDocument {
  final String id;
  String title;
  List<List<Map<String, dynamic>>> pages;
  List<List<Map<String, dynamic>>> pageImages; // إضافة دعم الصور لكل صفحة
  List<List<Map<String, dynamic>>> pageTexts; // إضافة دعم النصوص لكل صفحة
  List<List<Map<String, dynamic>>> pageShapes; // إضافة دعم الأشكال لكل صفحة
  List<List<Map<String, dynamic>>> pageTables; // إضافة دعم الجداول لكل صفحة
  String? parentId; // الانتماء للمجلد
  String? pdfPath; // مسار ملف الـ PDF ليكون كخلفية
  List<int> toolbarColors; // ألوان شريط الأدوات المخصصة
  int? color; // خاصية اللون
  List<bool> pageBookmarks; // إضافة دعم الإشارات المرجعية لكل صفحة
  List<String?> pageOutlines; // إضافة الفهرس/المخطط
  List<int?> pdfPageMapping; // ربط صفحة الـ Canvas بصفحة الـ PDF (1-indexed)، null تعني صفحة فارغة
  List<String> audioPaths;
  List<Map<String, dynamic>> audioMetadata; // [{name, path, date, duration}]

  NoteDocument({
    required this.id,
    required this.title,
    List<List<Map<String, dynamic>>>? pages,
    List<List<Map<String, dynamic>>>? pageImages,
    List<List<Map<String, dynamic>>>? pageTexts,
    List<List<Map<String, dynamic>>>? pageShapes,
    List<List<Map<String, dynamic>>>? pageTables,
    this.parentId,
    this.pdfPath,
    this.color,
    List<String>? audioPaths,
    List<Map<String, dynamic>>? audioMetadata,
    List<bool>? pageBookmarks,
    List<String?>? pageOutlines,
    List<int?>? pdfPageMapping,
    List<int>? toolbarColors,
  }) : pages = pages ?? [[]],
       pageImages = pageImages ?? [[]],
       pageTexts = pageTexts ?? [[]],
       pageShapes = pageShapes ?? [[]],
       pageTables = pageTables ?? [[]],
       audioPaths = audioPaths ?? [],
       audioMetadata = audioMetadata ?? [],
       toolbarColors =
           toolbarColors ??
           [
             0xFF2C2C2E, // Charcoal Black
             0xFF5E4AE3, // Indigo Violet
             0xFF3B82F6, // Sky Blue
             0xFF10B981, // Emerald Green
             0xFFEF4444, // Coral Red
           ],
       pageBookmarks =
           pageBookmarks ?? List.filled((pages ?? [[]]).length, false),
       pageOutlines =
           pageOutlines ?? List.filled((pages ?? [[]]).length, null),
       pdfPageMapping =
           pdfPageMapping ?? List.generate((pages ?? [[]]).length, (i) => i + 1);

  // تحويل الكائن إلى Map لحفظه
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'pages': pages,
    'pageImages': pageImages,
    'pageTexts': pageTexts,
    'pageShapes': pageShapes,
    'pageTables': pageTables,
    'parentId': parentId,
    'pdfPath': pdfPath,
    'toolbarColors': toolbarColors,
    'color': color,
    'pageBookmarks': pageBookmarks,
    'pageOutlines': pageOutlines,
    'pdfPageMapping': pdfPageMapping,
    'audioPaths': audioPaths,
    'audioMetadata': audioMetadata,
  };

  factory NoteDocument.fromMap(Map<dynamic, dynamic> map) {
    return NoteDocument(
      id: map['id'],
      title: map['title'],
      pages: map['pages'] != null
          ? (map['pages'] as List)
                .map(
                  (page) => (page as List)
                      .map((stroke) => Map<String, dynamic>.from(stroke as Map))
                      .toList(),
                )
                .toList()
          : [[]],
      pageImages: map['pageImages'] != null
          ? (map['pageImages'] as List)
                .map(
                  (page) => (page as List)
                      .map((image) => Map<String, dynamic>.from(image as Map))
                      .toList(),
                )
                .toList()
          : [[]],
      pageTexts: map['pageTexts'] != null
          ? (map['pageTexts'] as List)
                .map(
                  (page) => (page as List)
                      .map((text) => Map<String, dynamic>.from(text as Map))
                      .toList(),
                )
                .toList()
          : [[]],
      pageShapes: map['pageShapes'] != null
          ? (map['pageShapes'] as List)
                .map(
                  (page) => (page as List)
                      .map((shape) => Map<String, dynamic>.from(shape as Map))
                      .toList(),
                )
                .toList()
          : [[]],
      pageTables: map['pageTables'] != null
          ? (map['pageTables'] as List)
                .map(
                  (page) => (page as List)
                      .map((table) => Map<String, dynamic>.from(table as Map))
                      .toList(),
                )
                .toList()
          : [[]],
      parentId: map['parentId'],
      pdfPath: map['pdfPath'],
      color: map['color'],
      pageBookmarks: map['pageBookmarks'] != null
          ? List<bool>.from(map['pageBookmarks'])
          : null,
      pdfPageMapping: map['pdfPageMapping'] != null
          ? List<int?>.from(map['pdfPageMapping'])
          : null,
      pageOutlines: map['pageOutlines'] != null
          ? List<String?>.from(map['pageOutlines'])
          : null,
      toolbarColors: map['toolbarColors'] != null
          ? List<int>.from(map['toolbarColors'])
          : null,
      audioPaths: map['audioPaths'] != null
          ? List<String>.from(map['audioPaths'])
          : (map['audioPath'] != null ? [map['audioPath']] : []),
      audioMetadata: map['audioMetadata'] != null
          ? List<Map<String, dynamic>>.from(
              (map['audioMetadata'] as List).map(
                (i) => Map<String, dynamic>.from(i as Map),
              ),
            )
          : null,
    );
  }
}
