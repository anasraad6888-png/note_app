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
import 'main_screen.dart';

class FileManagerView extends StatelessWidget {
  final NoteFolder? currentFolder;
  final List<NoteFolder> folders;
  final List<NoteDocument> documents;
  final Function(NoteDocument) onDocumentTap;
  final Function(NoteFolder) onFolderTap;
  final VoidCallback? onBack;
  final VoidCallback onCreateNewDocument;
  final VoidCallback onImportDocument;
  final Function(NoteDocument) onDeleteDocument;
  final Function(NoteFolder) onDeleteFolder;
  final Function(NoteDocument, String) onRenameDocument;
  final Function(NoteFolder, String) onRenameFolder;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool isGridView;
  final VoidCallback onViewToggle;
  final int? selectedColorFilter;
  final ValueChanged<int?> onColorFilterChanged;
  final List<int> customColors;
  final Function(int) onSaveCustomColor;
  final Function(String) onCreateNewFolder;
  final Function(dynamic, int?) onSetItemColor;
  final Function(NoteDocument, String?) onMoveDocument;
  final Function(NoteFolder, String?) onMoveFolder;
  final List<int> defaultColors;

  final bool isDarkMode;
  final VoidCallback onDarkModeToggle;

  final bool isSelectionMode;
  final Set<String> selectedDocuments;
  final Set<String> selectedFolders;
  final VoidCallback onToggleSelectionMode;
  final VoidCallback onClearSelection;
  final Function(NoteDocument) onToggleDocumentSelection;
  final Function(NoteFolder) onToggleFolderSelection;
  final Function(List<NoteDocument>, List<NoteFolder>) onSelectAll;
  final VoidCallback onDeleteSelected;
  final Function(String?) onMoveSelected;

