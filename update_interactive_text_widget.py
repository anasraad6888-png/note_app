import re

with open('lib/widgets/interactive_text_widget.dart', 'r') as f:
    code = f.read()

# 1. Inject _getEditorConfig
config_snippet = """class _InteractiveTextWidgetState extends State<InteractiveTextWidget> {

  quill.QuillEditorConfig _getEditorConfig(BuildContext context, {required bool isEditing}) {
    return quill.QuillEditorConfig(
      expands: true,
      showCursor: isEditing,
      customStyles: quill.DefaultStyles.getInstance(context).merge(
        quill.DefaultStyles(
          code: quill.DefaultTextBlockStyle(
            TextStyle(
              color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF333333),
              fontFamily: 'Roboto Mono',
              fontSize: 14,
            ),
            const quill.VerticalSpacing(4, 4),
            const quill.VerticalSpacing(0, 0),
            BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF26262A) : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
            ),
          ),
        ),
      ),
    );
  }"""
code = code.replace("class _InteractiveTextWidgetState extends State<InteractiveTextWidget> {", config_snippet, 1)

# 2. Add focus logic to initState
old_listener = """    _quillController.addListener(() {
      _lastFormatTime = DateTime.now().millisecondsSinceEpoch;
    });"""
new_listener = """    _quillController.addListener(() {
      _lastFormatTime = DateTime.now().millisecondsSinceEpoch;
      if (isEditing && !_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && isEditing && !_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    });"""
code = code.replace(old_listener, new_listener, 1)

old_start = """        widget.canvasCtrl?.startEditingText(widget.textData, _quillController, toggleInspector: _toggleTextInspector);
      });"""
new_start = """        widget.canvasCtrl?.startEditingText(widget.textData, _quillController, toggleInspector: _toggleTextInspector);
        if (mounted) _focusNode.requestFocus();
      });"""
code = code.replace(old_start, new_start, 1)

# 3. Update QuillEditor.basic config wrappers inside build
old_editor_true = """                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                                focusNode: _focusNode,
                                config: const quill.QuillEditorConfig(
                                  expands: true,
                                ),
                              ),"""
new_editor_true = """                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                                focusNode: _focusNode,
                                config: _getEditorConfig(context, isEditing: true),
                              ),"""
code = code.replace(old_editor_true, new_editor_true, 1)

old_editor_false = """                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                                focusNode: FocusNode(),
                                config: const quill.QuillEditorConfig(
                                  showCursor: false,
                                  expands: true,
                                ),
                              ),"""
new_editor_false = """                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                                focusNode: FocusNode(),
                                config: _getEditorConfig(context, isEditing: false),
                              ),"""
code = code.replace(old_editor_false, new_editor_false, 1)

# 4. ExcludeFocus and TextFieldTapRegion around the formatting toolbar
old_theme_block_start = """                                    Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Colors.transparent,
                                tooltipTheme: const TooltipThemeData(
                                  waitDuration: Duration(days: 365),
                                  showDuration: Duration.zero,
                                ),
                              ),
                              child: quill.QuillSimpleToolbar("""
new_theme_block_start = """                                  ExcludeFocus(
                                    child: TextFieldTapRegion(
                                      groupId: tapGroupId,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          canvasColor: Colors.transparent,
                                          tooltipTheme: const TooltipThemeData(
                                            waitDuration: Duration(days: 365),
                                            showDuration: Duration.zero,
                                          ),
                                        ),
                                        child: quill.QuillSimpleToolbar("""
code = code.replace(old_theme_block_start, new_theme_block_start, 1)

old_theme_block_end = """                                  showClipboardCut: false,
                                  showClipboardPaste: false,
                                ),
                              ),
                            ),
                                  ),
                                // Page 1: Box Decoration"""
new_theme_block_end = """                                  showClipboardCut: false,
                                  showClipboardPaste: false,
                                ),
                               ),
                              ),
                             ),
                            ),
                                  ),
                                // Page 1: Box Decoration"""
code = code.replace(old_theme_block_end, new_theme_block_end, 1)

# 5. Dropdowns wrappers
old_font_family = """                                    fontFamily: quill.QuillToolbarFontFamilyButtonOptions(
                                      initialValue: GoogleFonts.cairo().fontFamily!,
                                      defaultDisplayText: 'Cairo',
                                      items: {
                                        'Cairo': GoogleFonts.cairo().fontFamily!,
                                        'Amiri': GoogleFonts.amiri().fontFamily!,
                                        'Tajawal': GoogleFonts.tajawal().fontFamily!,
                                        'Changa': GoogleFonts.changa().fontFamily!,
                                        'Aref Ruqaa': GoogleFonts.arefRuqaa().fontFamily!,
                                        'Pacifico': GoogleFonts.pacifico().fontFamily!,
                                        'Roboto Mono': GoogleFonts.robotoMono().fontFamily!,
                                        'Rubik': GoogleFonts.rubik().fontFamily!,
                                      },
                                    ),"""
