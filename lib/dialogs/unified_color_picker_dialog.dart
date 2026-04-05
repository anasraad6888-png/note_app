import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/canvas_widgets/eyedropper_overlay.dart';
import '../widgets/pro_compact_color_picker.dart';

class UnifiedColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;
  final VoidCallback? onDelete;
  final GlobalKey? canvasRepaintKey;
  final VoidCallback? onPop;
  final bool isAddMode;
  final bool isRightHalf;
  final bool isLeftHalf;
  final bool isSpawnedBelow;

  const UnifiedColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.onDelete,
    this.canvasRepaintKey,
    this.onPop,
    this.isAddMode = false,
    this.isRightHalf = false,
    this.isLeftHalf = false,
    this.isSpawnedBelow = false,
  });

  @override
  State<UnifiedColorPickerDialog> createState() => _UnifiedColorPickerDialogState();
}

class _UnifiedColorPickerDialogState extends State<UnifiedColorPickerDialog> {
  Color? _selectedColor;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.isAddMode ? null : widget.initialColor;
  }

  void _updateColor(Color color) {
    if (mounted) {
      setState(() {
        _selectedColor = color;
      });
    }
    widget.onColorChanged(color);
  }

  void _closeDialog() {
    if (widget.onPop != null) {
      widget.onPop!();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // --- Helpers للمكونات المتكررة (DRY Principle) --- //

  Widget _buildEyedropperButton(bool isDarkMode) {
    if (widget.canvasRepaintKey == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(LucideIcons.pipette, size: 18, color: Color(0xFFFF7F6A)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'لقط لون من الشاشة',
      onPressed: () async {
        final canvasContext = widget.canvasRepaintKey?.currentContext;
        if (canvasContext == null) return;
        
        final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
        
        _closeDialog();
        await Future.delayed(const Duration(milliseconds: 200));

        if (canvasContext.mounted) {
          RenderRepaintBoundary boundary = canvasContext.findRenderObject() as RenderRepaintBoundary;
          ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

          if (canvasContext.mounted) {
            Color? pickedColor = await Navigator.of(canvasContext).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (context, _, _) => EyedropperOverlay(capturedImage: image),
              ),
            );

            // [تحسين أمني]: التخلص من الصورة من الذاكرة (RAM) بعد الانتهاء منها لمنع تسريب الذاكرة
            image.dispose();

            if (pickedColor != null) {
              _updateColor(pickedColor);
            }
          } else {
            image.dispose(); // في حال تم إغلاق الشاشة قبل فتح القطارة
          }
        }
      },
    );
  }

  Widget _buildDeleteButton() {
    if (widget.onDelete == null || _selectedColor == null) return const SizedBox.shrink();
    return Tooltip(
      message: 'حذف اللون',
      child: InkWell(
        onTap: () {
          widget.onDelete!();
          _closeDialog();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildCloseButton(bool isDarkMode) {
    return IconButton(
      icon: Icon(Icons.close, size: 18, color: isDarkMode ? Colors.white70 : Colors.black87),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'إغلاق',
      onPressed: _closeDialog,
    );
  }

  // --- بناء الشاشات --- //

  Widget _buildSmallGrid(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "لوحة الألوان",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEyedropperButton(isDarkMode),
                  _buildDeleteButton(),
                  IconButton(
                    icon: Icon(Icons.open_in_full, size: 16, color: isDarkMode ? Colors.white70 : Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'ألوان متقدمة',
                    onPressed: () => setState(() => _isExpanded = true),
                  ),
                  _buildCloseButton(isDarkMode), // [تحسين UX]: إضافة زر إغلاق سريع
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          // [تحسين أداء]: استخدام Wrap بدلاً من GridView لسرعة الرسم وتجنب مشاكل الحركة
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: ProCompactColorPicker.curatedColors.map((color) {
              final isSelected = _selectedColor?.value == color.value;
              return GestureDetector(
                onTap: () => _updateColor(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 24, // تحديد حجم ثابت يماثل الـ AspectRatio في الـ GridView السابقة
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : Colors.black.withOpacity(0.1),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ] : [],
                  ),
                  child: isSelected 
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                        size: 14,
                      )
                    : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLargePicker(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, size: 16, color: isDarkMode ? Colors.white70 : Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'عودة',
                    onPressed: () => setState(() => _isExpanded = false),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "محرر الألوان المتقدم",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEyedropperButton(isDarkMode),
                  _buildDeleteButton(),
                  _buildCloseButton(isDarkMode), // [تحسين UX]: إضافة زر إغلاق سريع هنا أيضاً
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(cardColor: Colors.transparent),
            child: SizedBox(
              height: 250,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ProCompactColorPicker(
                  pickerColor: _selectedColor ?? widget.initialColor,
                  onColorChanged: _updateColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Use View.of(context) to get the true physical screen size, ignoring overridden MediaQueries from nested Dialogs.
    final double screenWidth = MediaQueryData.fromView(View.of(context)).size.width;
    final double maxW = screenWidth - 32;
    
    final double targetLarge = math.min(550.0, maxW);
    final double targetSmall = math.min(340.0, maxW);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQueryData.fromView(View.of(context)).size.height * 0.70,
      ),
      child: SizedBox(
        width: targetLarge,
        child: Align(
          alignment: widget.isSpawnedBelow
              ? (widget.isRightHalf 
                  ? Alignment.topRight 
                  : (widget.isLeftHalf ? Alignment.topLeft : Alignment.topCenter))
              : (widget.isRightHalf 
                  ? Alignment.bottomRight 
                  : (widget.isLeftHalf ? Alignment.bottomLeft : Alignment.bottomCenter)),
          child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        width: _isExpanded ? targetLarge : targetSmall,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 400),
            firstCurve: Curves.easeOutQuart,
            secondCurve: Curves.easeOutQuart,
            sizeCurve: Curves.easeOutQuart,
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildSmallGrid(isDarkMode),
            secondChild: _buildLargePicker(isDarkMode),
          ),
        ),
          ),
        ),
      ),
    );
  }
}