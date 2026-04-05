import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../painters/canvas_painters.dart';
import '../../controllers/canvas_controller.dart';
import '../../widgets/custom_popover.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dialog_helpers.dart';

class TableSettingsDialog {
  // --- Helper لزر العداد المدمج ---
  static Widget _buildCompactCounter(
    BuildContext context, bool isDarkMode, String label, IconData icon, int value, int min, int max, Function(int) onUpdate
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(icon, size: 14, color: isDarkMode ? Colors.white54 : Colors.black54),
             const SizedBox(width: 4),
             Text(label, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black54)),
           ]
        ),
        const SizedBox(height: 8),
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black26 : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: Icon(LucideIcons.minus, size: 16, color: value > min ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey),
                onPressed: value > min ? () => onUpdate(value - 1) : null,
              ),
              Container(
                width: 26,
                alignment: Alignment.center,
                child: Text(value.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: Icon(LucideIcons.plus, size: 16, color: value < max ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey),
                onPressed: value < max ? () => onUpdate(value + 1) : null,
              ),
            ]
          )
        )
      ]
    );
  }

  // --- Helper لمحولات رأس الجدول المدمجة ---
  static Widget _buildCompactHeaderToggle(bool isDarkMode, String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white70 : Colors.black87)),
        const SizedBox(width: 4),
        Transform.scale(
          scale: 0.7, // تصغير الحجم
          child: CupertinoSwitch(
            value: value,
            activeTrackColor: const Color(0xFFFF7F6A),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  static void showTableSettingsDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
    required bool isTopHalf,
    Alignment? alignment,
  }) {
    final bool isDarkMode = canvasCtrl.isDarkMode;
    showCustomPopover(
      context: context,
      isTopHalf: isTopHalf,
      alignment: alignment,
      width: 320, // Smaller width for elegance
      // height: null, // Allow wrapping to children beautifully
      backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Theme.of(context).cardColor,
      bodyBuilder: (dialogContext) {
        bool isAtBottom = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bgColor = isDarkMode ? const Color(0xFF2C2C2E) : Theme.of(context).cardColor;
            
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQueryData.fromView(View.of(context)).size.height * 0.60,
              ),
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.axis == Axis.vertical) {
                        // If maxScrollExtent is 0, it means it doesn't scroll.
                        // So we safely consider it "at bottom".
                        bool newIsAtBottom = scrollInfo.metrics.maxScrollExtent <= 0 ||
                            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 10.0;
                        if (newIsAtBottom != isAtBottom) {
                          Future.microtask(() {
                            if (context.mounted) {
                              setDialogState(() {
                                isAtBottom = newIsAtBottom;
                              });
                            }
                          });
                        }
                      }
                      return false; // let the scroll event pass through
                    },
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24.0), // Padding to avoid clipping the last card with the fading arrow
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'إعدادات الجدول',
                                  style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                tooltip: 'إغلاق',
                                onPressed: () {
                                  SmartDialog.dismiss(tag: 'custom_popover');
                                },
                              ),
                            ],
                          ),
                    const SizedBox(height: 12),
                    // Preview Area - reduced height
                    Container(
                      height: 90,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
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

                    // Controls (Compact side by side)
                    CanvasDialogHelpers.buildSettingsCard(
                      context: context,
                      isDarkMode: isDarkMode,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCompactCounter(
                              context, isDarkMode, 'الصفوف', Icons.table_rows_rounded, canvasCtrl.tableRows, 1, 10,
                              (v) { canvasCtrl.tableRows = v; canvasCtrl.notifyListeners(); setDialogState((){}); }
                            ),
                            Container(height: 40, width: 1, color: isDarkMode ? Colors.white12 : Colors.black12),
                            _buildCompactCounter(
                              context, isDarkMode, 'الأعمدة', Icons.view_column_rounded, canvasCtrl.tableCols, 1, 10,
                              (v) { canvasCtrl.tableCols = v; canvasCtrl.notifyListeners(); setDialogState((){}); }
                            ),
                          ],
                        ),
                      ]
                    ),

                    CanvasDialogHelpers.buildSettingsCard(
                      context: context,
                      isDarkMode: isDarkMode,
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 0),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'سمك الإطار',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  canvasCtrl.tableBorderWidth.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? const Color(0xFFFF7F6A) : Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 36, // Force smaller height for slider
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              overlayShape: SliderComponentShape.noOverlay, // Remove large invisible padding
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
                        ),
                      ],
                    ),

                    CanvasDialogHelpers.buildSettingsCard(
                      context: context,
                      isDarkMode: isDarkMode,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _buildCompactHeaderToggle(isDarkMode, 'صف الرأس', canvasCtrl.tableHeaderRow, (v) {
                                  canvasCtrl.tableHeaderRow = v; canvasCtrl.notifyListeners(); setDialogState((){});
                                }),
                              ),
                            ),
                            Container(height: 30, width: 1, color: isDarkMode ? Colors.white12 : Colors.black12),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _buildCompactHeaderToggle(isDarkMode, 'عمود الرأس', canvasCtrl.tableHeaderCol, (v) {
                                  canvasCtrl.tableHeaderCol = v; canvasCtrl.notifyListeners(); setDialogState((){});
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CanvasDialogHelpers.buildModernColorPicker(
                            context: context,
                            isDarkMode: isDarkMode,
                            setDialogState: setDialogState,
                            title: 'لون الإطار',
                            color: canvasCtrl.tableBorderColor,
                            canvasCtrl: canvasCtrl,
                            onColorChanged: (c) {
                              canvasCtrl.tableBorderColor = c;
                              canvasCtrl.notifyListeners();
                              setDialogState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CanvasDialogHelpers.buildModernColorPicker(
                            context: context,
                            isDarkMode: isDarkMode,
                            setDialogState: setDialogState,
                            title: 'التعبئة',
                            color: canvasCtrl.tableFillColor,
                            canvasCtrl: canvasCtrl,
                            onColorChanged: (c) {
                              canvasCtrl.tableFillColor = c;
                              canvasCtrl.notifyListeners();
                              setDialogState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ).animate().fade(duration: 200.ms).slideY(begin: 0.1, duration: 200.ms),
              ),
            ),
            ),
            
            // Fading down arrow indicator
            if (!isAtBottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          bgColor.withOpacity(0.0),
                          bgColor.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 20,
                        color: isDarkMode ? Colors.white30 : Colors.black38,
                      ),
                    ),
                  ),
                ),
              ),

          ],
        ),
      );
    },
  ); // Closes StatefulBuilder
}, // Closes bodyBuilder
); // Closes showCustomPopover
} // Closes showTableSettingsDialog method
} // Closes TableSettingsDialog class
