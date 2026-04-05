import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../painters/canvas_painters.dart';
import '../../controllers/canvas_controller.dart';
import '../../widgets/custom_popover.dart';
import '../../models/canvas_models.dart';
import '../../models/note_document.dart';
import 'dialog_helpers.dart';
import 'dart:ui';
import '../pages_manager_dialog.dart';

class PageSettingsDialog {
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
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
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
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
                              ),
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: CupertinoSwitch(
                                  value: applyToAll,
                                  activeTrackColor: const Color(0xFFFF7F6A),
                                  inactiveTrackColor: isDarkMode ? Colors.white12 : Colors.grey.shade300,
                                  onChanged: (v) {
                                    applyToAll = v;
                                    updateTemplate(currentTemp);
                                  },
                                ),
                              ),
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
                            child: CanvasDialogHelpers.buildModernColorPicker(
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
                              child: CanvasDialogHelpers.buildModernColorPicker(
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
}
