import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../widgets/custom_popover.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/note_document.dart';
import '../painters/canvas_painters.dart';
import '../controllers/audio_controller.dart';
import '../controllers/canvas_controller.dart';
import '../widgets/canvas_widgets/drawing_tools_row.dart';
import '../models/canvas_models.dart';
import 'pages_manager_dialog.dart';

class CanvasDialogs {
  /// 1. Edit Document Title Dialog
  static void showEditTitleDialog({
    required BuildContext context,
    required NoteDocument document,
    required bool isDarkMode,
    required VoidCallback onSave,
  }) {
    final controller = TextEditingController(text: document.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
          title: Text(
            'إعادة تسمية المستند',
            style: TextStyle(color: isDarkMode ? Colors.white : null),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: isDarkMode ? Colors.white : null),
            decoration: InputDecoration(
              hintText: 'أدخل الاسم الجديد',
              hintStyle: TextStyle(color: isDarkMode ? Colors.white60 : null),
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
                if (controller.text.trim().isNotEmpty) {
                  document.title = controller.text.trim();
                  onSave();
                }
                Navigator.pop(context);
              },
              child: Text(
                'حفظ',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFFFF7F6A) : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 2. Export Dialog (Bottom Sheet)
  static void showExportDialog({
    required BuildContext context,
    required bool isDarkMode,
    required VoidCallback onExportImage,
    required VoidCallback onExportPdf,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : null,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image, color: Colors.blue),
              title: Text(
                'حفظ كصورة في المعرض (الصفحة الحالية)',
                style: TextStyle(color: isDarkMode ? Colors.white : null),
              ),
              onTap: () {
                Navigator.pop(context);
                onExportImage();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.filePlus, color: Colors.purple),
              title: Text(
                'مشاركة الجميع كملف PDF',
                style: TextStyle(color: isDarkMode ? Colors.white : null),
              ),
              onTap: () {
                Navigator.pop(context);
                onExportPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Clear Page Dialog
  static void showClearPageDialog({
    required BuildContext context,
    required bool isDarkMode,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
        title: Text(
          'مسح الصفحة',
          style: TextStyle(color: isDarkMode ? Colors.white : null),
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع محتويات هذه الصفحة؟',
          style: TextStyle(color: isDarkMode ? Colors.white70 : null),
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
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 4. Erase Filters Dialog
  static void showEraseFiltersDialog({
    required BuildContext context,
    required bool isDarkMode,
    required Set<String> eraseFilters,
    required Function(String, bool) onSetFilter,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
              title: Text(
                'ماذا تريد أن تمسح؟',
                style: TextStyle(color: isDarkMode ? Colors.white : null),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _filterTile(
                    context,
                    isDarkMode,
                    'رسومات القلم',
                    'pen',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'تظليل Highlighter',
                    'highlighter',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'الأشكال Shapes',
                    'shapes',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'الصور Images',
                    'images',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'النصوص Texts',
                    'texts',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'الجداول Tables',
                    'tables',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'إغلاق',
                    style: TextStyle(color: isDarkMode ? Colors.white70 : null),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _filterTile(
    BuildContext context,
    bool isDarkMode,
    String title,
    String key,
    Set<String> eraseFilters,
    Function(String, bool) onSetFilter,
    StateSetter setDialogState,
  ) {
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white70 : null,
        ),
      ),
      value: eraseFilters.contains(key),
      onChanged: (v) {
        setDialogState(() {
          onSetFilter(key, v ?? false);
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 5. Table Settings Dialog
  static void showTableSettingsDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
    required bool isTopHalf,
  }) {
    final bool isDarkMode = canvasCtrl.isDarkMode;
    showCustomPopover(
      context: context,
      isTopHalf: isTopHalf,
      width: 340,
      height: (MediaQuery.of(context).size.height - 140).clamp(50.0, 640.0),
      backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Theme.of(context).cardColor,
      bodyBuilder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'إعدادات الجدول',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Preview Area
                    Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withAlpha(10)
                            : Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withAlpha(30)
                              : Colors.grey.withAlpha(50),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: TablePreviewPainter(
                            rows: canvasCtrl.tableRows,
                            cols: canvasCtrl.tableCols,
                            hasHeaderRow: canvasCtrl.tableHeaderRow,
                            hasHeaderCol: canvasCtrl.tableHeaderCol,
                            borderColor: canvasCtrl.tableBorderColor,
                            fillColor: canvasCtrl.tableFillColor,
                            borderWidth: canvasCtrl.tableBorderWidth,
                          ),
                        ),
                      ),
                    ),

                    // Controls
                    _buildSettingsCard(
                      context: context,
                      isDarkMode: isDarkMode,
                      children: [
                        _buildCounterControl(
                          context,
                          isDarkMode,
                          'عدد الصفوف',
                          canvasCtrl.tableRows,
                          1,
                          10,
                          (v) { canvasCtrl.tableRows = v; canvasCtrl.notifyListeners(); setDialogState((){}); },
                          setDialogState,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1),
                        ),
                        _buildCounterControl(
                          context,
                          isDarkMode,
                          'عدد الأعمدة',
                          canvasCtrl.tableCols,
                          1,
                          10,
                          (v) { canvasCtrl.tableCols = v; canvasCtrl.notifyListeners(); setDialogState((){}); },
                          setDialogState,
                        ),
                      ],
                    ),

                    _buildSettingsCard(
                      context: context,
                      isDarkMode: isDarkMode,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'صف رأس الجدول',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            CupertinoSwitch(
                              value: canvasCtrl.tableHeaderRow,
                              activeTrackColor: const Color(0xFFFF7F6A),
                              onChanged: (v) {
                                canvasCtrl.tableHeaderRow = v;
                                canvasCtrl.notifyListeners();
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'عمود رأس الجدول',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            CupertinoSwitch(
                              value: canvasCtrl.tableHeaderCol,
                              activeTrackColor: const Color(0xFFFF7F6A),
                              onChanged: (v) {
                                canvasCtrl.tableHeaderCol = v;
                                canvasCtrl.notifyListeners();
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    _buildSettingsCard(
                      context: context,
                      isDarkMode: isDarkMode,
                      children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               'سمك الإطار',
                               style: TextStyle(
                                 fontSize: 15,
                                 fontWeight: FontWeight.w500,
                                 color: isDarkMode ? Colors.white70 : Colors.black87,
                               ),
                             ),
                             Text(
                               canvasCtrl.tableBorderWidth.toInt().toString(),
                               style: TextStyle(
                                 fontSize: 15,
                                 fontWeight: FontWeight.bold,
                                 color: isDarkMode ? const Color(0xFFFF7F6A) : Colors.blue,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 8),
                         SliderTheme(
                           data: SliderTheme.of(context).copyWith(
                             trackHeight: 6,
                             thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                             overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                           ),
                           child: Slider(
                             value: canvasCtrl.tableBorderWidth,
                             min: 1,
                             max: 10,
                             divisions: 9,
                             activeColor: const Color(0xFFFF7F6A),
                             inactiveColor: isDarkMode ? Colors.white12 : Colors.black12,
                             onChanged: (v) {
                               canvasCtrl.tableBorderWidth = v;
                               canvasCtrl.notifyListeners();
                               setDialogState(() {});
                             },
                           ),
                         ),
                      ],
                    ),

                    _buildSettingsCard(
                      context: context,
                      isDarkMode: isDarkMode,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _colorPickerButton(
                              context,
                              isDarkMode,
                              setDialogState,
                              'الإطار',
                              canvasCtrl.tableBorderColor,
                              canvasCtrl,
                              (c) {
                                canvasCtrl.tableBorderColor = c;
                                canvasCtrl.notifyListeners();
                                setDialogState(() {});
                              },
                            ),
                            _colorPickerButton(
                              context,
                              isDarkMode,
                              setDialogState,
                              'التعبئة',
                              canvasCtrl.tableFillColor,
                              canvasCtrl,
                              (c) {
                                canvasCtrl.tableFillColor = c;
                                canvasCtrl.notifyListeners();
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                  ],
                ).animate().fade(duration: 200.ms).slideY(begin: 0.1, duration: 200.ms),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildSettingsCard({
    required BuildContext context,
    required bool isDarkMode,
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static Widget _buildCounterControl(
    BuildContext context,
    bool isDarkMode,
    String label,
    int value,
    int min,
    int max,
    Function(int) onUpdate,
    StateSetter setDialogState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black26 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(LucideIcons.minus, size: 18, color: value > min ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey),
                onPressed: value > min ? () { onUpdate(value - 1); setDialogState((){}); } : null,
              ),
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(LucideIcons.plus, size: 18, color: value < max ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey),
                onPressed: value < max ? () { onUpdate(value + 1); setDialogState((){}); } : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 6. Shape Settings Dialog
  static void showShapeSettingsDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
    required bool isTopHalf,
  }) {
    final bool isDarkMode = canvasCtrl.isDarkMode;
    showCustomPopover(
      context: context,
      isTopHalf: isTopHalf,
      width: 340,
      height: (MediaQuery.of(context).size.height - 80).clamp(100.0, 640.0),
      backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Theme.of(context).cardColor,
      bodyBuilder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'إعدادات الأشكال',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Preview Area
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withAlpha(30) : Colors.grey.withAlpha(50),
                    ),
                  ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: ShapePreviewPainter(
                            type: canvasCtrl.selectedShapeType,
                            borderWidth: canvasCtrl.shapeBorderWidth,
                            borderColor: canvasCtrl.shapeBorderColor,
                            fillColor: canvasCtrl.shapeFillColor,
                            lineType: canvasCtrl.shapeLineType,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ),
                ),
                
                _buildSettingsCard(
                  context: context,
                  isDarkMode: isDarkMode,
                  children: [
                    Text(
                      'نوع الشكل',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _shapeGridItem(
                          isDarkMode,
                          canvasCtrl.selectedShapeType,
                          setDialogState,
                          'rectangle',
                          LucideIcons.square,
                          onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                        ),
                        _shapeGridItem(
                          isDarkMode,
                          canvasCtrl.selectedShapeType,
                          setDialogState,
                          'circle',
                          LucideIcons.circle,
                          onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                        ),
                        _shapeGridItem(
                          isDarkMode,
                          canvasCtrl.selectedShapeType,
                          setDialogState,
                          'triangle',
                          LucideIcons.triangle,
                          onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                        ),
                        _shapeGridItem(
                          isDarkMode,
                          canvasCtrl.selectedShapeType,
                          setDialogState,
                          'line',
                          LucideIcons.minus,
                          onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                        ),
                        _shapeGridItem(
                          isDarkMode,
                          canvasCtrl.selectedShapeType,
                          setDialogState,
                          'arrow',
                          LucideIcons.arrowRight,
                          onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                        ),
                        _shapeGridItem(
                          isDarkMode,
                          canvasCtrl.selectedShapeType,
                          setDialogState,
                          'sin',
                          null,
                          label: 'sin',
                          onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                        ),
                        _shapeGridItem(
                          isDarkMode,
                          canvasCtrl.selectedShapeType,
                          setDialogState,
                          'cos',
                          null,
                          label: 'cos',
                          onUpdate: (v) { canvasCtrl.selectedShapeType = v; canvasCtrl.notifyListeners(); },
                        ),
                      ],
                    ),
                  ],
                ),
                
                _buildSettingsCard(
                  context: context,
                  isDarkMode: isDarkMode,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سُمك ونوع الخط',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black26 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () { canvasCtrl.shapeLineType = 0; canvasCtrl.notifyListeners(); setDialogState((){}); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: canvasCtrl.shapeLineType == 0 ? const Color(0xFFFF7F6A) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('متصل', style: TextStyle(color: canvasCtrl.shapeLineType == 0 ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87), fontSize: 13, fontWeight: canvasCtrl.shapeLineType == 0 ? FontWeight.bold : FontWeight.normal)),
                                ),
                              ),
                              GestureDetector(
                                onTap: () { canvasCtrl.shapeLineType = 1; canvasCtrl.notifyListeners(); setDialogState((){}); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: canvasCtrl.shapeLineType == 1 ? const Color(0xFFFF7F6A) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('متقطع', style: TextStyle(color: canvasCtrl.shapeLineType == 1 ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87), fontSize: 13, fontWeight: canvasCtrl.shapeLineType == 1 ? FontWeight.bold : FontWeight.normal)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          canvasCtrl.shapeBorderWidth.toInt().toString(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? const Color(0xFFFF7F6A) : Colors.blue,
                          ),
                        ),
                        Expanded(
                         child: SliderTheme(
                           data: SliderTheme.of(context).copyWith(
                             trackHeight: 6,
                             thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                             overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                           ),
                           child: Slider(
                             value: canvasCtrl.shapeBorderWidth,
                             min: 1,
                             max: 50,
                             divisions: 49,
                             activeColor: const Color(0xFFFF7F6A),
                             inactiveColor: isDarkMode ? Colors.white12 : Colors.black12,
                             onChanged: (v) {
                               canvasCtrl.shapeBorderWidth = v;
                               canvasCtrl.notifyListeners();
                               setDialogState(() {});
                             },
                           ),
                         ),
                        ),
                      ],
                    ),
                  ],
                ),

                _buildSettingsCard(
                  context: context,
                  isDarkMode: isDarkMode,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _colorPickerButton(
                          context,
                          isDarkMode,
                          setDialogState,
                          'الإطار',
                          canvasCtrl.shapeBorderColor,
                          canvasCtrl,
                          (c) {
                            canvasCtrl.shapeBorderColor = c;
                            canvasCtrl.notifyListeners();
                            setDialogState(() {});
                          },
                        ),
                        _colorPickerButton(
                          context,
                          isDarkMode,
                          setDialogState,
                          'التعبئة',
                          canvasCtrl.shapeFillColor,
                          canvasCtrl,
                          (c) {
                            canvasCtrl.shapeFillColor = c;
                            canvasCtrl.notifyListeners();
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ).animate().fade(duration: 200.ms).slideY(begin: 0.1, duration: 200.ms),
          ),
        ),
      ),
    );
  }

  static Widget _shapeGridItem(
    bool isDarkMode,
    String selectedShapeType,
    StateSetter setDialogState,
    String type,
    IconData? icon, {
    String? label,
    required Function(String) onUpdate,
  }) {
    bool isSelected = selectedShapeType == type;
    return GestureDetector(
      onTap: () {
        onUpdate(type);
        setDialogState(() {});
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode
                    ? Colors.amber.withValues(alpha: 0.3)
                    : Colors.blue.withValues(alpha: 0.2))
              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? Colors.amber : Colors.blue)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  color: isSelected
                      ? (isDarkMode ? Colors.amber : Colors.blue)
                      : (isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade700),
                  size: 22,
                )
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (isDarkMode ? Colors.amber : Colors.blue)
                        : (isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade700),
                  ),
                ),
        ),
      ),
    );
  }