new_font_family = """                                                          fontFamily: quill.QuillToolbarFontFamilyButtonOptions(
                                                            initialValue: GoogleFonts.cairo().fontFamily!,
                                                            defaultDisplayText: 'Cairo',
                                                            items: {
                                                              'Cairo': GoogleFonts.cairo().fontFamily!,
                                                              'Amiri': GoogleFonts.amiri().fontFamily!,
                                                              'Tajawal': GoogleFonts.tajawal().fontFamily!,
                                                              'Changa': GoogleFonts.changa().fontFamily!,
                                                              'Aref Ruqaa': GoogleFonts.arefRuqaa().fontFamily!,
                                                              'Pacifico': GoogleFonts.pacifico().fontFamily!,
                                                              'Roboto Mono': GoogleFonts.robotoMono().fontFamily!,
                                                              'Rubik': GoogleFonts.rubik().fontFamily!,
                                                            },
                                                            childBuilder: (dynamic options, dynamic extra) {
                                                              return _ScopedMenuAnchor<MapEntry<String, String>>(
                                                                offset: const Offset(0, 40),
                                                                groupId: tapGroupId,
                                                                displayValue: extra.currentValue == 'Clear' ? 'الخط' : extra.currentValue,
                                                                items: (options.items as Map<String, String>? ?? {}).entries.toList(),
                                                                itemLabel: (e) => e.key,
                                                                itemStyle: (e) => TextStyle(fontFamily: e.value),
                                                                onSelected: (e) {
                                                                  extra.controller.formatSelection(quill.Attribute.fromKeyValue('font', e.value == 'Clear' ? null : e.value));
                                                                  options.onSelected?.call(e.value);
                                                                },
                                                              );
                                                            },
                                                          ),"""
code = code.replace(old_font_family, new_font_family, 1)

old_font_size = """                                    fontSize: const quill.QuillToolbarFontSizeButtonOptions(
                                      initialValue: '16',
                                      defaultDisplayText: '16',
                                      items: {
                                        '12': '12',
                                        '14': '14',
                                        '16': '16',
                                        '18': '18',
                                        '20': '20',
                                        '24': '24',
                                        '28': '28',
                                        '32': '32',
                                        '36': '36',
                                        '48': '48',
                                        '64': '64',
                                      },
                                    ),"""
new_font_size = """                                                          fontSize: quill.QuillToolbarFontSizeButtonOptions(
                                                                initialValue: '16',
                                                                defaultDisplayText: '16',
                                                                items: const {
                                                                  '12': '12', '14': '14', '16': '16', '18': '18', '20': '20',
                                                                  '24': '24', '28': '28', '32': '32', '36': '36', '48': '48', '64': '64',
                                                                },
                                                                childBuilder: (dynamic options, dynamic extra) {
                                                                  return _ScopedMenuAnchor<MapEntry<String, String>>(
                                                                    offset: const Offset(0, 40),
                                                                    groupId: tapGroupId,
                                                                    displayValue: extra.currentValue == 'Clear' ? '16' : extra.currentValue,
                                                                    items: (options.items as Map<String, String>? ?? {}).entries.toList(),
                                                                    itemLabel: (e) => e.key,
                                                                    onSelected: (e) {
                                                                      extra.controller.formatSelection(quill.Attribute.fromKeyValue('size', e.value == 'Clear' ? null : e.value));
                                                                      options.onSelected?.call(e.value);
                                                                    },
                                                                  );
                                                                },
                                                              ),"""
code = code.replace(old_font_size, new_font_size, 1)

# Adding selectHeaderDropdown to the toolbar
new_font_size = new_font_size + """
                                                          selectHeaderStyleDropdownButton: quill.QuillToolbarSelectHeaderStyleDropdownButtonOptions(
                                                                childBuilder: (dynamic options, dynamic extra) {
                                                                  final Map<quill.Attribute<dynamic>, String> headerItems = {
                                                                    quill.Attribute.h1: 'Header 1',
                                                                    quill.Attribute.h2: 'Header 2',
                                                                    quill.Attribute.h3: 'Header 3',
                                                                    quill.Attribute.header: 'Normal',
                                                                  };
                                                                  return _ScopedMenuAnchor<MapEntry<quill.Attribute<dynamic>, String>>(
                                                                    offset: const Offset(0, 40),
                                                                    groupId: tapGroupId,
                                                                    displayValue: 'العنوان',
                                                                    items: headerItems.entries.toList(),
                                                                    itemLabel: (e) => e.value,
                                                                    onSelected: (e) {
                                                                      extra.controller.formatSelection(e.key);
                                                                    },
                                                                  );
                                                                },
                                                              ),"""
code = code.replace(new_font_size.split("\n")[0], new_font_size, 1) if new_font_size in code else code

# Append classes
append_code = """
class _SlideFadeIn extends StatefulWidget {
  final Widget child;
  const _SlideFadeIn({required this.child});

  @override
  State<_SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<_SlideFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _controller, child: widget.child),
    );
  }
}

class _ScopedMenuAnchor<T> extends StatelessWidget {
  final Offset offset;
  final String groupId;
  final String displayValue;
  final List<T> items;
  final String Function(T) itemLabel;
  final TextStyle Function(T)? itemStyle;
  final void Function(T) onSelected;

  const _ScopedMenuAnchor({
    super.key,
    required this.offset,
    required this.groupId,
    required this.displayValue,
    required this.items,
    required this.itemLabel,
    this.itemStyle,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: const MenuStyle(
        maximumSize: WidgetStatePropertyAll<Size>(Size(double.infinity, 250)),
      ),
      alignmentOffset: offset,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(displayValue, maxLines: 1),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
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
"""

with open('lib/widgets/interactive_text_widget.dart', 'w') as f:
    f.write(code + append_code)

print("Update complete")
