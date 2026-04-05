import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'inspector_helpers.dart';

class EditingTab extends StatelessWidget {
  final quill.QuillController quillController;
  final String tapGroupId;
  final bool isDarkMode;
  final String? inlineColorType;
  final Function(String?) setInlineColorType;
  final Function(Offset?) setPreExpansionPosition;
  final Offset? inspectorPosition;
  final Function(Offset) updateInspectorPosition;

  const EditingTab({
    Key? key,
    required this.quillController,
    required this.tapGroupId,
    required this.isDarkMode,
    required this.inlineColorType,
    required this.setInlineColorType,
    required this.setPreExpansionPosition,
    required this.inspectorPosition,
    required this.updateInspectorPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: ExcludeFocus(
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
              child: quill.QuillSimpleToolbar(
                controller: quillController,
                config: quill.QuillSimpleToolbarConfig(
                  color: Colors.transparent,
                  multiRowsDisplay: true,
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
                        return ScopedMenuAnchor<MapEntry<String, String>>(
                          offset: const Offset(0, 40),
                          groupId: tapGroupId,
                          displayValue: extra.currentValue == 'Clear' ? 'Cairo' : extra.currentValue,
                          items: (options.items as Map<String, String>? ?? {}).entries.toList(),
                          itemLabel: (e) => e.key,
                          itemStyle: (e) => TextStyle(fontFamily: e.value),
                          onSelected: (e) {
                            extra.controller.formatSelection(
                              quill.Attribute.fromKeyValue('font', e.value == 'Clear' ? null : e.value),
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
                        '12': '12', '14': '14', '16': '16', '18': '18',
                        '20': '20', '24': '24', '28': '28', '32': '32',
                        '36': '36', '48': '48', '64': '64',
                      },
                      childBuilder: (dynamic options, dynamic extra) {
                        return ScopedMenuAnchor<MapEntry<String, String>>(
                          offset: const Offset(0, 40),
                          groupId: tapGroupId,
                          displayValue: extra.currentValue == 'Clear' ? '16' : extra.currentValue,
                          items: (options.items as Map<String, String>? ?? {}).entries.toList(),
                          itemLabel: (e) => e.key,
                          onSelected: (e) {
                            extra.controller.formatSelection(
                              quill.Attribute.fromKeyValue('size', e.value == 'Clear' ? null : e.value),
                            );
                            options.onSelected?.call(e.value);
                          },
                        );
                      },
                    ),
                    color: quill.QuillToolbarColorButtonOptions(
                      customOnPressedCallback: (controller, isBackground) async {
                        if (inlineColorType != 'font') {
                          setInlineColorType('font');
                        } else {
                          setInlineColorType(null);
                        }
                      },
                    ),
                    backgroundColor: quill.QuillToolbarColorButtonOptions(
                      customOnPressedCallback: (controller, isBackground) async {
                        if (inlineColorType != 'background') {
                          setInlineColorType('background');
                        } else {
                          setInlineColorType(null);
                        }
                      },
                    ),
                  ),
                  showHeaderStyle: true,
                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showStrikeThrough: true,
                  showColorButton: true,
                  showBackgroundColorButton: true,
                  showAlignmentButtons: true,
                  showLeftAlignment: true,
                  showCenterAlignment: true,
                  showRightAlignment: true,
                  showJustifyAlignment: true,
                  showListNumbers: true,
                  showListBullets: true,
                  showLink: true,
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
        ),
      ),
    );
  }
}
