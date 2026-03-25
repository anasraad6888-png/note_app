import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../models/canvas_models.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'pro_compact_color_picker.dart';
import '../controllers/canvas_controller.dart';
import 'canvas_widgets/text_toolbar_dock.dart';
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

class _InteractiveTextWidgetState extends State<InteractiveTextWidget> {
  bool isSelected = false;
  bool isEditing = false;
  static List<TextPreset> savedPresets = [];
  late quill.QuillController _quillController;
  late FocusNode _focusNode;
  OverlayEntry? _inspectorOverlay;
  Offset? _inspectorPosition;
  int _lastFormatTime = 0;

  @override
  void initState() {
    super.initState();
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

    if (widget.textData.deltaJson != null && widget.textData.deltaJson!.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(widget.textData.deltaJson!));
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
      widget.textData.deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
      widget.textData.text = _quillController.document.toPlainText();
    });

    _quillController.addListener(() {
      _lastFormatTime = DateTime.now().millisecondsSinceEpoch;
    });

    if (widget.textData.isEditing) {
      isSelected = true;
      isEditing = true;
      // Guarantee only the first evaluation bounds the element natively isolating logic locally
      widget.textData.isEditing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.canvasCtrl?.startEditingText(widget.textData, _quillController, toggleInspector: _toggleTextInspector);
      });
    }
  }

  void _removeInspectorOverlay() {
    _inspectorOverlay?.remove();
    _inspectorOverlay = null;
  }

  @override
  void dispose() {
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

      widget.textData.rect = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
    });
  }

  Widget _buildResizeHandle(Alignment alignment, bool isLeft, bool isTop) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) => _updateRect(details.delta.dx, details.delta.dy, isLeft, isTop),
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
    final double parentWidth = math.max(widget.textData.rect.width + 150, 450.0);
    final double hOffset = (parentWidth - widget.textData.rect.width) / 2;
    const double topOffset = 150; // Extra space above for toolbar + handle rotations

    return Positioned(
      key: ValueKey('text_pos_${widget.textData.id}'),
      left: widget.textData.rect.left - hOffset,
      top: widget.textData.rect.top - topOffset,
      width: parentWidth,
      height: widget.textData.rect.height + 300,
      child: Transform.rotate(
        angle: widget.textData.angle, // Entire interactive bounds rotates gracefully
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
              if (widget.canvasCtrl?.activeEditingText?.id == widget.textData.id) {
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
                    onTap: isEditing ? null : () {
                      setState(() => isSelected = true);
                      widget.onSelect?.call();
                    },
                    onDoubleTap: isEditing ? null : () {
                      setState(() {
                        isSelected = true;
                        isEditing = true;
                      });
                      widget.onSelect?.call();
                      widget.canvasCtrl?.startEditingText(widget.textData, _quillController, toggleInspector: _toggleTextInspector);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.textData.fillColor,
                        borderRadius: BorderRadius.circular(widget.textData.borderRadius),
                        border: Border.all(
                          color: isSelected ? Colors.blue.withAlpha(150) : widget.textData.borderColor,
                          width: isSelected ? math.max(2.0, widget.textData.borderWidth) : widget.textData.borderWidth,
                          style: (isSelected || widget.textData.borderColor != Colors.transparent) ? BorderStyle.solid : BorderStyle.none,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: isEditing
                          ? TapRegion(
                              groupId: tapGroupId,
                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                                focusNode: _focusNode,
                                config: const quill.QuillEditorConfig(
                                  expands: true,
                                ),
                              ),
                            )
                          : IgnorePointer(
                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                                focusNode: FocusNode(),
                                config: const quill.QuillEditorConfig(
                                  showCursor: false,
                                  expands: true,
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
                        if (widget.canvasCtrl?.activeEditingText?.id == widget.textData.id) {
                          widget.canvasCtrl?.stopEditingText();
                        }
                        widget.onDelete();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
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
                          double rotDX = details.delta.dx * cosA - details.delta.dy * sinA;
                          double rotDY = details.delta.dx * sinA + details.delta.dy * cosA;
                          widget.textData.rect = widget.textData.rect.shift(Offset(rotDX, rotDY));
                        });
                      },
                      onPanEnd: (_) => widget.onSave(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.open_with, size: 16, color: Colors.blue),
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
                          widget.textData.angle += (details.delta.dx * 0.01) + (details.delta.dy * 0.01);
                        });
                      },
                      onPanEnd: (_) => widget.onSave(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.rotate_right, size: 18, color: Colors.orange),
                      ),
                    ),
                  ),

                // Resize Handles (Bottom Only)
                if (isSelected && !widget.readOnly) ...[
                  Positioned(left: hOffset - 7, top: topOffset + widget.textData.rect.height - 7, width: 14, height: 14, child: _buildResizeHandle(Alignment.bottomLeft, true, false)),
                  Positioned(left: hOffset + widget.textData.rect.width - 7, top: topOffset + widget.textData.rect.height - 7, width: 14, height: 14, child: _buildResizeHandle(Alignment.bottomRight, false, false)),
                ],

                // Single Row Toolbar Native Injection above the rotation bindings smoothly
                if (isSelected && !widget.readOnly)
                  Positioned(
                    top: topOffset - 90, // Places the layout cleanly above the boundaries handles
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TapRegion(
                        groupId: tapGroupId,
                        child: Container(
                          height: 55,
                          constraints: const BoxConstraints(maxWidth: 100), // Narrowed for inspector only
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12, width: 0.5),
                            boxShadow: [BoxShadow(color: widget.isDarkMode ? Colors.black45 : Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Custom Widget Stylization Bindings
                              IconButton(
                                tooltip: "المفتش",
                                icon: Text("Aa", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: widget.isDarkMode ? Colors.white : Colors.black87)),
                                onPressed: _toggleTextInspector,
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

  void _toggleTextInspector() {
    if (_inspectorOverlay != null) {
      _removeInspectorOverlay();
      return;
    }

    final size = MediaQuery.of(context).size;
    _inspectorPosition ??= Offset(
      size.width - 320 - 24, // Assuming inspector width ~320, padding 24
      120, // Below top toolbar
    );

    final String tapGroupId = 'text_box_${widget.textData.id}';
    int activeTab = 0;
    String? inlineColorType;
    Offset? preExpansionPosition;
    bool isDragging = false;
    final PageController pageController = PageController();

    _inspectorOverlay = OverlayEntry(
      builder: (context) {
        return AnimatedPositioned(
          duration: isDragging ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _inspectorPosition!.dx,
          top: _inspectorPosition!.dy,
          child: GestureDetector(
            onPanStart: (details) {
              isDragging = true;
              _inspectorOverlay?.markNeedsBuild();
            },
            onPanUpdate: (details) {
              _inspectorPosition = _inspectorPosition! + details.delta;
              if (inlineColorType != null) preExpansionPosition = null;
              _inspectorOverlay?.markNeedsBuild();
            },
            onPanEnd: (details) {
              isDragging = false;
              _inspectorOverlay?.markNeedsBuild();
            },
            onPanCancel: () {
              isDragging = false;
              _inspectorOverlay?.markNeedsBuild();
            },
            child: TapRegion(
              groupId: tapGroupId,
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: 340,
                          padding: const EdgeInsets.only(bottom: 24, top: 20, left: 24, right: 24),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? const Color(0xFF1E1E1E).withAlpha(180) : Colors.white.withAlpha(220),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: widget.isDarkMode ? Colors.white.withAlpha(30) : Colors.black.withAlpha(20)),
                            boxShadow: [
                               BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("تنسيق النص", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: widget.isDarkMode ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.close, size: 18, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        _removeInspectorOverlay();
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: inlineColorType == null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                            firstChild: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Segmented Control Tabs
                                Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? Colors.black.withAlpha(60) : Colors.black.withAlpha(15),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setOverlayState(() => activeTab = 0);
                                      pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: activeTab == 0 ? (widget.isDarkMode ? Colors.white24 : Colors.white) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: activeTab == 0 && !widget.isDarkMode ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.type, size: 14, color: activeTab == 0 ? Colors.blue : (widget.isDarkMode ? Colors.white54 : Colors.black54)),
                                          const SizedBox(width: 6),
                                          Text("التحرير", style: TextStyle(fontSize: 12, fontWeight: activeTab == 0 ? FontWeight.bold : FontWeight.w500, color: activeTab == 0 ? Colors.blue : (widget.isDarkMode ? Colors.white54 : Colors.black54))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setOverlayState(() => activeTab = 1);
                                      pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: activeTab == 1 ? (widget.isDarkMode ? Colors.white24 : Colors.white) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: activeTab == 1 && !widget.isDarkMode ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.box, size: 14, color: activeTab == 1 ? Colors.blue : (widget.isDarkMode ? Colors.white54 : Colors.black54)),
                                          const SizedBox(width: 6),
                                          Text("الصندوق", style: TextStyle(fontSize: 12, fontWeight: activeTab == 1 ? FontWeight.bold : FontWeight.w500, color: activeTab == 1 ? Colors.blue : (widget.isDarkMode ? Colors.white54 : Colors.black54))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setOverlayState(() => activeTab = 2);
                                      pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: activeTab == 2 ? (widget.isDarkMode ? Colors.white24 : Colors.white) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: activeTab == 2 && !widget.isDarkMode ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.bookmark, size: 14, color: activeTab == 2 ? Colors.blue : (widget.isDarkMode ? Colors.white54 : Colors.black54)),
                                          const SizedBox(width: 6),
                                          Text("الأنماط", style: TextStyle(fontSize: 12, fontWeight: activeTab == 2 ? FontWeight.bold : FontWeight.w500, color: activeTab == 2 ? Colors.blue : (widget.isDarkMode ? Colors.white54 : Colors.black54))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Swipable Content (PageView)
                          SizedBox(
                            height: 250,
                            child: PageView(
                              controller: pageController,
                              onPageChanged: (index) {
                                setOverlayState(() => activeTab = index);
                              },
                              children: [
                                // Page 0: Editing Toolbar
                                SingleChildScrollView(
                                  child: // New Tab 2 - Generic Editing Tools
                                    Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Colors.transparent,
                                tooltipTheme: const TooltipThemeData(
                                  waitDuration: Duration(days: 365),
                                  showDuration: Duration.zero,
                                ),
                              ),
                              child: quill.QuillSimpleToolbar(
                                controller: _quillController,
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
                                    ),
                                    fontSize: const quill.QuillToolbarFontSizeButtonOptions(
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
                                    ),
                                    color: quill.QuillToolbarColorButtonOptions(
                                      customOnPressedCallback: (controller, isBackground) async {
                                        setOverlayState(() {
                                          if (inlineColorType != 'font') {
                                            if (inlineColorType == null) {
                                              double screenHeight = MediaQuery.of(context).size.height;
                                              double expandedHeightEstimate = 600.0;
                                              if (_inspectorPosition!.dy + expandedHeightEstimate > screenHeight - 24) {
                                                preExpansionPosition ??= _inspectorPosition;
                                                double newDy = screenHeight - expandedHeightEstimate - 24;
                                                if (newDy < 24) newDy = 24.0;
                                                _inspectorPosition = Offset(_inspectorPosition!.dx, newDy);
                                              }
                                            }
                                            inlineColorType = 'font';
                                          } else {
                                            inlineColorType = null;
                                            if (preExpansionPosition != null) {
                                              _inspectorPosition = preExpansionPosition;
                                              preExpansionPosition = null;
                                            }
                                          }
                                        });
                                      },
                                    ),
                                    backgroundColor: quill.QuillToolbarColorButtonOptions(
                                      customOnPressedCallback: (controller, isBackground) async {
                                        setOverlayState(() {
                                          if (inlineColorType != 'background') {
                                            if (inlineColorType == null) {
                                              double screenHeight = MediaQuery.of(context).size.height;
                                              double expandedHeightEstimate = 600.0;
                                              if (_inspectorPosition!.dy + expandedHeightEstimate > screenHeight - 24) {
                                                preExpansionPosition ??= _inspectorPosition;
                                                double newDy = screenHeight - expandedHeightEstimate - 24;
                                                if (newDy < 24) newDy = 24.0;
                                                _inspectorPosition = Offset(_inspectorPosition!.dx, newDy);
                                              }
                                            }
                                            inlineColorType = 'background';
                                          } else {
                                            inlineColorType = null;
                                            if (preExpansionPosition != null) {
                                              _inspectorPosition = preExpansionPosition;
                                              preExpansionPosition = null;
                                            }
                                          }
                                        });
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
                                // Page 1: Box Decoration
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                          
                          // Container Color Grid
                          Text("لون الخلفية", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              Colors.transparent,
                              Colors.yellow.shade200, Colors.blue.shade100, Colors.green.shade100,
                              Colors.pink.shade100, Colors.purple.shade100, Colors.orange.shade100,
                            ].map((c) {
                              final isSelected = widget.textData.fillColor == c;
                               return GestureDetector(
                              onTap: () {
                                setState(() => widget.textData.fillColor = c);
                                setOverlayState(() {});
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(isSelected ? 16 : 10),
                                  border: Border.all(
                                    color: isSelected ? Colors.blue.withAlpha(150) : (widget.isDarkMode ? Colors.white24 : Colors.black12),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected && c != Colors.transparent ? [BoxShadow(color: c.withAlpha(100), blurRadius: 8, spreadRadius: 2)] : null,
                                ),
                                child: isSelected && c != Colors.transparent 
                                      ? Icon(Icons.check, size: 20, color: c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white) 
                                      : (c == Colors.transparent ? Icon(LucideIcons.ban, size: 20, color: widget.isDarkMode ? Colors.white54 : Colors.black54) : null),
                              ),
                            );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          
                          // Border Color Grid
                          Text("لون الإطار", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              Colors.transparent,
                              Colors.black, Colors.grey, Colors.blue, Colors.red, Colors.green, Colors.purple,
                            ].map((c) {
                              final isSelected = widget.textData.borderColor == c;
                              return GestureDetector(
                              onTap: () {
                                setState(() { 
                                  widget.textData.borderColor = c; 
                                  widget.textData.borderWidth = c == Colors.transparent ? 0 : 2.0; 
                                });
                                setOverlayState(() {});
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.blue.withAlpha(150) : (widget.isDarkMode ? Colors.white24 : Colors.black12),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected && c != Colors.transparent ? [BoxShadow(color: c.withAlpha(100), blurRadius: 8, spreadRadius: 2)] : null,
                                ),
                                child: isSelected && c != Colors.transparent 
                                      ? Icon(Icons.check, size: 20, color: c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white) 
                                      : (c == Colors.transparent ? Icon(LucideIcons.ban, size: 20, color: widget.isDarkMode ? Colors.white54 : Colors.black54) : null),
                              ),
                            );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Border Radius Slider
                          Row(
                            children: [
                              Text("الزوايا", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 6,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                                    activeTrackColor: Colors.blue,
                                    inactiveTrackColor: widget.isDarkMode ? Colors.white12 : Colors.black.withAlpha(15),
                                    thumbColor: Colors.blue,
                                  ),
                                  child: Slider(
                                  value: widget.textData.borderRadius,
                                  min: 0,
                                  max: 32,
                                  divisions: 8,
                                  onChanged: (val) {
                                    setState(() => widget.textData.borderRadius = val);
                                    setOverlayState(() {});
                                  },
                                ),
                                ),
                              ),
                            ],
                          ),
                                    ],
                                  ),
                                ),
                                // Page 2: Presets Config
                                SingleChildScrollView(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          final currentStyle = _quillController.getSelectionStyle();
                                          final newPreset = TextPreset(
                                            fillColor: widget.textData.fillColor,
                                            borderColor: widget.textData.borderColor,
                                            borderWidth: widget.textData.borderWidth,
                                            borderRadius: widget.textData.borderRadius,
                                            textAttributes: Map.from(currentStyle.attributes),
                                          );
                                          setState(() => _InteractiveTextWidgetState.savedPresets.add(newPreset));
                                          setOverlayState(() {});
                                        },
                                        icon: const Icon(Icons.bookmark_add, size: 16),
                                        label: const Text("حفظ التنسيق كنمط"),
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          backgroundColor: Colors.blue.withAlpha(150),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          minimumSize: const Size(double.infinity, 44),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (_InteractiveTextWidgetState.savedPresets.isEmpty)
                                        const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("لا توجد أنماط محفوظة", style: TextStyle(color: Colors.grey))))
                                      else
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: _InteractiveTextWidgetState.savedPresets.asMap().entries.map((entry) {
                                            final idx = entry.key;
                                            final preset = entry.value;
                                            return GestureDetector(
                                              onTap: () {
                                                if (!_quillController.selection.isCollapsed) {
                                                  // Apply only text configurations natively mapped onto selection
                                                  preset.textAttributes.forEach((key, attribute) {
                                                    _quillController.formatSelection(attribute);
                                                  });
                                                } else {
                                                  // Mutate bounding styles globally
                                                  setState(() {
                                                    widget.textData.fillColor = preset.fillColor;
                                                    widget.textData.borderColor = preset.borderColor;
                                                    widget.textData.borderWidth = preset.borderWidth;
                                                    widget.textData.borderRadius = preset.borderRadius;
                                                  });
                                                  // Broadcast pure text changes cross entire editor space
                                                  final fullDocLength = _quillController.document.length;
                                                  preset.textAttributes.forEach((key, attribute) {
                                                    _quillController.formatText(0, fullDocLength, attribute);
                                                  });
                                                }
                                                setOverlayState(() {});
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: preset.fillColor,
                                                  border: Border.all(
                                                    color: preset.borderColor == Colors.transparent ? (widget.isDarkMode ? Colors.white24 : Colors.black12) : preset.borderColor,
                                                    width: preset.borderWidth == 0 ? 1 : preset.borderWidth,
                                                  ),
                                                  borderRadius: BorderRadius.circular(preset.borderRadius == 0 ? 4 : preset.borderRadius),
                                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                                ),
                                                alignment: Alignment.center,
                                                child: Text("Aa", style: TextStyle(
                                                    fontFamily: preset.textAttributes['font']?.value?.toString(),
                                                    color: preset.textAttributes['color']?.value != null 
                                                        ? (preset.textAttributes['color']!.value is String ? Color(int.parse((preset.textAttributes['color']!.value as String).replaceFirst('#', '0xFF'))) : null)
                                                        : (preset.fillColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white),
                                                    fontWeight: preset.textAttributes['bold']?.value == true ? FontWeight.bold : FontWeight.w600,
                                                    fontStyle: preset.textAttributes['italic']?.value == true ? FontStyle.italic : FontStyle.normal,
                                                    fontSize: 16,
                                                )),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                              ],
                            ),
                            secondChild: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.arrow_back_ios_new, size: 16, color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          onPressed: () {
                                            setOverlayState(() {
                                              inlineColorType = null;
                                              if (preExpansionPosition != null) {
                                                _inspectorPosition = preExpansionPosition;
                                                preExpansionPosition = null;
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Text(inlineColorType == 'font' ? "لون النص" : "لون تمييز النص", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    TextButton.icon(
                                  icon: const Icon(LucideIcons.ban, size: 14),
                                  label: const Text("شفاف"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                    textStyle: const TextStyle(fontSize: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    if (inlineColorType == 'font') {
                                      _quillController.formatSelection(const quill.ColorAttribute(null));
                                    } else {
                                      _quillController.formatSelection(const quill.BackgroundAttribute(null));
                                    }
                                    setOverlayState(() {
                                      inlineColorType = null;
                                      if (preExpansionPosition != null) {
                                        _inspectorPosition = preExpansionPosition;
                                        preExpansionPosition = null;
                                      }
                                    });
                                  },
                                ),
                              ]
                            ),
                            const SizedBox(height: 8),
                            Builder(builder: (context) {
                              Color initialColor = widget.isDarkMode ? Colors.white : Colors.black;
                              try {
                                final style = _quillController.getSelectionStyle();
                                final attr = inlineColorType == 'font' ? style.attributes['color']?.value : style.attributes['background']?.value;
                                if (attr != null && attr is String) {
                                  initialColor = Color(int.parse(attr.replaceFirst('#', '0xFF')));
                                }
                              } catch (_) {}
                                return SizedBox(
                                  height: 340,
                                  child: SingleChildScrollView(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: ProCompactColorPicker(
                                      pickerColor: initialColor,
                                      onColorChanged: (color) {
                                        final hex = '#${color.value.toRadixString(16).padLeft(8, '0')}';
                                        if (inlineColorType == 'font') {
                                          _quillController.formatSelection(quill.ColorAttribute(hex));
                                        } else {
                                          _quillController.formatSelection(quill.BackgroundAttribute(hex));
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  },
);

    Overlay.of(context).insert(_inspectorOverlay!);
  }

}
