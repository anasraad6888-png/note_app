part of 'interactive_text_widget.dart';

mixin InteractiveTextInspectorMixin on State<InteractiveTextWidget> {
  bool isSelected = false;
  bool isEditing = false;
  bool _isInitializing = false;
  static List<TextPreset> savedPresets = [];
  late quill.QuillController _quillController;
  late FocusNode _focusNode;
  OverlayEntry? _inspectorOverlay;
  int? _currentInspectorTab;
  PageController? _inspectorPageController;
  Offset? _inspectorPosition;
  int _lastFormatTime = 0;

  // Exact Absolute Rotation Tracking Anchors
  Offset? _rotationPivotGlobal;
  double _rotationStartAngle = 0;
  double _rotationStartPointerAngle = 0;

  void _removeInspectorOverlay() {
    _inspectorOverlay?.remove();
    _inspectorOverlay = null;
    _currentInspectorTab = null;
    _inspectorPageController?.dispose();
    _inspectorPageController = null;
    if (mounted && isEditing) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && isEditing) _focusNode.requestFocus();
      });
    }
  }

  void _toggleTextInspector({int initialTab = 0}) {
    if (_inspectorOverlay != null) {
      if (_currentInspectorTab == initialTab) {
        _removeInspectorOverlay();
        return;
      } else {
        _currentInspectorTab = initialTab;
        _inspectorPageController?.animateToPage(
          initialTab,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }
    }

    _currentInspectorTab = initialTab;

    final size = MediaQuery.of(context).size;
    _inspectorPosition ??= Offset(
      size.width - 320 - 24,
      120,
    );

    final String tapGroupId = 'text_box_${widget.textData.id}';
    int activeTab = initialTab;
    String? inlineColorType;
    Offset? preExpansionPosition;
    bool isDragging = false;
    _inspectorPageController = PageController(initialPage: initialTab);

    _inspectorOverlay = OverlayEntry(
      builder: (context) {
        return InspectorOverlayFrame(
          inspectorPosition: _inspectorPosition!,
          isDragging: isDragging,
          isDarkMode: widget.isDarkMode,
          activeTab: activeTab,
          onClose: () {
            _removeInspectorOverlay();
            setState(() {});
          },
          onPanStart: () {
            isDragging = true;
            _inspectorOverlay?.markNeedsBuild();
          },
          onPanUpdate: (delta) {
            _inspectorPosition = _inspectorPosition! + delta;
            if (inlineColorType != null) preExpansionPosition = null;
            _inspectorOverlay?.markNeedsBuild();
          },
          onPanEnd: () {
            isDragging = false;
            _inspectorOverlay?.markNeedsBuild();
          },
          tapGroupId: tapGroupId,
          child: StatefulBuilder(
            builder: (context, setOverlayState) {
              void switchTab(int index, {bool animate = true}) {
                setOverlayState(() => activeTab = index);
                if (mounted && isEditing) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted && isEditing) _focusNode.requestFocus();
                  });
                }
              }

              return InspectorContent(
                activeTab: activeTab,
                switchTab: switchTab,
                isDarkMode: widget.isDarkMode,
                inlineColorType: inlineColorType,
                setInlineColorType: (type) {
                  setOverlayState(() { inlineColorType = type; });
                },
                onClose: () {
                  _removeInspectorOverlay();
                  setState(() {});
                },
                editingTab: EditingTab(
                  quillController: _quillController,
                  tapGroupId: tapGroupId,
                  isDarkMode: widget.isDarkMode,
                  inlineColorType: inlineColorType,
                  setInlineColorType: (type) => setOverlayState(() { inlineColorType = type; }),
                  inspectorPosition: _inspectorPosition,
                  updateInspectorPosition: (pos) => setOverlayState(() { _inspectorPosition = pos; }),
                  setPreExpansionPosition: (pos) => setOverlayState(() { preExpansionPosition = pos; }),
                ),
                boxTab: BoxTab(
                  isDarkMode: widget.isDarkMode,
                  textData: widget.textData,
                  onDataChanged: () {
                    setState(() {});
                    setOverlayState(() {});
                  },
                ),
                presetsTab: PresetsTab(
                  quillController: _quillController,
                  textData: widget.textData,
                  isDarkMode: widget.isDarkMode,
                  savedPresets: InteractiveTextInspectorMixin.savedPresets,
                  onPresetSaved: (preset) {
                    setState(() {
                      InteractiveTextInspectorMixin.savedPresets.add(preset);
                    });
                    setOverlayState(() {});
                  },
                  onDataChanged: () {
                    setState(() {});
                    setOverlayState(() {});
                  },
                ),
                quillController: _quillController,
                preExpansionPosition: preExpansionPosition,
                resetPreExpansionPosition: () {
                   setOverlayState(() {
                      if (preExpansionPosition != null) {
                        _inspectorPosition = preExpansionPosition;
                        preExpansionPosition = null;
                      }
                   });
                },
              );
            },
          ),
        );
      },
    );

    Overlay.of(context).insert(_inspectorOverlay!);
    
    if (mounted && isEditing) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && isEditing) _focusNode.requestFocus();
      });
    }
  }
}
