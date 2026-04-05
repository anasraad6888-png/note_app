import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'inspector_color_picker.dart';

class InspectorContent extends StatelessWidget {
  final int activeTab;
  final Function(int, {bool animate}) switchTab;
  final bool isDarkMode;
  final String? inlineColorType;
  final Function(String?) setInlineColorType;
  final VoidCallback onClose;
  final Widget editingTab;
  final Widget boxTab;
  final Widget presetsTab;
  final quill.QuillController quillController;
  final Offset? preExpansionPosition;
  final VoidCallback resetPreExpansionPosition;

  const InspectorContent({
    Key? key,
    required this.activeTab,
    required this.switchTab,
    required this.isDarkMode,
    required this.inlineColorType,
    required this.setInlineColorType,
    required this.onClose,
    required this.editingTab,
    required this.boxTab,
    required this.presetsTab,
    required this.quillController,
    required this.preExpansionPosition,
    required this.resetPreExpansionPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subColor = isDarkMode ? Colors.white54 : Colors.black45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ───────────────────────────────────────────────────
        Row(
          children: [
            // Drag handle dot
            Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: subColor,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              switch (activeTab) {
                1 => "تنسيق الصندوق",
                2 => "الأنماط",
                _ => "تنسيق النص",
              },
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            // ── Compact icon-only tabs ────────────────────────────
            _buildCompactTab(0, LucideIcons.type, 'تحرير'),
            const SizedBox(width: 2),
            _buildCompactTab(1, LucideIcons.box, 'صندوق'),
            const SizedBox(width: 2),
            _buildCompactTab(2, LucideIcons.bookmark, 'أنماط'),
            const SizedBox(width: 8),
            // Close button
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: subColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Content ───────────────────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: inlineColorType == null
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: SizedBox(
            height: 220,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey(activeTab),
                child: [editingTab, boxTab, presetsTab][activeTab],
              ),
            ),
          ),
          secondChild: SizedBox(
            height: 220,
            child: _buildColorPicker(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTab(int index, IconData icon, String tooltip) {
    final isActive = activeTab == index;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isActive
                ? (isDarkMode
                    ? const Color(0xFFFF7F6A).withAlpha(50)
                    : const Color(0xFFFF7F6A).withAlpha(30))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 13,
            color: isActive
                ? const Color(0xFFFF7F6A)
                : (isDarkMode ? Colors.white38 : Colors.black38),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Back header ───────────────────────────────────────────────
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setInlineColorType(null);
                resetPreExpansionPosition();
              },
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 13,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              inlineColorType == 'font' ? "لون النص" : "لون التمييز",
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                if (inlineColorType == 'font') {
                  quillController
                      .formatSelection(const quill.ColorAttribute(null));
                } else {
                  quillController
                      .formatSelection(const quill.BackgroundAttribute(null));
                }
                setInlineColorType(null);
                resetPreExpansionPosition();
              },
              child: Text(
                "شفاف",
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Color grid: fits exactly in the remaining window space ─────
        Expanded(
          child: Builder(
            builder: (context) {
              Color initialColor = isDarkMode ? Colors.white : Colors.black;
              try {
                final style = quillController.getSelectionStyle();
                final attr = inlineColorType == 'font'
                    ? style.attributes['color']?.value
                    : style.attributes['background']?.value;
                if (attr != null && attr is String) {
                  initialColor =
                      Color(int.parse(attr.replaceFirst('#', '0xFF')));
                }
              } catch (_) {}

              return InspectorColorPicker(
                  pickerColor: initialColor,
                  isDarkMode: isDarkMode,
                  onColorChanged: (color) {
                    final hex =
                        '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
                    if (inlineColorType == 'font') {
                      quillController
                          .formatSelection(quill.ColorAttribute(hex));
                    } else {
                      quillController
                          .formatSelection(quill.BackgroundAttribute(hex));
                    }
                  },
                );
            },
          ),
        ),
      ],
    );
  }
}

