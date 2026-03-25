import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/canvas_controller.dart';

class TextToolbarDock extends StatefulWidget {
  static bool isMenuOpen = false;
  final CanvasController canvasCtrl;

  const TextToolbarDock({
    super.key,
    required this.canvasCtrl,
  });

  @override
  State<TextToolbarDock> createState() => _TextToolbarDockState();
}

class _TextToolbarDockState extends State<TextToolbarDock> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Request focus safely after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.unfocus();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.canvasCtrl.activeEditingText == null || widget.canvasCtrl.activeQuillController == null) {
      return const SizedBox.shrink();
    }

    // Attach to keyboard properly safely at the bottom
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Positioned(
      bottom: bottomInset + 8, // Ensure it floats above keyboard
      left: 8,
      right: 8,
      child: TapRegion(
        groupId: 'text_box_${widget.canvasCtrl.activeEditingText!.id}', // Link dynamically
        child: Material(
          color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: widget.canvasCtrl.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.canvasCtrl.isDarkMode ? Colors.black54 : Colors.black26, 
                blurRadius: 10, 
                offset: const Offset(0, 4)
              )
            ],
            border: Border.all(color: widget.canvasCtrl.isDarkMode ? Colors.white10 : Colors.black12, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Formatting Toolbar (QuillSimpleToolbar)
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: widget.canvasCtrl.isDarkMode ? Colors.white10 : Colors.black12, width: 1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.transparent,
                    scrollbarTheme: const ScrollbarThemeData(
                      thickness: WidgetStatePropertyAll(0),
                    ),
                    tooltipTheme: const TooltipThemeData(
                      waitDuration: Duration(days: 365),
                      showDuration: Duration.zero,
                    ),
                  ),
                  child: quill.QuillSimpleToolbar(
                      controller: widget.canvasCtrl.activeQuillController!,
                      config: quill.QuillSimpleToolbarConfig(
                      color: Colors.transparent,
                      multiRowsDisplay: false,
                      showFontFamily: true,
                      showFontSize: true,
                      buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                        fontFamily: quill.QuillToolbarFontFamilyButtonOptions(
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
                            return _UpwardMenuAnchor<MapEntry<String, String>>(
                              offset: const Offset(0, -250),
                              groupId: 'text_box_${widget.canvasCtrl.activeEditingText!.id}',
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
                        ),
                        fontSize: quill.QuillToolbarFontSizeButtonOptions(
                          initialValue: '16',
                          defaultDisplayText: '16',
                          items: const {
                            '12': '12', '14': '14', '16': '16', '18': '18', '20': '20',
                            '24': '24', '28': '28', '32': '32', '36': '36', '48': '48', '64': '64',
                          },
                          childBuilder: (dynamic options, dynamic extra) {
                            return _UpwardMenuAnchor<MapEntry<String, String>>(
                              offset: const Offset(0, -250),
                              groupId: 'text_box_${widget.canvasCtrl.activeEditingText!.id}',
                              displayValue: extra.currentValue == 'Clear' ? '16' : extra.currentValue,
                              items: (options.items as Map<String, String>? ?? {}).entries.toList(),
                              itemLabel: (e) => e.key,
                              onSelected: (e) {
                                extra.controller.formatSelection(quill.Attribute.fromKeyValue('size', e.value == 'Clear' ? null : e.value));
                                options.onSelected?.call(e.value);
                              },
                            );
                          },
                        ),
                        selectHeaderStyleDropdownButton: quill.QuillToolbarSelectHeaderStyleDropdownButtonOptions(
                          childBuilder: (dynamic options, dynamic extra) {
                            final Map<quill.Attribute<dynamic>, String> headerItems = {
                              quill.Attribute.h1: 'Header 1',
                              quill.Attribute.h2: 'Header 2',
                              quill.Attribute.h3: 'Header 3',
                              quill.Attribute.header: 'Normal',
                            };
                            return _UpwardMenuAnchor<MapEntry<quill.Attribute<dynamic>, String>>(
                              offset: const Offset(0, -180),
                              groupId: 'text_box_${widget.canvasCtrl.activeEditingText!.id}',
                              displayValue: 'العنوان',
                              items: headerItems.entries.toList(),
                              itemLabel: (e) => e.value,
                              onSelected: (e) {
                                extra.controller.formatSelection(e.key);
                              },
                            );
                          },
                        ),
                      ),
                      showHeaderStyle: false,
                      showBoldButton: true,
                      showItalicButton: true,
                      showUnderLineButton: true,
                      showStrikeThrough: true,
                      showColorButton: true,
                      showBackgroundColorButton: true,
                      customButtons: [
                        quill.QuillToolbarCustomButtonOptions(
                          icon: const Text('Aa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          tooltip: 'المفتش',
                          onPressed: () {
                            widget.canvasCtrl.toggleTextInspector?.call();
                          },
                        ),
                      ],
                      showAlignmentButtons: false,
                      showLeftAlignment: false,
                      showCenterAlignment: false,
                      showRightAlignment: false,
                      showJustifyAlignment: false,
                      showListNumbers: false,
                      showListBullets: false,
                      showLink: false,
                      showClearFormat: false,
                      showCodeBlock: false,
                      showQuote: false,
                      showIndent: false,
                      showUndo: false,
                      showRedo: false,
                      showSearchButton: false,
                      showClipboardCopy: false,
                      showClipboardCut: false,
                      showClipboardPaste: false,
                    ),
                  ),
                ),
              ),
              
              // 2. Text Input Area
              Container(
                constraints: const BoxConstraints(maxHeight: 120, minHeight: 45),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: quill.QuillEditor.basic(
                        controller: widget.canvasCtrl.activeQuillController!,
                        focusNode: _focusNode,
                        config: quill.QuillEditorConfig(
                          expands: false,
                          padding: EdgeInsets.zero,
                          autoFocus: true,
                          placeholder: 'اكتب النص هنا...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action button to finish editing
                    IconButton(
                      icon: Icon(Icons.check_circle, color: Colors.blue, size: 28),
                      onPressed: () {
                        widget.canvasCtrl.stopEditingText();
                        // This removes focus because the widget disappears natively.
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
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

  const _UpwardMenuAnchor({
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(displayValue, maxLines: 1),
                const Icon(Icons.arrow_drop_down, size: 18), // Use standard downward icon since it's a menu
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
            child: Text(
              itemLabel(item),
              style: itemStyle?.call(item),
            ),
          ),
        );
      }).toList(),
    );
  }
}

