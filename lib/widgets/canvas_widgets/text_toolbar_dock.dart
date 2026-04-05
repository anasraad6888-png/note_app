import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/canvas_controller.dart';
import 'drawing_tools_row.dart';

class TextToolbarDock extends StatefulWidget {
  static bool isMenuOpen = false;
  final CanvasController canvasCtrl;

  const TextToolbarDock({super.key, required this.canvasCtrl});

  @override
  State<TextToolbarDock> createState() => _TextToolbarDockState();
}

class _TextToolbarDockState extends State<TextToolbarDock> {
  @override
  Widget build(BuildContext context) {
    if (widget.canvasCtrl.activeEditingText == null ||
        widget.canvasCtrl.activeQuillController == null) {
      return const SizedBox.shrink();
    }

    // The outer MainScreen Scaffold already avoids the keyboard (resizeToAvoidBottomInset: true),
    // so the inner DrawingCanvas body's bottom edge is already at the keyboard top.
    // We just need a small gap (8px) from the body bottom.
    final isDark = widget.canvasCtrl.isDarkMode;

    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: TapRegion(
        groupId: 'text_box_${widget.canvasCtrl.activeEditingText!.id}',
        child: TextFieldTapRegion(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xF026262A)
                        : const Color(0xF2FFFFFF),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withAlpha(120)
                            : Colors.black.withAlpha(40),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Font family & size ─────────────────────
                            _buildFontFamilyButton(isDark),
                            _buildFontSizeButton(isDark),
                            _buildDivider(isDark),
                            // ── Style toggles ──────────────────────────
                            _buildQuillButton(
                              icon: Icons.format_bold,
                              attr: quill.Attribute.bold,
                              tooltip: 'عريض',
                              isDark: isDark,
                            ),
                            _buildQuillButton(
                              icon: Icons.format_italic,
                              attr: quill.Attribute.italic,
                              tooltip: 'مائل',
                              isDark: isDark,
                            ),
                            _buildQuillButton(
                              icon: Icons.format_underline,
                              attr: quill.Attribute.underline,
                              tooltip: 'تحته خط',
                              isDark: isDark,
                            ),
                            _buildQuillButton(
                              icon: Icons.format_strikethrough,
                              attr: quill.Attribute.strikeThrough,
                              tooltip: 'يتوسطه خط',
                              isDark: isDark,
                            ),
                            _buildDivider(isDark),
                            // ── Colors ─────────────────────────────────
                            _buildColorButton(isBackground: false, isDark: isDark),
                            _buildColorButton(isBackground: true, isDark: isDark),
                            _buildDivider(isDark),
                            // ── Inspector & Done ───────────────────────
                            _buildIconBtn(
                              child: Text(
                                'Aa',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              tooltip: 'المفتش',
                              onTap: () =>
                                  widget.canvasCtrl.toggleTextInspector?.call(),
                            ),
                            const SizedBox(width: 4),
                            // Done (coral circle)
                            GestureDetector(
                              onTap: () =>
                                  widget.canvasCtrl.stopEditingText(),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7F6A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? Colors.white.withAlpha(45) : Colors.black12,
    );
  }

  Widget _buildIconBtn({
    required Widget child,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = const Color(0xFFFF7F6A),
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 30,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withAlpha(40)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: activeColor.withAlpha(80), width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _buildQuillButton({
    required IconData icon,
    required quill.Attribute attr,
    required String tooltip,
    required bool isDark,
  }) {
    final controller = widget.canvasCtrl.activeQuillController!;
    final isActive = controller
        .getSelectionStyle()
        .containsKey(attr.key);

    return _buildIconBtn(
      child: Icon(
        icon,
        size: 16,
        color: isActive
            ? const Color(0xFFFF7F6A)
            : (isDark ? Colors.white70 : Colors.black87),
      ),
      tooltip: tooltip,
      isActive: isActive,
      onTap: () {
        if (isActive) {
          controller.formatSelection(quill.Attribute.clone(attr, null));
        } else {
          controller.formatSelection(attr);
        }
      },
    );
  }

  Widget _buildColorButton({
    required bool isBackground,
    required bool isDark,
  }) {
    final controller = widget.canvasCtrl.activeQuillController!;
    final attr = controller
        .getSelectionStyle()
        .attributes[isBackground ? 'background' : 'color'];
    final currentColor = _parseQuillColor(
      attr?.value?.toString(),
      isDark,
      isBackground,
    );

    return Builder(
      builder: (ctx) => _buildIconBtn(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isBackground
                  ? Icons.format_color_fill
                  : Icons.format_color_text,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            Positioned(
              bottom: 2,
              child: Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: currentColor == Colors.transparent
                      ? (isDark ? Colors.white38 : Colors.black26)
                      : currentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        tooltip: isBackground ? 'لون الخلفية' : 'لون النص',
        onTap: () => _handleColorPickerRequest(controller, isBackground),
      ),
    );
  }

  Widget _buildFontFamilyButton(bool isDark) {
    return _UpwardMenuAnchor<MapEntry<String, String>>(
      offset: const Offset(0, -250),
      groupId: 'text_box_${widget.canvasCtrl.activeEditingText!.id}',
      displayValue: _currentFontLabel(),
      items: {
        'Cairo': GoogleFonts.cairo().fontFamily!,
        'Amiri': GoogleFonts.amiri().fontFamily!,
        'Tajawal': GoogleFonts.tajawal().fontFamily!,
        'Changa': GoogleFonts.changa().fontFamily!,
        'Aref Ruqaa': GoogleFonts.arefRuqaa().fontFamily!,
        'Pacifico': GoogleFonts.pacifico().fontFamily!,
        'Roboto Mono': GoogleFonts.robotoMono().fontFamily!,
        'Rubik': GoogleFonts.rubik().fontFamily!,
      }.entries.toList(),
      itemLabel: (e) => e.key,
      itemStyle: (e) => TextStyle(fontFamily: e.value),
      onSelected: (e) {
        widget.canvasCtrl.activeQuillController!.formatSelection(
          quill.Attribute.fromKeyValue('font', e.value),
        );
      },
      isDark: isDark,
    );
  }

  Widget _buildFontSizeButton(bool isDark) {
    return _UpwardMenuAnchor<MapEntry<String, String>>(
      offset: const Offset(0, -250),
      groupId: 'text_box_${widget.canvasCtrl.activeEditingText!.id}',
      displayValue: _currentFontSize(),
      items: ['12', '14', '16', '18', '20', '24', '28', '32', '36', '48', '64']
          .map((s) => MapEntry(s, s))
          .toList(),
      itemLabel: (e) => e.key,
      onSelected: (e) {
        widget.canvasCtrl.activeQuillController!.formatSelection(
          quill.Attribute.fromKeyValue('size', e.value),
        );
      },
      isDark: isDark,
    );
  }

  String _currentFontLabel() {
    final controller = widget.canvasCtrl.activeQuillController!;
    final attr = controller.getSelectionStyle().attributes['font'];
    if (attr == null || attr.value == null) return 'Cairo';
    final fontMap = {
      GoogleFonts.cairo().fontFamily!: 'Cairo',
      GoogleFonts.amiri().fontFamily!: 'Amiri',
      GoogleFonts.tajawal().fontFamily!: 'Tajawal',
      GoogleFonts.changa().fontFamily!: 'Changa',
      GoogleFonts.arefRuqaa().fontFamily!: 'Ruqaa',
      GoogleFonts.pacifico().fontFamily!: 'Pacifico',
      GoogleFonts.robotoMono().fontFamily!: 'Mono',
      GoogleFonts.rubik().fontFamily!: 'Rubik',
    };
    return fontMap[attr.value.toString()] ?? 'Cairo';
  }

  String _currentFontSize() {
    final controller = widget.canvasCtrl.activeQuillController!;
    final attr = controller.getSelectionStyle().attributes['size'];
    if (attr == null || attr.value == null) return '16';
    return attr.value.toString();
  }

  Color _parseQuillColor(
    String? colorString,
    bool isDarkMode,
    bool isBackground,
  ) {
    if (colorString == null || colorString.isEmpty) {
      return isBackground
          ? Colors.transparent
          : (isDarkMode ? Colors.white : Colors.black);
    }
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return isBackground
          ? Colors.transparent
          : (isDarkMode ? Colors.white : Colors.black);
    }
  }

  String _colorToQuillHex(Color color) {
    return '#${(color.value & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0')}';
  }

  Future<void> _handleColorPickerRequest(
    quill.QuillController controller,
    bool isBackground,
  ) async {
    final attr = controller
        .getSelectionStyle()
        .attributes[isBackground ? 'background' : 'color'];
    final currentColor = _parseQuillColor(
      attr?.value?.toString(),
      widget.canvasCtrl.isDarkMode,
      isBackground,
    );

    await showPopoverColorPicker(
      context: context,
      currentColor: currentColor,
      onColorChanged: (Color color) {
        if (color.a == 0 && isBackground) {
          controller.formatSelection(
            quill.Attribute.fromKeyValue('background', null),
          );
        } else {
          controller.formatSelection(
            quill.Attribute.fromKeyValue(
              isBackground ? 'background' : 'color',
              _colorToQuillHex(color),
            ),
          );
        }
      },
      onDelete: () {
        if (isBackground) {
          controller.formatSelection(
            quill.Attribute.fromKeyValue('background', null),
          );
        } else {
          controller.formatSelection(
            quill.Attribute.fromKeyValue('color', null),
          );
        }
      },
      canvasCtrl: widget.canvasCtrl,
    );

    // Asynchronously reclaim focus back to the text component after dialog finishes unmounting
    widget.canvasCtrl.forceTextFocusReclamation();
  }
}

class _UpwardMenuAnchor<T> extends StatelessWidget {
  final Offset offset;
  final String groupId;
  final String displayValue;
  final List<T> items;
  final String Function(T) itemLabel;
  final TextStyle Function(T)? itemStyle;
  final void Function(T) onSelected;
  final bool isDark;

  const _UpwardMenuAnchor({
    required this.offset,
    required this.groupId,
    required this.displayValue,
    required this.items,
    required this.itemLabel,
    this.itemStyle,
    required this.onSelected,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: const MenuStyle(
        maximumSize: WidgetStatePropertyAll<Size>(Size(double.infinity, 250)),
      ),
      alignmentOffset: offset, // Open upwards directly
      onOpen: () => TextToolbarDock.isMenuOpen = true,
      onClose: () => TextToolbarDock.isMenuOpen = false,
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayValue,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: items.map((item) {
        return TapRegion(
          groupId: groupId,
          child: MenuItemButton(
            onPressed: () => onSelected(item),
            child: Text(itemLabel(item), style: itemStyle?.call(item)),
          ),
        );
      }).toList(),
    );
  }
}
