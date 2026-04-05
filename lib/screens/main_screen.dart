import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import '../drawing_canvas.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../models/note_document.dart';
import '../models/canvas_models.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/audio_controller.dart';
import 'file_manager_view.dart';

class MainScreen extends StatefulWidget {
  final bool initialDarkMode;
  final VoidCallback onGlobalThemeToggle;

  const MainScreen({
    super.key,
    required this.initialDarkMode,
    required this.onGlobalThemeToggle,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  NoteDocument? activeDocument;
  List<NoteDocument> recentDocuments = [];
  bool showFileManager = true;

  List<NoteDocument> allDocuments = [];
  List<NoteFolder> allFolders = [];
  NoteFolder? currentFolder; // المجلد المفتوح حالياً
  String searchQuery = ''; // نص البحث
  bool isGridView = true; // وضع العرض (شبكة/قائمة)

  int? selectedColorFilter; // فلتر اللون المختار
  List<int> customColors = []; // الألوان المخصصة للمستخدم
  bool get isDarkMode => widget.initialDarkMode;

  bool isSelectionMode = false;
  Set<String> selectedDocuments = {};
  Set<String> selectedFolders = {};

  final List<int> defaultColors = [
    0xFFEF4444, // Red
    0xFF3B82F6, // Blue
    0xFF10B981, // Green
  ];

  // الاتصال بصندوق قاعدة البيانات
  final _box = Hive.box('documentsBox');
  final _foldersBox = Hive.box('foldersBox');
  final _settingsBox = Hive.box('settingsBox');

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCustomColors();
  }

  void _toggleDarkMode() {
    widget.onGlobalThemeToggle();
  }

  void _loadCustomColors() {
    final colors = _settingsBox.get('customColors', defaultValue: <int>[]);
    setState(() {
      customColors = List<int>.from(colors);
    });
  }

  void _saveCustomColor(int color) {
    if (!customColors.contains(color) && !defaultColors.contains(color)) {
      setState(() {
        customColors.add(color);
      });
      _settingsBox.put('customColors', customColors);
    }
  }

  // 3. دالة جلب المستندات والمجلدات المحفوظة عند فتح التطبيق
  void _loadData() {
    final docsData = _box.values.toList();
    final foldersData = _foldersBox.values.toList();
    setState(() {
      allDocuments = docsData.map((e) => NoteDocument.fromMap(e)).toList();
      allFolders = foldersData.map((e) => NoteFolder.fromMap(e)).toList();
    });
  }

  void toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        clearSelection();
      }
    });
  }

  void clearSelection() {
    setState(() {
      selectedDocuments.clear();
      selectedFolders.clear();
      isSelectionMode = false;
    });
  }

  void toggleDocumentSelection(NoteDocument doc) {
    setState(() {
      if (selectedDocuments.contains(doc.id)) {
        selectedDocuments.remove(doc.id);
      } else {
        selectedDocuments.add(doc.id);
      }
      if (selectedDocuments.isEmpty && selectedFolders.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  void toggleFolderSelection(NoteFolder folder) {
    setState(() {
      if (selectedFolders.contains(folder.id)) {
        selectedFolders.remove(folder.id);
      } else {
        selectedFolders.add(folder.id);
      }
      if (selectedDocuments.isEmpty && selectedFolders.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  void selectAll(List<NoteDocument> currentDocs, List<NoteFolder> currentFolders) {
    setState(() {
      final allDocIds = currentDocs.map((e) => e.id).toSet();
      final allFolderIds = currentFolders.map((e) => e.id).toSet();
      
      if (selectedDocuments.length == allDocIds.length && selectedFolders.length == allFolderIds.length) {
        clearSelection();
      } else {
        selectedDocuments = allDocIds;
        selectedFolders = allFolderIds;
      }
    });
  }

  void deleteSelectedItems() {
    setState(() {
      for (String folderId in selectedFolders.toList()) {
        final folderIndex = allFolders.indexWhere((f) => f.id == folderId);
        if (folderIndex != -1) {
          _recursiveDeleteFolder(allFolders[folderIndex]);
        }
      }
      for (String docId in selectedDocuments.toList()) {
        final docIndex = allDocuments.indexWhere((d) => d.id == docId);
        if (docIndex != -1) {
          _box.delete(docId);
          allDocuments.removeAt(docIndex);
          recentDocuments.removeWhere((element) => element.id == docId);
          if (activeDocument?.id == docId) {
            activeDocument = null;
            showFileManager = true;
          }
        }
      }
      clearSelection();
    });
  }

  void moveSelectedItems(String? targetFolderId) {
    setState(() {
      for (String folderId in selectedFolders.toList()) {
        final folderIndex = allFolders.indexWhere((f) => f.id == folderId);
        if (folderIndex != -1) {
          final folder = allFolders[folderIndex];
          if (targetFolderId != folder.id) {
            folder.parentId = targetFolderId;
            _foldersBox.put(folder.id, folder.toMap());
          }
        }
      }
      for (String docId in selectedDocuments.toList()) {
        final docIndex = allDocuments.indexWhere((d) => d.id == docId);
        if (docIndex != -1) {
          final doc = allDocuments[docIndex];
          doc.parentId = targetFolderId;
          _box.put(doc.id, doc.toMap());
        }
      }
      clearSelection();
    });
  }

  // 4. دالة إنشاء وحفظ مستند جديد في قاعدة البيانات داخل المجلد الحالي
  void createNewDocument() {
    final newDoc = NoteDocument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Document ${allDocuments.length + 1}',
      parentId: currentFolder?.id,
      pages: [[]],
      pageImages: [[]],
      pageTexts: [[]],
      pageShapes: [[]],
    );

    _box.put(newDoc.id, newDoc.toMap()); // الحفظ الفعلي

    setState(() {
      allDocuments.add(newDoc);
    });
    openDocument(newDoc);
  }

  // دالة إنشاء المجلد
  void createNewFolder(String title) {
    if (title.trim().isEmpty) return;
    final newFolder = NoteFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      parentId: currentFolder?.id,
    );
    _foldersBox.put(newFolder.id, newFolder.toMap());
    setState(() {
      allFolders.add(newFolder);
    });
  }

  Future<void> _importDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final extension = result.files.single.extension?.toLowerCase();
      final title = result.files.single.name;

      NoteDocument newDoc = NoteDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        parentId: currentFolder?.id,
      );

      if (extension == 'pdf') {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final savedPdf = await File(path).copy(
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          newDoc.pdfPath = savedPdf.path;

          final pdfDoc = await PdfDocument.openFile(savedPdf.path);
          int pagesCount = pdfDoc.pagesCount;

          List<List<Map<String, dynamic>>> emptyPagesArray() =>
              List.generate(pagesCount, (_) => []);

          newDoc.pages = emptyPagesArray();
          newDoc.pageImages = emptyPagesArray();
          newDoc.pageTexts = emptyPagesArray();
          newDoc.pageShapes = emptyPagesArray();
        } catch (e) {
          debugPrint('Error loading PDF: $e');
          return;
        }
      } else if (extension == 'txt' || extension == 'md') {
        try {
          String content = await File(path).readAsString();
          newDoc.pages = [[]];
          newDoc.pageImages = [[]];
          newDoc.pageShapes = [[]];
          newDoc.pageTexts = [
            [
              {
                'text': content,
                'dx': 50.0,
                'dy': 50.0,
                'color': 0xFF000000,
                'fontSize': 24.0,
              },
            ],
          ];
        } catch (e) {
          debugPrint('Error reading text file: $e');
          return;
        }
      } else if (['png', 'jpg', 'jpeg'].contains(extension)) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final savedImg = await File(path).copy(
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.$extension',
          );

          newDoc.pages = [[]];
          newDoc.pageTexts = [[]];
          newDoc.pageShapes = [[]];
          newDoc.pageImages = [
            [
              {
                'path': savedImg.path,
                'dx': 50.0,
                'dy': 50.0,
                'width': 300.0,
                'height': 300.0,
              },
            ],
          ];
        } catch (e) {
          debugPrint('Error copying image: $e');
          return;
        }
      } else {
        return;
      }

      _box.put(newDoc.id, newDoc.toMap());
      setState(() {
        allDocuments.add(newDoc);
      });
      openDocument(newDoc);
    }
  }

  // 5. دالة حذف المستند من قاعدة البيانات ومن الواجهة
  void deleteDocument(NoteDocument doc) {
    _box.delete(doc.id); // الحذف الفعلي

    setState(() {
      allDocuments.removeWhere((element) => element.id == doc.id);
      recentDocuments.removeWhere((element) => element.id == doc.id);

      // إذا كان المستند المحذوف هو المفتوح حالياً، نغلقه ونعود لمدير الملفات
      if (activeDocument?.id == doc.id) {
        activeDocument = null;
        showFileManager = true;
      }
    });
  }

  // دالة حذف المجلد وكل محتوياته (مستندات ومجلدات فرعية)
  void deleteFolder(NoteFolder folder) {
    setState(() {
      _recursiveDeleteFolder(folder);
    });
  }

  void _recursiveDeleteFolder(NoteFolder folder) {
    // 1. حذف المجلد نفسه
    _foldersBox.delete(folder.id);
    allFolders.removeWhere((element) => element.id == folder.id);
    if (currentFolder?.id == folder.id) {
      // إذا كان المجلد الحالي هو المحذوف، نعود للأب أو للجذر
      if (folder.parentId != null) {
        currentFolder = allFolders.firstWhere(
          (f) => f.id == folder.parentId,
          orElse: () => NoteFolder(id: '', title: ''),
        );
        if (currentFolder!.id == '') currentFolder = null;
      } else {
        currentFolder = null;
      }
    }

    // 2. حذف جميع المستندات داخل هذا المجلد
    final docsToDelete = allDocuments
        .where((doc) => doc.parentId == folder.id)
        .toList();
    for (var doc in docsToDelete) {
      _box.delete(doc.id);
      allDocuments.removeWhere((element) => element.id == doc.id);
      recentDocuments.removeWhere((element) => element.id == doc.id);
      if (activeDocument?.id == doc.id) {
        activeDocument = null;
        showFileManager = true;
      }
    }

    // 3. حذف المجلدات الفرعية بشكل تكراري
    final subFolders = allFolders
        .where((f) => f.parentId == folder.id)
        .toList();
    for (var sub in subFolders) {
      _recursiveDeleteFolder(sub);
    }
  }

  // دوال إعادة التسمية
  void renameDocument(NoteDocument doc, String newTitle) {
    if (newTitle.trim().isEmpty) return;
    setState(() {
      doc.title = newTitle.trim();
      _box.put(doc.id, doc.toMap());
    });
  }

  void renameFolder(NoteFolder folder, String newTitle) {
    if (newTitle.trim().isEmpty) return;
    setState(() {
      folder.title = newTitle.trim();
      _foldersBox.put(folder.id, folder.toMap());
    });
  }

  void setItemColor(dynamic item, int? color) {
    setState(() {
      item.color = color;
    });
    if (item is NoteDocument) {
      _box.put(item.id, item.toMap());
    } else if (item is NoteFolder) {
      _foldersBox.put(item.id, item.toMap());
    }
  }

  void moveDocumentToFolder(NoteDocument document, String? targetFolderId) {
    setState(() {
      document.parentId = targetFolderId;
    });
    _box.put(document.id, document.toMap());
  }

  void moveFolderToFolder(NoteFolder folder, String? targetFolderId) {
    // منع نقل المجلد داخل نفسه أو داخل أحد أبنائه
    if (targetFolderId == folder.id) return;

    setState(() {
      folder.parentId = targetFolderId;
    });
    _foldersBox.put(folder.id, folder.toMap());
  }

  void saveDocument(NoteDocument doc) {
    _box.put(doc.id, doc.toMap());
  }

  void openDocument(NoteDocument doc) {
    setState(() {
      activeDocument = doc;
      showFileManager = false;

      recentDocuments.removeWhere((element) => element.id == doc.id);
      recentDocuments.insert(0, doc);

      if (recentDocuments.length > 4) {
        recentDocuments = recentDocuments.sublist(0, 4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = isDarkMode
        ? const Color(0xFF1C1C1E)
        : Colors.grey.shade50;
    final sidebarColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: themeColor,
      body: Padding(
        padding: EdgeInsets.only(top: Platform.isMacOS ? 32.0 : 0.0),
        child: Row(
          children: [
          if (showFileManager && MediaQuery.of(context).size.width >= 450)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: sidebarColor,
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),

                  if (activeDocument != null)
                    Container(
                      color: !showFileManager
                          ? Colors.blue.withAlpha(26)
                          : Colors.transparent,
                      child: ListTile(
                        leading: const Icon(
                          LucideIcons.fileEdit,
                          color: Colors.blue,
                        ),
                        title: Text(
                          activeDocument!.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            showFileManager = false;
                          });
                        },
                      ),
                    ),

                  Container(
                    color: showFileManager
                        ? Colors.blue.withAlpha(26)
                        : Colors.transparent,
                    child: ListTile(
                      leading: Icon(
                        LucideIcons.folder,
                        color: showFileManager ? Colors.blue : Colors.black54,
                      ),
                      title: Text(
                        'Files Manager',
                        style: TextStyle(
                          fontWeight: showFileManager
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: showFileManager ? Colors.blue : textColor,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          showFileManager = true;
                          currentFolder =
                              null; // العودة للصفحة الرئيسية للمجلدات
                        });
                      },
                    ),
                  ),

                  const Divider(),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Recents',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ...recentDocuments.map(
                    (doc) => ListTile(
                      dense: true,
                      leading: Icon(
                        LucideIcons.fileText,
                        size: 20,
                        color: subTextColor,
                      ),
                      title: Text(
                        doc.title,
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                      onTap: () => openDocument(doc),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: showFileManager
                ? FileManagerView(
                    currentFolder: currentFolder,
                    folders: allFolders, // Pass all folders for global search
                    documents:
                        allDocuments, // Pass all documents for global search
                    onDocumentTap: openDocument,
                    onFolderTap: (folder) {
                      setState(() {
                        currentFolder = folder;
                      });
                    },
                    onBack: currentFolder == null
                        ? null
                        : () {
                            setState(() {
                              if (currentFolder!.parentId != null) {
                                currentFolder = allFolders.firstWhere(
                                  (f) => f.id == currentFolder!.parentId,
                                );
                              } else {
                                currentFolder = null;
                              }
                            });
                          },
                    onCreateNewDocument: createNewDocument,
                    onImportDocument: _importDocument,
                    onCreateNewFolder: createNewFolder,
                    onDeleteDocument: deleteDocument,
                    onDeleteFolder: deleteFolder,
                    onRenameDocument: renameDocument,
                    onRenameFolder: renameFolder,
                    searchQuery: searchQuery,
                    onSearchChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    isGridView: isGridView,
                    onViewToggle: () {
                      setState(() {
                        isGridView = !isGridView;
                      });
                    },
                    selectedColorFilter: selectedColorFilter,
                    onColorFilterChanged: (color) {
                      setState(() {
                        selectedColorFilter = color;
                      });
                    },
                    customColors: customColors,
                    onSaveCustomColor: _saveCustomColor,
                    onSetItemColor: setItemColor,
                    onMoveDocument: moveDocumentToFolder,
                    onMoveFolder: moveFolderToFolder,
                    defaultColors: defaultColors,
                    isDarkMode: isDarkMode,
                    onDarkModeToggle: _toggleDarkMode,
                    isSelectionMode: isSelectionMode,
                    selectedDocuments: selectedDocuments,
                    selectedFolders: selectedFolders,
                    onToggleSelectionMode: toggleSelectionMode,
                    onClearSelection: clearSelection,
                    onToggleDocumentSelection: toggleDocumentSelection,
                    onToggleFolderSelection: toggleFolderSelection,
                    onSelectAll: selectAll,
                    onDeleteSelected: deleteSelectedItems,
                    onMoveSelected: moveSelectedItems,
                  )
                : DrawingCanvas(
                    document: activeDocument!,
                    onSave: saveDocument,
                    isDarkMode: isDarkMode,
                    onDarkModeToggle: _toggleDarkMode,
                    onClose: () {
                      setState(() {
                        showFileManager = true;
                      });
                    },
                  ),
          ),
        ],
      ),
    ));
  }
}

