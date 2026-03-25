import 'package:flutter/material.dart';
import '../models/canvas_models.dart';
import 'dart:math' as math;

class InteractiveTableWidget extends StatefulWidget {
  final PageTable table;
  final int pageIndex;
  final bool readOnly;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final bool isDarkMode;

  const InteractiveTableWidget({
    super.key,
    required this.table,
    required this.pageIndex,
    required this.onSave,
    required this.onDelete,
    this.readOnly = false,
    this.isDarkMode = false,
  });

  @override
  State<InteractiveTableWidget> createState() => _InteractiveTableWidgetState();
}

class _InteractiveTableWidgetState extends State<InteractiveTableWidget> {
  int _initialRows = 0;
  int _initialCols = 0;
  double _tableDragAccumulatorX = 0;
  double _tableDragAccumulatorY = 0;
  double _initialCellWidth = 0;
  double _initialCellHeight = 0;

  bool isSelected = false;
  int? selectedRowIndex;
  int? selectedColIndex;

  int? editingRow;
  int? editingCol;
  final TextEditingController _cellTextController = TextEditingController();

  @override
  void dispose() {
    _cellTextController.dispose();
    super.dispose();
  }

  void _insertColumn(int atIndex) {
    setState(() {
      final cellWidth = widget.table.rect.width / widget.table.columns;
      widget.table.columns++;
      widget.table.rect = Rect.fromLTWH(
        widget.table.rect.left,
        widget.table.rect.top,
        widget.table.rect.width + cellWidth,
        widget.table.rect.height,
      );

      // تشفيت النصوص لليمين
      for (int r = 0; r < widget.table.rows; r++) {
        for (int c = widget.table.columns - 1; c > atIndex; c--) {
          final prevText = widget.table.cellTexts["$r,${c - 1}"];
          if (prevText != null) {
            widget.table.cellTexts["$r,$c"] = prevText;
          } else {
            widget.table.cellTexts.remove("$r,$c");
          }
        }
        widget.table.cellTexts.remove("$r,$atIndex"); // تفريغ الخلية الجديدة
      }
    });
    widget.onSave();
  }

  void _insertRow(int atIndex) {
    setState(() {
      final cellHeight = widget.table.rect.height / widget.table.rows;
      widget.table.rows++;
      widget.table.rect = Rect.fromLTWH(
        widget.table.rect.left,
        widget.table.rect.top,
        widget.table.rect.width,
        widget.table.rect.height + cellHeight,
      );

      // تشفيت النصوص للأسفل
      for (int c = 0; c < widget.table.columns; c++) {
        for (int r = widget.table.rows - 1; r > atIndex; r--) {
          final prevText = widget.table.cellTexts["${r - 1},$c"];
          if (prevText != null) {
            widget.table.cellTexts["$r,$c"] = prevText;
          } else {
            widget.table.cellTexts.remove("$r,$c");
          }
        }
        widget.table.cellTexts.remove("$atIndex,$c"); // تفريغ الخلية الجديدة
      }
    });
    widget.onSave();
  }