  const FileManagerView({
    super.key,
    this.currentFolder,
    required this.folders,
    required this.documents,
    required this.onDocumentTap,
    required this.onFolderTap,
    required this.onBack,
    required this.onCreateNewDocument,
    required this.onImportDocument,
    required this.onDeleteDocument,
    required this.onDeleteFolder,
    required this.onRenameDocument,
    required this.onRenameFolder,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.isGridView,
    required this.onViewToggle,
    required this.selectedColorFilter,
    required this.onColorFilterChanged,
    required this.customColors,
    required this.onSaveCustomColor,
    required this.onCreateNewFolder,
    required this.onSetItemColor,
    required this.onMoveDocument,
    required this.onMoveFolder,
    required this.defaultColors,
    required this.isDarkMode,
    required this.onDarkModeToggle,
    required this.isSelectionMode,
    required this.selectedDocuments,
    required this.selectedFolders,
    required this.onToggleSelectionMode,
    required this.onClearSelection,
    required this.onToggleDocumentSelection,
    required this.onToggleFolderSelection,
    required this.onSelectAll,
    required this.onDeleteSelected,
    required this.onMoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery.trim().isNotEmpty;
    final filteredFolders = folders.where((f) {
      if (isSearching) {
        final matchesSearch = f.title.toLowerCase().contains(
          searchQuery.toLowerCase(),
        );
        final matchesColor =
            selectedColorFilter == null || f.color == selectedColorFilter;
        return matchesSearch && matchesColor;
      } else if (selectedColorFilter != null && currentFolder == null) {
        return f.color == selectedColorFilter;
      } else {
        return f.parentId == currentFolder?.id;
      }
    }).toList();

    final filteredDocuments = documents.where((d) {
      if (isSearching) {
        final matchesSearch = d.title.toLowerCase().contains(
          searchQuery.toLowerCase(),
        );
        final matchesColor =
            selectedColorFilter == null || d.color == selectedColorFilter;
        return matchesSearch && matchesColor;
      } else if (selectedColorFilter != null && currentFolder == null) {
        return d.color == selectedColorFilter;
      } else {
        return d.parentId == currentFolder?.id;
      }
    }).toList();

    final itemsCount = filteredFolders.length + filteredDocuments.length;
    final int selectedCount = selectedDocuments.length + selectedFolders.length;

    final themeColor = isDarkMode
        ? const Color(0xFF1C1C1E)
        : Colors.grey.shade50;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: themeColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isSelectionMode ? Colors.blue.withAlpha(20) : Colors.transparent,
        foregroundColor: textColor,
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: onClearSelection,
              )
            : currentFolder != null
                ? IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: onBack,
                  )
                : null,
        title: isSelectionMode
            ? Text(
                '$selectedCount تم التحديد',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: textColor,
                ),
              )
            : Row(
          children: [
            Expanded(
              child: Text(
                currentFolder != null ? currentFolder!.title : 'مدير الملفات',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: onSearchChanged,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'البحث عن ملف أو مجلد...',
                    hintStyle: TextStyle(color: subTextColor),
                    border: InputBorder.none,
                    icon: Icon(
                      LucideIcons.search,
                      size: 20,
                      color: subTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildColorChip(null, 'الكل'),
                ...defaultColors.map((c) => _buildColorChip(c, null)),
                ...customColors.map((c) => _buildColorChip(c, null)),
              ],
            ),
          ),
        ),
        actions: isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(LucideIcons.checkSquare),
                  tooltip: 'تحديد الكل',
                  onPressed: () => onSelectAll(filteredDocuments, filteredFolders),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.folderInput),
                  tooltip: 'نقل',
                  onPressed: () {
                    if (selectedCount > 0) _showBulkMoveDialog(context);
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: () {
                    if (selectedCount > 0) _showBulkDeleteConfirmDialog(context);
                  },
                ),
                const SizedBox(width: 8),
              ]
            : [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                color: textColor,
              ),
              tooltip: isDarkMode ? 'الوضع الفاتح' : 'الوضع الليلي',
              onPressed: onDarkModeToggle,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                isGridView ? LucideIcons.list : LucideIcons.layoutGrid,
                color: textColor,
              ),
              tooltip: isGridView ? 'عرض القائمة' : 'عرض الشبكة',
              onPressed: onViewToggle,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.upload, color: Colors.green),
              tooltip: 'استيراد مستند',
              onPressed: onImportDocument,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                LucideIcons.folderPlus,
                color: Colors.blueAccent,
              ),
              tooltip: 'إنشاء مجلد',
              onPressed: () => _showCreateFolderDialog(context),
            ),
          ),
        ],
      ),
      body: itemsCount == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.folderOpen,
                    size: 80,
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد عناصر بعد.',
                    style: TextStyle(color: subTextColor, fontSize: 18),
                  ),
                ],
              ),
            )
          : isGridView
          ? GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.9,
              ),
              itemCount: itemsCount,
              itemBuilder: (context, index) => _buildGridItem(
                context,
                index,
                filteredFolders,
                filteredDocuments,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: itemsCount,
              itemBuilder: (context, index) => _buildListItem(
                context,
                index,
                filteredFolders,
                filteredDocuments,
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreateNewDocument,
        elevation: 4,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'مستند جديد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildColorChip(int? color, String? label) {
    bool isSelected = selectedColorFilter == color;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () => onColorFilterChanged(color),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color != null
                ? Color(color)
                : (isDarkMode ? Colors.white10 : Colors.grey.shade300),
            width: 2,
          ),
        ),
        child: Center(
          child: Row(
            children: [
              if (color != null)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                  ),
                ),
              if (color != null && label == null) const SizedBox(width: 4),
              Text(
                label ?? '',
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, dynamic item) {
    // تصفية المجلدات لاستثناء المجلد الحالي وأبنائه (إذا كان العنصر مجلداً)
    final availableFolders = folders.where((f) {
      if (item is NoteFolder) {
        if (f.id == item.id) return false;
        if (f.parentId == item.id) return false;
      }
      return true;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نقل إلى مجلد'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableFolders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(LucideIcons.home),
                  title: const Text('الصفحة الرئيسية'),
                  onTap: () {
                    if (item is NoteDocument) {
                      onMoveDocument(item, null);
                    } else if (item is NoteFolder) {
                      onMoveFolder(item, null);
                    }
                    Navigator.pop(context);
                  },
                );
              }
              final folder = availableFolders[index - 1];
              return ListTile(
                leading: const Icon(LucideIcons.folder),
                title: Text(folder.title),
                onTap: () {
                  if (item is NoteDocument) {
                    onMoveDocument(item, folder.id);
                  } else if (item is NoteFolder) {
                    onMoveFolder(item, folder.id);
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(
    BuildContext context, {
    NoteDocument? doc,
    NoteFolder? folder,
  }) {
    final backgroundColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          color: backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                doc != null ? doc.title : folder!.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Divider(color: isDarkMode ? Colors.white10 : null),
              // Color Picker Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...defaultColors.map(
                      (c) => _buildColorPickerItem(context, c, doc ?? folder!),
                    ),
                    ...customColors.map(
                      (c) => _buildColorPickerItem(context, c, doc ?? folder!),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.plusCircle,
                        color: isDarkMode ? Colors.white60 : Colors.grey,
                      ),
                      onPressed: () =>
                          _showCustomColorPicker(context, doc ?? folder!),
                    ),
                  ],
                ),
              ),
              Divider(color: isDarkMode ? Colors.white10 : null),
              ListTile(
                leading: Icon(LucideIcons.edit3, color: iconColor),
                title: Text('إعادة تسمية', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, doc: doc, folder: folder);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.move, color: iconColor),
                title: Text('نقل إلى مجلد', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showMoveDialog(context, doc ?? folder!);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.red),
                title: const Text('حذف', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, doc: doc, folder: folder);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorPickerItem(BuildContext context, int color, dynamic item) {
    bool isSelected = item.color == color;
    return GestureDetector(
      onTap: () {
        onSetItemColor(item, color);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: isDarkMode ? Colors.white : Colors.black,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  void _showCustomColorPicker(BuildContext context, dynamic item) {
    Color pickerColor = item.color != null ? Color(item.color!) : Colors.blue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
        title: Text(
          'لون مخصص',
          textAlign: TextAlign.right,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: SingleChildScrollView(
          child: Theme(
            data: isDarkMode
                ? ThemeData.dark().copyWith(
                    canvasColor: const Color(0xFF2C2C2E),
                  )
                : ThemeData.light(),
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'إلغاء',
              style: TextStyle(color: isDarkMode ? Colors.white70 : null),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
            onPressed: () {
              final newColor = pickerColor.toARGB32();
              onSaveCustomColor(newColor);
              onSetItemColor(item, newColor);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close options menu
            },
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
        title: Text(
          'إنشاء مجلد جديد',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'اسم المجلد',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: isDarkMode ? Colors.white70 : null),
            ),
          ),
          TextButton(
            onPressed: () {
              onCreateNewFolder(controller.text);
              Navigator.pop(context);
            },
            child: const Text(
              'إنشاء',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context, {
    NoteDocument? doc,
    NoteFolder? folder,
  }) {
    final controller = TextEditingController(text: doc?.title ?? folder?.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
          title: Text(
            'إعادة تسمية',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'أدخل الاسم الجديد',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(color: isDarkMode ? Colors.white70 : null),
              ),
            ),
            TextButton(
              onPressed: () {
                if (doc != null) onRenameDocument(doc, controller.text);
                if (folder != null) onRenameFolder(folder, controller.text);
                Navigator.pop(context);
              },
              child: const Text(
                'حفظ',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context, {
    NoteDocument? doc,
    NoteFolder? folder,
  }) {
    final itemName = doc?.title ?? folder?.title ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
        title: Text(
          doc != null ? 'حذف المستند' : 'حذف المجلد',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          'هل أنت متأكد من حذف "$itemName"؟ \n${folder != null ? "سيتم حذف جميع المستندات بداخله أيضاً." : ""}',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: isDarkMode ? Colors.white70 : null),
            ),
          ),
          TextButton(
            onPressed: () {
              if (doc != null) onDeleteDocument(doc);
              if (folder != null) onDeleteFolder(folder);
              Navigator.pop(context);
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showBulkMoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
        title: Text(
          'نقل العناصر المحددة (${selectedDocuments.length + selectedFolders.length})',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(LucideIcons.home),
                  title: const Text('الصفحة الرئيسية'),
                  onTap: () {
                    onMoveSelected(null);
                    Navigator.pop(context);
                  },
                );
              }
              final folder = folders[index - 1];
              return ListTile(
                leading: const Icon(LucideIcons.folder),
                title: Text(folder.title),
                onTap: () {
                  onMoveSelected(folder.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBulkDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
        title: Text(
          'حذف العناصر المحددة',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${selectedDocuments.length + selectedFolders.length} عناصر؟ \nسيتم حذف جميع المجلدات المحددة ومحتوياتها.',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: isDarkMode ? Colors.white70 : null),
            ),
          ),
          TextButton(
            onPressed: () {
              onDeleteSelected();
              Navigator.pop(context);
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    int index,
    List<NoteFolder> filteredFolders,
    List<NoteDocument> filteredDocuments,
  ) {
    final bool isSearching = searchQuery.trim().isNotEmpty;

    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    if (index < filteredFolders.length) {
      final folder = filteredFolders[index];
      final bool isSelected = selectedFolders.contains(folder.id);
      return InkWell(
        onTap: () {
          if (isSelectionMode) {
            onToggleFolderSelection(folder);
          } else {
            onFolderTap(folder);
          }
        },
        onLongPress: () {
          if (!isSelectionMode) onToggleSelectionMode();
          onToggleFolderSelection(folder);
        },
        borderRadius: BorderRadius.circular(20),
        child: Hero(
          tag: 'folder_${folder.id}',
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withAlpha(30) : cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.folder,
                            size: 60,
                            color: folder.color != null
                                ? Color(folder.color!)
                                : Colors.blueAccent,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 120, // Give it a constrained width inside FittedBox so text can wrap if needed
                            child: Text(
                              folder.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isSelectionMode)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(
                      isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: isSelected ? Colors.blueAccent : subTextColor,
                    ),
                  ),
                if (!isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        LucideIcons.moreVertical,
                        size: 20,
                        color: subTextColor,
                      ),
                      onPressed: () =>
                          _showOptionsDialog(context, folder: folder),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      final doc = filteredDocuments[index - filteredFolders.length];
      final bool isSelected = selectedDocuments.contains(doc.id);
      return InkWell(
        onTap: () {
          if (isSelectionMode) {
            onToggleDocumentSelection(doc);
          } else {
            onDocumentTap(doc);
          }
        },
        onLongPress: () {
          if (!isSelectionMode) onToggleSelectionMode();
          onToggleDocumentSelection(doc);
        },
        borderRadius: BorderRadius.circular(20),
        child: Hero(
          tag: 'doc_${doc.id}',
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withAlpha(30) : cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (doc.pageImages.isNotEmpty &&
                    doc.pageImages[0].isNotEmpty &&
                    doc.pageImages[0][0]['path'] != null &&
                    File(doc.pageImages[0][0]['path'] as String).existsSync())
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.2,
                      child: Image.file(
                        File(doc.pageImages[0][0]['path'] as String),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.fileText,
                            size: 60,
                            color: doc.color != null
                                ? Color(doc.color!)
                                : Colors.blueAccent,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 120, // Give it a constrained width
                            child: Text(
                              doc.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (isSearching && doc.parentId != null) ...[
                            const SizedBox(height: 2),
                            SizedBox(
                              width: 120, // Constrain width here too
                              child: Text(
                                'في: ${folders.firstWhere(
                                  (f) => f.id == doc.parentId,
                                  orElse: () => NoteFolder(id: '', title: 'مجلد غير معروف'),
                                ).title}',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blueAccent.withAlpha(200),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${doc.pages.length} صفحات',
                            maxLines: 1,
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isSelectionMode)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(
                      isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: isSelected ? Colors.blueAccent : subTextColor,
                    ),
                  ),
                if (!isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        LucideIcons.moreVertical,
                        size: 20,
                        color: subTextColor,
                      ),
                      onPressed: () => _showOptionsDialog(context, doc: doc),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildListItem(
    BuildContext context,
    int index,
    List<NoteFolder> filteredFolders,
    List<NoteDocument> filteredDocuments,
  ) {
    final bool isSearching = searchQuery.trim().isNotEmpty;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    if (index < filteredFolders.length) {
      final folder = filteredFolders[index];
      final bool isSelected = selectedFolders.contains(folder.id);
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: isSelected ? Colors.blue.withAlpha(30) : cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTile(
          onTap: () {
            if (isSelectionMode) {
              onToggleFolderSelection(folder);
            } else {
              onFolderTap(folder);
            }
          },
          onLongPress: () {
            if (!isSelectionMode) onToggleSelectionMode();
            onToggleFolderSelection(folder);
          },
          leading: Icon(
            LucideIcons.folder,
            color: folder.color != null
                ? Color(folder.color!)
                : Colors.blueAccent,
          ),
          title: Text(
            folder.title,
            style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
          ),
          trailing: isSelectionMode
              ? Icon(
                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  color: isSelected ? Colors.blueAccent : subTextColor,
                )
              : IconButton(
                  icon: Icon(LucideIcons.moreVertical, size: 18, color: subTextColor),
                  onPressed: () => _showOptionsDialog(context, folder: folder),
                ),
        ),
      );
    } else {
      final doc = filteredDocuments[index - filteredFolders.length];
      final bool isSelected = selectedDocuments.contains(doc.id);
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: isSelected ? Colors.blue.withAlpha(30) : cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTile(
          onTap: () {
            if (isSelectionMode) {
              onToggleDocumentSelection(doc);
            } else {
              onDocumentTap(doc);
            }
          },
          onLongPress: () {
            if (!isSelectionMode) onToggleSelectionMode();
            onToggleDocumentSelection(doc);
          },
          leading: Icon(
            LucideIcons.fileText,
            color: doc.color != null ? Color(doc.color!) : Colors.blueAccent,
          ),
          title: Text(
            doc.title,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
          ),
          subtitle: Row(
            children: [
              Text(
                '${doc.pages.length} صفحات',
                style: TextStyle(fontSize: 12, color: subTextColor),
              ),
              if (isSearching && doc.parentId != null) ...[
                const SizedBox(width: 8),
                Text(
                  'في: ${folders.firstWhere(
                    (f) => f.id == doc.parentId,
                    orElse: () => NoteFolder(id: '', title: 'مجلد غير معروف'),
                  ).title}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueAccent.withAlpha(200),
                  ),
                ),
              ],
            ],
          ),
          trailing: isSelectionMode
              ? Icon(
                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  color: isSelected ? Colors.blueAccent : subTextColor,
                )
              : IconButton(
                  icon: Icon(LucideIcons.moreVertical, size: 18, color: subTextColor),
                  onPressed: () => _showOptionsDialog(context, doc: doc),
                ),
        ),
      );
    }
  }
}
