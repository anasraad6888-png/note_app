import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../../models/canvas_models.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import '../pro_compact_color_picker.dart';
import '../../controllers/canvas_controller.dart';
import '../canvas_widgets/text_toolbar_dock.dart';
part 'interactive_text_inspector.dart';


class TextPreset {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Map<String, quill.Attribute> textAttributes;

  TextPreset({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.textAttributes,
  });
}

class InteractiveTextWidget extends StatefulWidget {
  final PageText textData;
  final bool readOnly;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final bool isDarkMode;
  final VoidCallback? onSelect;
  final CanvasController? canvasCtrl;

  const InteractiveTextWidget({
    super.key,
    required this.textData,
    required this.onSave,
    required this.onDelete,
    this.readOnly = false,
    this.isDarkMode = false,
    this.onSelect,
    this.canvasCtrl,
  });

  @override
  State<InteractiveTextWidget> createState() => _InteractiveTextWidgetState();
}

class _InteractiveTextWidgetState extends State<InteractiveTextWidget> with InteractiveTextInspectorMixin {
  quill.QuillEditorConfig _getEditorConfig(
    BuildContext context, {
    required bool isEditing,
  }) {
    return quill.QuillEditorConfig(
      expands: true,
      showCursor: isEditing,
      customStyles: quill.DefaultStyles.getInstance(context).merge(
        quill.DefaultStyles(
          code: quill.DefaultTextBlockStyle(
            TextStyle(
              color: widget.isDarkMode
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFF333333),
              fontFamily: 'Roboto Mono',
              fontSize: 14,
            ),
            const quill.HorizontalSpacing(0, 0),
            const quill.VerticalSpacing(4, 4),
            const quill.VerticalSpacing(0, 0),
            BoxDecoration(
              color: widget.isDarkMode
                  ? const Color(0xFF26262A)
                  : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          inlineCode: quill.InlineCodeStyle(
            backgroundColor: widget.isDarkMode ? const Color(0xFF26262A) : const Color(0xFFF1F1F1),
            radius: const Radius.circular(4),
            style: TextStyle(
              color: widget.isDarkMode ? const Color(0xFF5AB6FF) : const Color(0xFF0D47A1),
              fontFamily: 'Roboto Mono',
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    widget.canvasCtrl?.addListener(_onCanvasControllerChanged);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });

    if (widget.textData.deltaJson != null &&
        widget.textData.deltaJson!.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(
          jsonDecode(widget.textData.deltaJson!),
        );
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        final doc = widget.textData.text.isNotEmpty
            ? (quill.Document()..insert(0, widget.textData.text))
            : quill.Document();
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      final doc = widget.textData.text.isNotEmpty
          ? (quill.Document()..insert(0, widget.textData.text))
          : quill.Document();
      _quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    _quillController.readOnly = widget.readOnly;

    _quillController.document.changes.listen((_) {
      widget.textData.deltaJson = jsonEncode(
        _quillController.document.toDelta().toJson(),
      );
      widget.textData.text = _quillController.document.toPlainText();
    });

    _quillController.addListener(() {
      _lastFormatTime = DateTime.now().millisecondsSinceEpoch;
      if (isEditing && !_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && isEditing && !_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    });

    if (widget.textData.isEditing) {
      isSelected = true;
      isEditing = true;
      // Guarantee only the first evaluation bounds the element natively isolating logic locally
      widget.textData.isEditing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.canvasCtrl?.startEditingText(
          widget.textData,
          _quillController,
          toggleInspector: _toggleTextInspector,
        );
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _onCanvasControllerChanged() {
    if (isSelected || isEditing) {
      if (widget.canvasCtrl?.activeEditingText?.id != widget.textData.id) {
        if (mounted) {
          setState(() {
            isSelected = false;
            isEditing = false;
          });
          _removeInspectorOverlay();
          if (_quillController.document.toPlainText().trim().isEmpty) {
            widget.onDelete();
          } else {
            widget.onSave();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    widget.canvasCtrl?.removeListener(_onCanvasControllerChanged);
    _removeInspectorOverlay();
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateRect(double dx, double dy, bool isLeft, bool isTop) {
    setState(() {
      double newLeft = widget.textData.rect.left + (isLeft ? dx : 0);
      double newTop = widget.textData.rect.top + (isTop ? dy : 0);
      double newWidth = widget.textData.rect.width + (isLeft ? -dx : dx);
      double newHeight = widget.textData.rect.height + (isTop ? -dy : dy);

      if (newWidth < 100) {
        newWidth = 100;
        newLeft = widget.textData.rect.left;
      }
      if (newHeight < 50) {
        newHeight = 50;
        newTop = widget.textData.rect.top;
      }

      widget.textData.rect = Rect.fromLTWH(
        newLeft,
        newTop,
        newWidth,
        newHeight,
      );
    });
  }

  Widget _buildResizeHandle(Alignment alignment, bool isLeft, bool isTop) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) =>
            _updateRect(details.delta.dx, details.delta.dy, isLeft, isTop),
        onPanEnd: (_) => widget.onSave(),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String tapGroupId = 'text_box_${widget.textData.id}';
    // Provide plenty of bounds space to allow rotating safely
    final double parentWidth = math.max(
      widget.textData.rect.width + 150,
      450.0,
    );
    final double hOffset = (parentWidth - widget.textData.rect.width) / 2;
    const double topOffset =
        150; // Extra space above for toolbar + handle rotations

    return Positioned(
      key: ValueKey('text_pos_${widget.textData.id}'),
      left: widget.textData.rect.left - hOffset,
      top: widget.textData.rect.top - topOffset,
      width: parentWidth,
      height: widget.textData.rect.height + 300,
      child: Transform.rotate(
        angle: widget
            .textData
            .angle, // Entire interactive bounds rotates gracefully
        child: TapRegion(
          groupId: tapGroupId,
          onTapOutside: (_) async {
            if (TextToolbarDock.isMenuOpen) return;
            // Dropdowns & Dialogs push new routes. Ignore outside taps if a popup is active.
            if (ModalRoute.of(context)?.isCurrent != true) return;

            final tapTime = DateTime.now().millisecondsSinceEpoch;

            // Allow a brief window for floating Quill toolbar Dropdowns/Menus to process events
            await Future.delayed(const Duration(milliseconds: 200));
            if (!mounted) return;

            // If the Quill Controller was actively mutated around the time of the tap,
            // an unlinked overlay element (like the Headings dropdown) consumed the tap natively.
            if (_lastFormatTime > tapTime - 100) return;

            if (isSelected || isEditing) {
              setState(() {
                isSelected = false;
                isEditing = false;
              });
              if (widget.canvasCtrl?.activeEditingText?.id ==
                  widget.textData.id) {
                widget.canvasCtrl?.stopEditingText();
              }
              _removeInspectorOverlay();

              if (_quillController.document.toPlainText().trim().isEmpty) {
                widget.onDelete();
              } else {
                widget.onSave();
              }
            }
          },
          child: Container(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Text Box Container
                Positioned(
                  left: hOffset,
                  top: topOffset,
                  width: widget.textData.rect.width,
                  height: widget.textData.rect.height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isEditing
                        ? null
                        : () {
                            setState(() => isSelected = true);
                            widget.onSelect?.call();
                          },
                    onDoubleTap: isEditing
                        ? null
                        : () {
                            setState(() {
                              isSelected = true;
                              isEditing = true;
                            });
                            widget.onSelect?.call();
                            widget.canvasCtrl?.startEditingText(
                              widget.textData,
                              _quillController,
                              toggleInspector: _toggleTextInspector,
                            );
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.textData.fillColor,
                        borderRadius: BorderRadius.circular(
                          widget.textData.borderRadius,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue.withAlpha(150)
                              : widget.textData.borderColor,
                          width: isSelected
                              ? math.max(2.0, widget.textData.borderWidth)
                              : widget.textData.borderWidth,
                          style:
                              (isSelected ||
                                  widget.textData.borderColor !=
                                      Colors.transparent)
                              ? BorderStyle.solid
                              : BorderStyle.none,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: isEditing
                          ? TapRegion(
                              groupId: tapGroupId,
                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                                focusNode: _focusNode,
                                config: _getEditorConfig(
                                  context,
                                  isEditing: true,
                                ),
                              ),
                            )
                          : IgnorePointer(
                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                                focusNode: FocusNode(),
                                config: _getEditorConfig(
                                  context,
                                  isEditing: false,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                // Delete Button (Top Middle)
                if (isSelected && !widget.readOnly)
                  Positioned(
                    left: hOffset + (widget.textData.rect.width / 2) - 15,
                    top: topOffset - 35,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.canvasCtrl?.activeEditingText?.id ==
                            widget.textData.id) {
                          widget.canvasCtrl?.stopEditingText();
                        }
                        widget.onDelete();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Drag Handle (Top Left)
                if (isSelected && !widget.readOnly)
                  Positioned(
                    left: hOffset - 15,
                    top: topOffset - 15,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          // Standard pan offsets without applying complex rotational inverse scaling
                          // The easiest vector rotation formulation to translate globally regardless of Transform matrix:
                          double cosA = math.cos(widget.textData.angle);
                          double sinA = math.sin(widget.textData.angle);
                          // Inverse rotate the delta offset to apply local coordinates back to global canvas space properly:
                          double rotDX =
                              details.delta.dx * cosA - details.delta.dy * sinA;
                          double rotDY =
                              details.delta.dx * sinA + details.delta.dy * cosA;
                          widget.textData.rect = widget.textData.rect.shift(
                            Offset(rotDX, rotDY),
                          );
                        });
                      },
                      onPanEnd: (_) => widget.onSave(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Icon(
                          Icons.open_with,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),

                // Rotate Handle (Top Right)
                if (isSelected && !widget.readOnly)
                  Positioned(
                    left: hOffset + widget.textData.rect.width - 20,
                    top: topOffset - 15,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          // Simple angular drag (clockwise increasing angle based on dx moving right natively)
                          widget.textData.angle +=
                              (details.delta.dx * 0.01) +
                              (details.delta.dy * 0.01);
                        });
                      },
                      onPanEnd: (_) => widget.onSave(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Icon(
                          Icons.rotate_right,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),

                // Resize Handles (Bottom Only)
                if (isSelected && !widget.readOnly) ...[
                  Positioned(
                    left: hOffset - 7,
                    top: topOffset + widget.textData.rect.height - 7,
                    width: 14,
                    height: 14,
                    child: _buildResizeHandle(
                      Alignment.bottomLeft,
                      true,
                      false,
                    ),
                  ),
                  Positioned(
                    left: hOffset + widget.textData.rect.width - 7,
                    top: topOffset + widget.textData.rect.height - 7,
                    width: 14,
                    height: 14,
                    child: _buildResizeHandle(
                      Alignment.bottomRight,
                      false,
                      false,
                    ),
                  ),
                ],

                // Single Row Toolbar Native Injection above the rotation bindings smoothly
                if (isSelected && !widget.readOnly)
                  Positioned(
                    top:
                        topOffset -
                        90, // Places the layout cleanly above the boundaries handles
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ExcludeFocus(
                        child: TapRegion(
                          groupId: tapGroupId,
                          child: Container(
                          height: 55,
                          constraints: const BoxConstraints(
                            maxWidth: 250,
                          ), // Narrowed for inspector only
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? const Color(0xFF2C2C2E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white10
                                  : Colors.black12,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.isDarkMode
                                    ? Colors.black45
                                    : Colors.black12,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Custom Widget Stylization Bindings
                              IconButton(
                                tooltip: "لتحرير النص",
                                icon: Text(
                                  "Aa",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: widget.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                onPressed: () => _toggleTextInspector(initialTab: 0),
                              ),
                              Container(width: 1, height: 20, color: widget.isDarkMode ? Colors.white24 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
                              IconButton(
                                tooltip: "تنسيق الصندوق",
                                icon: Icon(LucideIcons.box, size: 20, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                onPressed: () => _toggleTextInspector(initialTab: 1),
                              ),
                              Container(width: 1, height: 20, color: widget.isDarkMode ? Colors.white24 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
                              IconButton(
                                tooltip: "الأنماط الجاهزة",
                                icon: Icon(LucideIcons.bookmark, size: 20, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                onPressed: () => _toggleTextInspector(initialTab: 2),
                              ),
                            ],
                          ),
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
    );
  }

}