  Widget _buildHandle({
    required Widget child,
    required Color color,
    required Color borderColor,
    VoidCallback? onTap,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragStartCallback? onPanStart,
    VoidCallback? onPanEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: (_) {
        if (onPanEnd != null) onPanEnd();
        widget.onSave();
      },
      child: Container(
        color: Colors.transparent, // زيادة مساحة الاستشعار
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          padding: const EdgeInsets.all(4),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    return Positioned(
      left: table.rect.left - 50,
      top: table.rect.top - 50,
      width: table.rect.width + 100,
      height: table.rect.height + 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. الجدول الفعلي
          Positioned(
            left: 50,
            top: 50,
            width: table.rect.width,
            height: table.rect.height,
            child: widget.readOnly
                ? Container(
                    color: getSmartColor(table.fillColor, widget.isDarkMode),
                    child: Table(
                      border: TableBorder.all(
                        color: getSmartColor(
                          table.borderColor,
                          widget.isDarkMode,
                        ),
                        width: table.borderWidth,
                      ),
                      children: List.generate(table.rows, (rowIndex) {
                        return TableRow(
                          children: List.generate(table.columns, (colIndex) {
                            final isHeader =
                                (table.hasHeaderRow && rowIndex == 0) ||
                                (table.hasHeaderCol && colIndex == 0);

                            return Container(
                              height: table.rect.height / table.rows,
                              decoration: BoxDecoration(
                                color: isHeader
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.transparent,
                              ),
                              child: Container(
                                alignment: _getAlignment(
                                  table.cellStyles["$rowIndex,$colIndex"]?['align'] ??
                                      'center',
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  table.cellTexts["$rowIndex,$colIndex"] ?? "",
                                  textAlign: _getTextAlign(
                                    table.cellStyles["$rowIndex,$colIndex"]?['align'] ??
                                        'center',
                                  ),
                                  style: _getCellTextStyle(
                                    table.cellStyles["$rowIndex,$colIndex"] ??
                                        {},
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  )
                : GestureDetector(
                    onTapUp: (_) {
                      setState(() {
                        isSelected = true;
                        selectedRowIndex = null;
                        selectedColIndex = null;
                      });
                    },
                    child: Container(
                      color: getSmartColor(table.fillColor, widget.isDarkMode),
                      child: Table(
                        border: TableBorder.all(
                          color: getSmartColor(
                            table.borderColor,
                            widget.isDarkMode,
                          ),
                          width: table.borderWidth,
                        ),
                        children: List.generate(table.rows, (rowIndex) {
                          return TableRow(
                            children: List.generate(table.columns, (colIndex) {
                              final isHeader =
                                  (table.hasHeaderRow && rowIndex == 0) ||
                                  (table.hasHeaderCol && colIndex == 0);
                              final isRowSelected =
                                  selectedRowIndex == rowIndex;
                              final isColSelected =
                                  selectedColIndex == colIndex;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isSelected = true;
                                    selectedRowIndex = rowIndex;
                                    selectedColIndex = colIndex;
                                  });
                                },
                                onDoubleTap: () {
                                  setState(() {
                                    editingRow = rowIndex;
                                    editingCol = colIndex;
                                    _cellTextController.text =
                                        table
                                            .cellTexts["$rowIndex,$colIndex"] ??
                                        "";
                                  });
                                },
                                child: Container(
                                  height: table.rect.height / table.rows,
                                  decoration: BoxDecoration(
                                    color: (isRowSelected || isColSelected)
                                        ? Colors.blue.withAlpha(50)
                                        : (isHeader
                                              ? Colors.blue.withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.transparent),
                                    border:
                                        (selectedRowIndex == rowIndex &&
                                            selectedColIndex == colIndex)
                                        ? Border.all(
                                            color: Colors.blue,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child:
                                      (editingRow == rowIndex &&
                                          editingCol == colIndex)
                                      ? TextField(
                                          controller: _cellTextController,
                                          autofocus: true,
                                          textAlign: _getTextAlign(
                                            table.cellStyles["$rowIndex,$colIndex"]?['align'] ??
                                                'center',
                                          ),
                                          decoration:
                                              const InputDecoration.collapsed(
                                                hintText: "",
                                              ),
                                          style: _getCellTextStyle(
                                            table.cellStyles["$rowIndex,$colIndex"] ??
                                                {},
                                          ),
                                          onChanged: (value) {
                                            table.cellTexts["$rowIndex,$colIndex"] =
                                                value;
                                          },
                                          onSubmitted: (_) {
                                            setState(() {
                                              editingRow = null;
                                              editingCol = null;
                                            });
                                            widget.onSave();
                                          },
                                          onTapOutside: (_) {
                                            setState(() {
                                              editingRow = null;
                                              editingCol = null;
                                            });
                                            widget.onSave();
                                          },
                                        )
                                      : Container(
                                          alignment: _getAlignment(
                                            table.cellStyles["$rowIndex,$colIndex"]?['align'] ??
                                                'center',
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            table.cellTexts["$rowIndex,$colIndex"] ??
                                                "",
                                            textAlign: _getTextAlign(
                                              table.cellStyles["$rowIndex,$colIndex"]?['align'] ??
                                                  'center',
                                            ),
                                            style: _getCellTextStyle(
                                              table.cellStyles["$rowIndex,$colIndex"] ??
                                                  {},
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
          ),
          // 2. مقبض التحريك
          if (isSelected && !widget.readOnly)
            Positioned(
              top: 50 - 20,
              left: 50 - 20,
              child: _buildHandle(
                color: Colors.white,
                borderColor: Colors.grey.shade300,
                onPanUpdate: (details) {
                  setState(() {
                    table.rect = table.rect.shift(details.delta);
                  });
                },
                child: const Icon(
                  Icons.drag_indicator,
                  size: 14,
                  color: Colors.blue,
                ),
              ),
            ),
          // 3. مقبض الحذف
          if (isSelected && !widget.readOnly)
            Positioned(
              top: 50 - 20,
              right: 50 - 20,
              child: _buildHandle(
                color: Colors.white,
                borderColor: Colors.red.shade200,
                onTap: widget.onDelete,
                child: const Icon(Icons.close, size: 14, color: Colors.red),
              ),
            ),
          // 4. مقبض إضافة الصفوف والأعمدة
          if (isSelected && !widget.readOnly)
            Positioned(
              bottom: 50 - 20,
              right: 50 - 20,
              child: _buildHandle(
                color: Colors.white,
                borderColor: Colors.green.shade200,
                onPanStart: (details) {
                  _tableDragAccumulatorX = 0;
                  _tableDragAccumulatorY = 0;
                  _initialCellWidth = table.rect.width / table.columns;
                  _initialCellHeight = table.rect.height / table.rows;
                  _initialRows = table.rows;
                  _initialCols = table.columns;
                },
                onPanUpdate: (details) {
                  _tableDragAccumulatorX += details.delta.dx;
                  _tableDragAccumulatorY += details.delta.dy;

                  int addedCols = (_tableDragAccumulatorX / _initialCellWidth)
                      .round();
                  int addedRows = (_tableDragAccumulatorY / _initialCellHeight)
                      .round();

                  int newCols = math.max(1, _initialCols + addedCols);
                  int newRows = math.max(1, _initialRows + addedRows);

                  if (newCols != table.columns || newRows != table.rows) {
                    setState(() {
                      table.columns = newCols;
                      table.rows = newRows;
                      table.rect = Rect.fromLTWH(
                        table.rect.left,
                        table.rect.top,
                        newCols * _initialCellWidth,
                        newRows * _initialCellHeight,
                      );
                    });
                  }
                },
                child: const Icon(Icons.add, size: 14, color: Colors.green),
              ),
            ),
          // 5. مقبض تغيير الأبعاد الحر
          if (isSelected && !widget.readOnly)
            Positioned(
              bottom: 50 - 20,
              left: 50 - 20,
              child: _buildHandle(
                color: Colors.white,
                borderColor: Colors.grey.shade300,
                onPanUpdate: (details) {
                  setState(() {
                    double newWidth = table.rect.width - details.delta.dx;
                    double newHeight = table.rect.height + details.delta.dy;
                    double minWidth = table.columns * 20.0;
                    double minHeight = table.rows * 20.0;

                    if (newWidth < minWidth) newWidth = minWidth;
                    if (newHeight < minHeight) newHeight = minHeight;

                    double deltaX = table.rect.width - newWidth;
                    table.rect = Rect.fromLTWH(
                      table.rect.left + deltaX,
                      table.rect.top,
                      newWidth,
                      newHeight,
                    );
                  });
                },
                child: const Icon(
                  Icons.aspect_ratio,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
            ),

          // 6. أدوات التحكم بالعمود
          if (isSelected && selectedColIndex != null && !widget.readOnly)
            Positioned(
              top: 50 - 35,
              left:
                  50 +
                  (selectedColIndex! *
                          (widget.table.rect.width / widget.table.columns))
                      .toDouble(),
              width: widget.table.rect.width / widget.table.columns,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final insertLeft = GestureDetector(
                    onTap: () => _insertColumn(selectedColIndex!),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  );

                  final insertRight = GestureDetector(
                    onTap: () => _insertColumn(selectedColIndex! + 1),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  );

                  // If the column is narrow, stack buttons to avoid overflow.
                  if (constraints.maxWidth < 52) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        insertLeft,
                        const SizedBox(height: 4),
                        insertRight,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [insertLeft, insertRight],
                  );
                },
              ),
            ),

          // 7. أدوات التحكم بالصف
          if (isSelected && selectedRowIndex != null && !widget.readOnly)
            Positioned(
              left: 50 - 35,
              top:
                  50 +
                  (selectedRowIndex! *
                          (widget.table.rect.height / widget.table.rows))
                      .toDouble(),
              height: widget.table.rect.height / widget.table.rows,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _insertRow(selectedRowIndex!),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _insertRow(selectedRowIndex! + 1),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 8. شريط أدوات التنسيق
          if (isSelected &&
              selectedRowIndex != null &&
              selectedColIndex != null &&
              !widget.readOnly)
            Positioned(
              top: 5,
              left: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أزرار المحاذاة
                    Builder(
                      builder: (context) {
                        final currentAlign =
                            widget
                                .table
                                .cellStyles["$selectedRowIndex,$selectedColIndex"]?['align'] ??
                            'center';
                        IconData currentIcon;
                        if (currentAlign == 'left') {
                          currentIcon = Icons.format_align_left;
                        } else if (currentAlign == 'right') {
                          currentIcon = Icons.format_align_right;
                        } else {
                          currentIcon = Icons.format_align_center;
                        }

                        return PopupMenuButton<String>(
                          icon: Icon(
                            currentIcon,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onSelected: (align) =>
                              _updateCellStyle('align', align),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'right',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.format_align_right,
                                    size: 18,
                                    color: Colors.blueGrey,
                                  ),
                                  SizedBox(width: 8),
                                  Text('يمين'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'center',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.format_align_center,
                                    size: 18,
                                    color: Colors.blueGrey,
                                  ),
                                  SizedBox(width: 8),
                                  Text('وسط'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'left',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.format_align_left,
                                    size: 18,
                                    color: Colors.blueGrey,
                                  ),
                                  SizedBox(width: 8),
                                  Text('يسار'),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const VerticalDivider(width: 16),
                    // حجم الخط
                    GestureDetector(
                      onTap: _showFontSizeDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '${widget.table.cellStyles["$selectedRowIndex,$selectedColIndex"]?['fontSize']?.toInt() ?? 14}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 16),
                    // نوع الخط
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.font_download,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                      onSelected: (font) =>
                          _updateCellStyle('fontFamily', font),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'sans-serif',
                          child: Text('Sans-Serif'),
                        ),
                        const PopupMenuItem(
                          value: 'serif',
                          child: Text('Serif'),
                        ),
                        const PopupMenuItem(
                          value: 'monospace',
                          child: Text('Monospace'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 16),
                    // اللون
                    GestureDetector(
                      onTap: _cycleCellColor,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: getSmartColor(
                            Color(
                              widget
                                      .table
                                      .cellStyles["$selectedRowIndex,$selectedColIndex"]?['color'] ??
                                  Colors.black.toARGB32(),
                            ),
                            widget.isDarkMode,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _updateCellStyle(String key, dynamic value) {
    setState(() {
      final cellKey = "$selectedRowIndex,$selectedColIndex";
      widget.table.cellStyles[cellKey] = Map<String, dynamic>.from(
        widget.table.cellStyles[cellKey] ?? {},
      );
      widget.table.cellStyles[cellKey]![key] = value;
    });
    widget.onSave();
  }

  void _showFontSizeDialog() {
    final currentSize =
        widget
            .table
            .cellStyles["$selectedRowIndex,$selectedColIndex"]?['fontSize']
            ?.toInt() ??
        14;
    final controller = TextEditingController(text: currentSize.toString());
    final presetSizes = [8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'حجم الخط',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'أدخل حجم الخط...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: presetSizes.map((size) {
                  return InkWell(
                    onTap: () {
                      _updateCellStyle('fontSize', size.toDouble());
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentSize == size
                            ? const Color(0xFFFF7F6A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentSize == size
                              ? const Color(0xFFFF7F6A)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        size.toString(),
                        style: TextStyle(
                          color: currentSize == size
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final newSize = double.tryParse(controller.text);
                if (newSize != null && newSize > 0) {
                  _updateCellStyle('fontSize', newSize);
                }
                Navigator.pop(context);
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  void _cycleCellColor() {
    final cellKey = "$selectedRowIndex,$selectedColIndex";
    final currentColor =
        widget.table.cellStyles[cellKey]?['color'] ?? Colors.black.toARGB32();
    final colors = [
      Colors.black.toARGB32(),
      Colors.red.toARGB32(),
      Colors.blue.toARGB32(),
      Colors.green.toARGB32(),
    ];
    int nextIndex = (colors.indexOf(currentColor) + 1) % colors.length;
    _updateCellStyle('color', colors[nextIndex]);
  }

  TextAlign _getTextAlign(String align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  Alignment _getAlignment(String align) {
    switch (align) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      case 'center':
      default:
        return Alignment.center;
    }
  }

  TextStyle _getCellTextStyle(Map style) {
    final normalized = <String, dynamic>{
      for (final entry in style.entries) entry.key.toString(): entry.value,
    };

    return TextStyle(
      fontSize: (normalized['fontSize'] ?? 14).toDouble(),
      color: getSmartColor(
        Color(normalized['color'] ?? Colors.black.toARGB32()),
        widget.isDarkMode,
      ),
      fontFamily: normalized['fontFamily'] ?? 'sans-serif',
    );
  }
}
