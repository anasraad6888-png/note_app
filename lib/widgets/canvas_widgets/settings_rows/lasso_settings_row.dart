import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/canvas_controller.dart';

class LassoSettingsRow extends StatelessWidget {
  final CanvasController canvasCtrl;
  final bool reversed;
  final bool isVertical;

  const LassoSettingsRow({
    super.key,
    required this.canvasCtrl,
    this.reversed = false,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      _buildLassoIconToggle(LucideIcons.penTool, 'خطوط', canvasCtrl.lassoSelectHandwriting, (v) {
        canvasCtrl.lassoSelectHandwriting = v;
        canvasCtrl.notifyListeners();
      }, isVertical),
      _buildLassoIconToggle(LucideIcons.highlighter, 'تظليل', canvasCtrl.lassoSelectHighlighter, (v) {
        canvasCtrl.lassoSelectHighlighter = v;
        canvasCtrl.notifyListeners();
      }, isVertical),
      _buildLassoIconToggle(LucideIcons.image, 'صور', canvasCtrl.lassoSelectImages, (v) {
        canvasCtrl.lassoSelectImages = v;
        canvasCtrl.notifyListeners();
      }, isVertical),
      _buildLassoIconToggle(LucideIcons.type, 'نصوص', canvasCtrl.lassoSelectTexts, (v) {
        canvasCtrl.lassoSelectTexts = v;
        canvasCtrl.notifyListeners();
      }, isVertical),
      _buildLassoIconToggle(LucideIcons.square, 'أشكال', canvasCtrl.lassoSelectShapes, (v) {
        canvasCtrl.lassoSelectShapes = v;
        canvasCtrl.notifyListeners();
      }, isVertical),
      _buildLassoIconToggle(LucideIcons.table, 'جداول', canvasCtrl.lassoSelectTables, (v) {
        canvasCtrl.lassoSelectTables = v;
        canvasCtrl.notifyListeners();
      }, isVertical),
    ];
    return Flex(
      direction: isVertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      children: reversed ? children.reversed.toList() : children,
    );
  }

  static Widget _buildLassoIconToggle(
    IconData icon,
    String tooltip,
    bool isSelected,
    ValueChanged<bool> onChanged,
    bool isVertical,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVertical ? 0 : 4,
        vertical: isVertical ? 4 : 0,
      ),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => onChanged(!isSelected),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF7F6A).withAlpha(50) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: const Color(0xFFFF7F6A).withAlpha(100), width: 1) : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFFFF7F6A) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
