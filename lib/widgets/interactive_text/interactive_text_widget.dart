import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../../models/canvas_models.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../controllers/canvas_controller.dart';
import '../canvas_widgets/text_toolbar_dock.dart';
import '../canvas_widgets/drawing_tools_row.dart';
import 'inspector_tabs/editing_tab.dart';
import 'inspector_tabs/box_tab.dart';
import 'inspector_tabs/presets_tab.dart';
import 'inspector_tabs/inspector_overlay_frame.dart';
import 'inspector_tabs/inspector_content.dart';

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

      if (widget.textData.deltaJson == null || widget.textData.deltaJson!.isEmpty) {
        if (widget.textData.isBold) _quillController.formatSelection(quill.Attribute.bold);
        if (widget.textData.isItalic) _quillController.formatSelection(quill.Attribute.italic);
        if (widget.textData.isUnderline) _quillController.formatSelection(quill.Attribute.underline);
        if (widget.textData.isStrikethrough) _quillController.formatSelection(quill.Attribute.strikeThrough);
        
        final hexColor = '#${widget.textData.color.value.toRadixString(16).padLeft(8, '0')}';
        _quillController.formatSelection(quill.ColorAttribute(hexColor));
        _quillController.formatSelection(quill.SizeAttribute('${widget.textData.fontSize}'));
        
        if (widget.textData.textAlign == 'center') {
           _quillController.formatSelection(quill.Attribute.centerAlignment);
        } else if (widget.textData.textAlign == 'right') {
           _quillController.formatSelection(quill.Attribute.rightAlignment);
        } else if (widget.textData.textAlign == 'justify') {
           _quillController.formatSelection(quill.Attribute.justifyAlignment);
        } else if (widget.textData.textAlign == 'left') {
           _quillController.formatSelection(quill.Attribute.leftAlignment);
        }
      }
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
      _isInitializing = true;
      // Guarantee only the first evaluation bounds the element natively isolating logic locally
      widget.textData.isEditing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.canvasCtrl?.startEditingText(
          widget.textData,
          _quillController,
          toggleInspector: _toggleTextInspector,
          textContext: context,
        );
        if (mounted) {
          _isInitializing = false;
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _onCanvasControllerChanged() {
    if (_isInitializing) return;

    if (isEditing) {
      if (widget.canvasCtrl?.activeEditingText?.id != widget.textData.id) {
        if (mounted) {
          if (_focusNode.hasFocus) { _focusNode.unfocus(); }
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
      } else {
        // activeEditingText matches, ensuring physical text bounds didn't drop cursor
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      }
    } else if (isSelected) {
      // If purely selected, only forcefully deselect if another box actively enters edit mode
      if (widget.canvasCtrl?.activeEditingText != null && widget.canvasCtrl?.activeEditingText?.id != widget.textData.id) {
        if (mounted) {
          setState(() {
            isSelected = false;
          });
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
      height: widget.textData.rect.height + (topOffset * 2),
      child: Transform.rotate(
        angle: widget
            .textData
            .angle, // Entire interactive bounds rotates gracefully
        child: TapRegion(
          groupId: tapGroupId,
          onTapOutside: (_) async {
            if (TextToolbarDock.isMenuOpen) return;
            if (isColorPickerOpen) return;
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
              if (_focusNode.hasFocus) { _focusNode.unfocus(); }
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
                            if (widget.canvasCtrl?.isTextMode == true) {
                              setState(() {
                                isSelected = true;
                                isEditing = true;
                              });
                              // Start edit mode BEFORE bringing to front avoiding observer death
                              widget.canvasCtrl?.startEditingText(
                                widget.textData,
                                _quillController,
                                toggleInspector: _toggleTextInspector,
                                textContext: context,
                              );
                              widget.onSelect?.call();
                              if (mounted) _focusNode.requestFocus();
                            } else {
                              setState(() => isSelected = true);
                              widget.onSelect?.call();
                            }
                          },
                    onDoubleTap: isEditing
                        ? null
                        : () {
                            setState(() {
                              isSelected = true;
                              isEditing = true;
                            });
                            widget.canvasCtrl?.startEditingText(
                              widget.textData,
                              _quillController,
                              toggleInspector: _toggleTextInspector,
                              textContext: context,
                            );
                            widget.onSelect?.call();
                            if (mounted) _focusNode.requestFocus();
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
                      child: IgnorePointer(
                        ignoring: !isEditing,
                        child: TapRegion(
                          groupId: tapGroupId,
                          child: Directionality(
                            textDirection: widget.textData.textAlign == 'left'
                                ? TextDirection.ltr
                                : (widget.textData.textAlign == 'right'
                                    ? TextDirection.rtl
                                    : Directionality.of(context)),
                            child: quill.QuillEditor.basic(
                              controller: _quillController,
                              focusNode: _focusNode,
                              config: _getEditorConfig(
                                context,
                                isEditing: isEditing,
                              ),
                            ),
                          ),
                        ),
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
                      onPanStart: (details) {
                        final RenderBox? box = context.findRenderObject() as RenderBox?;
                        if (box != null) {
                          double cx = hOffset + (widget.textData.rect.width / 2);
                          double cy = topOffset + (widget.textData.rect.height / 2);
                          // We map the static center into exactly one fixed global screen coordinate 
                          _rotationPivotGlobal = box.localToGlobal(Offset(cx, cy));
                          _rotationStartAngle = widget.textData.angle;
                          
                          // Track the exact physical screen angle the finger grabbed at
                          _rotationStartPointerAngle = math.atan2(
                            details.globalPosition.dy - _rotationPivotGlobal!.dy,
                            details.globalPosition.dx - _rotationPivotGlobal!.dx,
                          );
                        }
                      },
                      onPanUpdate: (details) {
                        if (_rotationPivotGlobal != null) {
                          setState(() {
                            // Find the physical screen angle of where the finger moved to
                            double currentPointerAngle = math.atan2(
                              details.globalPosition.dy - _rotationPivotGlobal!.dy,
                              details.globalPosition.dx - _rotationPivotGlobal!.dx,
                            );
                            
                            // The true drag rotation angle is just the difference! Absolutely immune to local spin.
                            double deltaAngle = currentPointerAngle - _rotationStartPointerAngle;
                            
                            double rawAngle = _rotationStartAngle + deltaAngle;
                            
                            // Magnetic Snapping Logic (intervals of 90 degrees = pi / 2)
                            const double snapTolerance = 0.087; // Roughly 5 degrees tolerance
                            const double snapInterval = math.pi / 2;
                            
                            double closestSnap = (rawAngle / snapInterval).round() * snapInterval;
                            
                            if ((rawAngle - closestSnap).abs() < snapTolerance) {
                              widget.textData.angle = closestSnap;
                            } else {
                              widget.textData.angle = rawAngle;
                            }
                          });
                        }
                      },
                      onPanEnd: (_) {
                        _rotationPivotGlobal = null;
                        widget.onSave();
                      },
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

                // Vertical Side-Dock Toolbar Native Injection
                if (isSelected && !widget.readOnly)
                  Positioned(
                    // Tool height: 20(pad) + 32*3(btns) + 30(trash) + 6*4(gaps) + 12(gap) + 1*2(divs) = 184
                    top: topOffset + (widget.textData.rect.height / 2) - 92, 
                    left: (widget.textData.rect.center.dx + (-widget.textData.rect.width / 2 - 65) * math.cos(widget.textData.angle)) < 40
                        ? hOffset + widget.textData.rect.width + 25 // Flip to Right-Side structurally
                        : hOffset - 65, // Default Left-Side Dock
                    child: ExcludeFocus(
                      child: TapRegion(
                        groupId: tapGroupId,
                        child: Container(
                          width: 40, // Slim pill aesthetic
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ), // Vertical padding
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? const Color(0xFF2C2C2E).withAlpha(240) // Deep grey matching UI request
                                : Colors.white.withAlpha(240),           // Frosted white
                            borderRadius: BorderRadius.circular(30),     // Pill shape
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
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Text Format (Aa)
                              Tooltip(
                                message: "تنسيق النص",
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _toggleTextInspector(initialTab: 0),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    child: Transform.rotate(
                                      angle: -widget.textData.angle,
                                      child: Text(
                                        "Aa",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: widget.isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(height: 1, width: 20, color: widget.isDarkMode ? Colors.white24 : Colors.black12),
                              const SizedBox(height: 6),
                              
                              // Box Format (Cube)
                              Tooltip(
                                message: "تنسيق الصندوق",
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _toggleTextInspector(initialTab: 1),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    child: Transform.rotate(
                                      angle: -widget.textData.angle,
                                      child: Icon(LucideIcons.box, size: 18, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(height: 1, width: 20, color: widget.isDarkMode ? Colors.white24 : Colors.black12),
                              const SizedBox(height: 6),
                              
                              // Styles (Bookmark)
                              Tooltip(
                                message: "الأنماط الجاهزة",
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _toggleTextInspector(initialTab: 2),
                                  child: Container(
                                     width: 32,
                                     height: 32,
                                     alignment: Alignment.center,
                                     child: Transform.rotate(
                                       angle: -widget.textData.angle,
                                       child: Icon(LucideIcons.bookmark, size: 18, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                     ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Delete Button (Red Trash)
                              Tooltip(
                                message: "حذف الصندوق",
                                child: GestureDetector(
                                  onTap: () {
                                    if (widget.canvasCtrl?.activeEditingText?.id == widget.textData.id) {
                                      widget.canvasCtrl?.stopEditingText();
                                    }
                                    if (_focusNode.hasFocus) { _focusNode.unfocus(); }
                                    widget.onDelete();
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF4B4B), // Striking Red matching screenshot
                                      shape: BoxShape.circle,
                                    ),
                                    child: Transform.rotate(
                                      angle: -widget.textData.angle,
                                      child: const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

}
