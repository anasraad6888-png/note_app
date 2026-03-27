import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    return Positioned(
      bottom: 8, // The outer Scaffold's resize already puts us just above the keyboard
      left: 8,
      right: 8,
      child: TapRegion(
        groupId:
            'text_box_${widget.canvasCtrl.activeEditingText!.id}', // Link dynamically
        child: TextFieldTapRegion(
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: widget.canvasCtrl.isDarkMode
                    ? const Color(0xD926262A)
                    : const Color(0xE6F5F5F7),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: widget.canvasCtrl.isDarkMode
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: widget.canvasCtrl.isDarkMode
                      ? Colors.white10
                      : Colors.black12,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Formatting Toolbar (QuillSimpleToolbar)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: widget.canvasCtrl.isDarkMode
                              ? Colors.white10
                              : Colors.black12,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.transparent,
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: const Color(0xFFFF7F6A),
                          primaryContainer: const Color(
                            0xFFFF7F6A,
                          ).withValues(alpha: 0.2),
                          onPrimaryContainer: const Color(0xFFFF7F6A),
                          secondaryContainer: const Color(
                            0xFFFF7F6A,
                          ).withValues(alpha: 0.2),
                          onSecondaryContainer: const Color(0xFFFF7F6A),
                        ),
                        scrollbarTheme: const ScrollbarThemeData(
                          thickness: WidgetStatePropertyAll(0),
                        ),
                        tooltipTheme: const TooltipThemeData(
                          waitDuration: Duration(days: 365),
                          showDuration: Duration.zero,
                        ),
                      ),
                      child: ExcludeFocus(
                        child: quill.QuillSimpleToolbar(
                          controller: widget.canvasCtrl.activeQuillController!,
                          config: quill.QuillSimpleToolbarConfig(
                            iconTheme: quill.QuillIconTheme(
                              iconButtonSelectedData: quill.IconButtonData(
                                color: const Color(0xFFFF7F6A),
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    const Color(
                                      0xFFFF7F6A,
                                    ).withValues(alpha: 0.2),
                                  ),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              iconButtonUnselectedData: quill.IconButtonData(
                                color: widget.canvasCtrl.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                                style: ButtonStyle(
                                  backgroundColor: const WidgetStatePropertyAll(
                                    Colors.transparent,
                                  ),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            color: Colors.transparent,
                            multiRowsDisplay: false,
                            showFontFamily: true,
                            showFontSize: true,
                            buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                              color: quill.QuillToolbarColorButtonOptions(
                                customOnPressedCallback:
                                    _handleColorPickerRequest,
                              ),
                              backgroundColor:
                                  quill.QuillToolbarColorButtonOptions(
                                    customOnPressedCallback:
                                        _handleColorPickerRequest,
                                  ),
                              fontFamily: quill.QuillToolbarFontFamilyButtonOptions(
                                initialValue: GoogleFonts.cairo().fontFamily!,
                                defaultDisplayText: 'Cairo',
                                items: {
                                  'Cairo': GoogleFonts.cairo().fontFamily!,
                                  'Amiri': GoogleFonts.amiri().fontFamily!,
                                  'Tajawal': GoogleFonts.tajawal().fontFamily!,
                                  'Changa': GoogleFonts.changa().fontFamily!,
                                  'Aref Ruqaa':
                                      GoogleFonts.arefRuqaa().fontFamily!,
                                  'Pacifico':
                                      GoogleFonts.pacifico().fontFamily!,
                                  'Roboto Mono':
                                      GoogleFonts.robotoMono().fontFamily!,
                                  'Rubik': GoogleFonts.rubik().fontFamily!,
                                },
                                childBuilder: (dynamic options, dynamic extra) {
                                  return _UpwardMenuAnchor<
                                    MapEntry<String, String>
                                  >(
                                    offset: const Offset(0, -250),
                                    groupId:
                                        'text_box_${widget.canvasCtrl.activeEditingText!.id}',
                                    displayValue: extra.currentValue == 'Clear'
                                        ? 'الخط'
                                        : extra.currentValue,
                                    items:
                                        (options.items
                                                    as Map<String, String>? ??
                                                {})
                                            .entries
                                            .toList(),
                                    itemLabel: (e) => e.key,
                                    itemStyle: (e) =>
                                        TextStyle(fontFamily: e.value),
                                    onSelected: (e) {
                                      extra.controller.formatSelection(
                                        quill.Attribute.fromKeyValue(
                                          'font',
                                          e.value == 'Clear' ? null : e.value,
                                        ),
                                      );
                                      options.onSelected?.call(e.value);
                                    },
                                  );
                                },
                              ),
                              fontSize: quill.QuillToolbarFontSizeButtonOptions(
                                initialValue: '16',
                                defaultDisplayText: '16',
                                items: const {
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
                                childBuilder: (dynamic options, dynamic extra) {
                                  return _UpwardMenuAnchor<
                                    MapEntry<String, String>
                                  >(
                                    offset: const Offset(0, -250),
                                    groupId:
                                        'text_box_${widget.canvasCtrl.activeEditingText!.id}',
                                    displayValue: extra.currentValue == 'Clear'
                                        ? '16'
                                        : extra.currentValue,
                                    items:
                                        (options.items
                                                    as Map<String, String>? ??
                                                {})
                                            .entries
                                            .toList(),
                                    itemLabel: (e) => e.key,
                                    onSelected: (e) {
                                      extra.controller.formatSelection(
                                        quill.Attribute.fromKeyValue(
                                          'size',
                                          e.value == 'Clear' ? null : e.value,
                                        ),
                                      );
                                      options.onSelected?.call(e.value);
                                    },
                                  );
                                },
                              ),
                              selectHeaderStyleDropdownButton:
                                  quill.QuillToolbarSelectHeaderStyleDropdownButtonOptions(
                                    childBuilder: (dynamic options, dynamic extra) {
                                      final Map<
                                        quill.Attribute<dynamic>,
                                        String
                                      >
                                      headerItems = {
                                        quill.Attribute.h1: 'Header 1',
                                        quill.Attribute.h2: 'Header 2',
                                        quill.Attribute.h3: 'Header 3',
                                        quill.Attribute.header: 'Normal',
                                      };
                                      return _UpwardMenuAnchor<
                                        MapEntry<
                                          quill.Attribute<dynamic>,
                                          String
                                        >
                                      >(
                                        offset: const Offset(0, -180),
                                        groupId:
                                            'text_box_${widget.canvasCtrl.activeEditingText!.id}',
                                        displayValue: 'العنوان',
                                        items: headerItems.entries.toList(),
                                        itemLabel: (e) => e.value,
                                        onSelected: (e) {
                                          extra.controller.formatSelection(
                                            e.key,
                                          );
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
                                icon: const Text(
                                  'Aa',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                tooltip: 'المفتش',
                                onPressed: () {
                                  widget.canvasCtrl.toggleTextInspector?.call();
                                },
                              ),
                              quill.QuillToolbarCustomButtonOptions(
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF7F6A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                tooltip: 'تأكيد',
                                onPressed: () {
                                  widget.canvasCtrl.stopEditingText();
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
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

    await DrawingToolsRow.showPopoverColorPicker(
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
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                ), // Use standard downward icon since it's a menu
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