  /// 7. Custom Color Picker Dialog
  static void showCustomColorPicker({
    required BuildContext context,
    required bool isDarkMode,
    required Color initialColor,
    required Function(Color) onColorChanged,
  }) {
    Color selectedColor = initialColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
        title: Text(
          'اختر اللون',
          textAlign: TextAlign.right,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Theme(
                data: isDarkMode
                    ? ThemeData.dark().copyWith(
                        canvasColor: const Color(0xFF2C2C2E),
                      )
                    : ThemeData.light(),
                child: ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) => selectedColor = color,
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha: true,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  onColorChanged(const Color(0x00000000));
                  Navigator.pop(context);
                },
                child: Text(
                  'بدون لون (شفاف)',
                  style: TextStyle(
                    color: isDarkMode ? Colors.redAccent.shade100 : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: isDarkMode ? Colors.white70 : null),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F6A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              onColorChanged(selectedColor);
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  /// 8. Document Pages Grid Dialog
  static void showPagesGridDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // transparent to let PagesManagerDialog handle shape/color
      builder: (context) {
        return PagesManagerDialog(canvasCtrl: canvasCtrl);
      },
    );
  }

  /// 9. Rename Audio Recording Dialog
  static void showRenameAudioDialog({
    required BuildContext context,
    required bool isDarkMode,
    required int index,
    required AudioController audioCtrl,
  }) {
    String currentName = audioCtrl.document.audioMetadata[index]['name'] ?? '';
    TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : null,
        title: Text(
          'إعادة تسمية التسجيل',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'اسم التسجيل الجديد',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: isDarkMode ? Colors.white70 : null),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                audioCtrl.renameRecording(index, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // Helper: Color Picker Button
  static Widget _colorPickerButton(
    BuildContext context,
    bool isDarkMode,
    StateSetter setDialogState,
    String title,
    Color currentColor,
    CanvasController canvasCtrl,
    Function(Color) onColorChanged,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => DrawingToolsRow.showPopoverColorPicker(
            context: context,
            currentColor: currentColor,
            canvasCtrl: canvasCtrl,
            useDialog: true,
            onColorChanged: (c) {
              onColorChanged(c);
              setDialogState(() {});
            },
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: currentColor == Colors.transparent ? Colors.white : currentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: currentColor == Colors.transparent
                ? Icon(Icons.format_color_reset, color: Colors.red.shade400, size: 24)
                : null,
          ),
        ),
      ],
    );
  }

  /// 9. Page Settings Dialog
  static void showPageSettingsDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
    bool isTopHalf = false,
  }) {
    final bool isDarkMode = canvasCtrl.isDarkMode;
    PageTemplate currentTemp = canvasCtrl.pageTemplates[canvasCtrl.currentPageIndex];
    bool applyToAll = false;

    showCustomPopover(
      context: context,
      isTopHalf: isTopHalf,
      width: 340,
      height: (MediaQuery.of(context).size.height - 140).clamp(50.0, 560.0),
      backgroundColor: Colors.transparent, // Transparent for Glassmorphism
      bodyBuilder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateTemplate(PageTemplate newTemp) {
            // Guarantee an immediate expansion when infinite mode is activated
            // so that scroll controllers can actually be scrolled.
            if (newTemp.isInfinite && newTemp.canvasHeight < 3000) {
              newTemp = newTemp.copyWith(canvasHeight: 3000);
            }
            
            currentTemp = newTemp;
            if (applyToAll) {
              for (int i = 0; i < canvasCtrl.pageTemplates.length; i++) {
                canvasCtrl.pageTemplates[i] = newTemp;
              }
            } else {
              canvasCtrl.pageTemplates[canvasCtrl.currentPageIndex] = newTemp;
            }
            canvasCtrl.notifyListeners();
            setDialogState(() {});
          }

          Widget templateGridItem(
            CanvasBackgroundType type,
            String label,
            IconData iconData,
          ) {
            bool isSelected = currentTemp.type == type;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => updateTemplate(currentTemp.copyWith(type: type)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 64,
                height: 70,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFFFF7F6A).withAlpha(isDarkMode ? 80 : 25)
                      : (isDarkMode ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF7F6A) : (isDarkMode ? Colors.white10 : Colors.black.withAlpha(10)),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: const Color(0xFFFF7F6A).withAlpha(isDarkMode ? 30 : 15), blurRadius: 12, offset: const Offset(0, 4))
                  ] : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        iconData, 
                        size: 24, 
                        color: isSelected ? const Color(0xFFFF7F6A) : (isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label, 
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, 
                        color: isSelected ? const Color(0xFFFF7F6A) : (isDarkMode ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white).withAlpha(180),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? Colors.white12 : Colors.black.withAlpha(20),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(LucideIcons.layoutTemplate, color: isDarkMode ? Colors.white : Colors.black87, size: 24),
                          const SizedBox(width: 12),
                          Text('إعدادات الصفحة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Apply to All Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black.withAlpha(50) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black.withAlpha(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.layers, size: 18, color: const Color(0xFFFF7F6A).withAlpha(200)),
                                const SizedBox(width: 10),
                                Text(
                                  'تطبيق على جميع الصفحات',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            CupertinoSwitch(
                              value: applyToAll,
                              activeTrackColor: const Color(0xFFFF7F6A),
                              inactiveTrackColor: isDarkMode ? Colors.white12 : Colors.grey.shade300,
                              onChanged: (v) {
                                applyToAll = v;
                                updateTemplate(currentTemp);
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Templates Grid Section
                      Text('نمط التسطير', 
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white54 : Colors.black45, letterSpacing: 0.5)
                      ).animate().fade(delay: 100.ms),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        alignment: WrapAlignment.start,
                        children: [
                          templateGridItem(CanvasBackgroundType.blank, 'فارغ', LucideIcons.square),
                          templateGridItem(CanvasBackgroundType.ruled_college, 'مسطر', LucideIcons.alignJustify),
                          templateGridItem(CanvasBackgroundType.grid, 'مربعات', LucideIcons.layoutGrid),
                          templateGridItem(CanvasBackgroundType.dotted, 'منقط', LucideIcons.moreHorizontal),
                          templateGridItem(CanvasBackgroundType.todo, 'مهام', LucideIcons.checkSquare),
                          templateGridItem(CanvasBackgroundType.music, 'موسيقى', LucideIcons.music),
                        ]
                      ),

                      const SizedBox(height: 24),

                      // Colors Section
                      Text('الألوان الرئيسية', 
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white54 : Colors.black45, letterSpacing: 0.5)
                      ).animate().fade(delay: 200.ms),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildModernColorPicker(
                              context: context, 
                              isDarkMode: isDarkMode, 
                              setDialogState: setDialogState, 
                              title: 'لون الورقة', 
                              color: currentTemp.paperColor, 
                              canvasCtrl: canvasCtrl, 
                              onColorChanged: (c) => updateTemplate(currentTemp.copyWith(paperColor: c))
                            ),
                          ),
                          if (currentTemp.type != CanvasBackgroundType.blank) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernColorPicker(
                                context: context, 
                                isDarkMode: isDarkMode, 
                                setDialogState: setDialogState, 
                                title: 'لون السطور', 
                                color: currentTemp.lineColor, 
                                canvasCtrl: canvasCtrl, 
                                onColorChanged: (c) => updateTemplate(currentTemp.copyWith(lineColor: c))
                              ),
                            ),
                          ]
                        ],
                      ),

                      // Density / Line Spacing Slider
                      if (currentTemp.type != CanvasBackgroundType.blank && currentTemp.type != CanvasBackgroundType.custom) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('التباعد / الكثافة', 
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white54 : Colors.black45)
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7F6A).withAlpha(isDarkMode ? 30 : 20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${currentTemp.lineSpacing.toInt()}', 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF7F6A))
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                         SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 8,
                            activeTrackColor: const Color(0xFFFF7F6A),
                            inactiveTrackColor: isDarkMode ? Colors.white10 : Colors.black12,
                            thumbColor: Colors.white,
                            overlayColor: const Color(0xFFFF7F6A).withAlpha(50),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                            tickMarkShape: SliderTickMarkShape.noTickMark,
                            trackShape: const RoundedRectSliderTrackShape(),
                          ),
                          child: Slider(
                            value: currentTemp.lineSpacing,
                            min: 10,
                            max: 100,
                            onChanged: (v) => updateTemplate(currentTemp.copyWith(lineSpacing: v)),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Infinite Canvas Option
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black.withAlpha(50) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black.withAlpha(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.move, size: 18, color: const Color(0xFFFF7F6A).withAlpha(200)),
                                const SizedBox(width: 10),
                                Text(
                                  'لا نهائي (Infinite Canvas)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            CupertinoSwitch(
                              value: currentTemp.isInfinite,
                              activeTrackColor: const Color(0xFFFF7F6A),
                              inactiveTrackColor: isDarkMode ? Colors.white12 : Colors.grey.shade300,
                              onChanged: (v) => updateTemplate(currentTemp.copyWith(isInfinite: v)),
                            ),
                          ],
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
      ),
    );
  }

  static Widget _buildModernColorPicker({
    required BuildContext context,
    required bool isDarkMode,
    required StateSetter setDialogState,
    required String title,
    required Color color,
    required CanvasController canvasCtrl,
    required Function(Color) onColorChanged,
  }) {
    return GestureDetector(
      onTap: () {
        DrawingToolsRow.showPopoverColorPicker(
          context: context,
          currentColor: color,
          onColorChanged: onColorChanged,
          canvasCtrl: canvasCtrl,
          useDialog: true,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 24, 
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black26, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(100),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

