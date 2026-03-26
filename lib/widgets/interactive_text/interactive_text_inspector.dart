part of 'interactive_text_widget.dart';

mixin InteractiveTextInspectorMixin on State<InteractiveTextWidget> {
  bool isSelected = false;
  bool isEditing = false;
  static List<TextPreset> savedPresets = [];
  late quill.QuillController _quillController;
  late FocusNode _focusNode;
  OverlayEntry? _inspectorOverlay;
  int? _currentInspectorTab;
  PageController? _inspectorPageController;
  Offset? _inspectorPosition;
  int _lastFormatTime = 0;

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
        // Toggle OFF (Close) if the exact same trigger was pressed
        _removeInspectorOverlay();
        return;
      } else {
        // Hot-Swap (Switch Tab) seamlessly by animating the PageView instead of unmounting
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
      size.width - 320 - 24, // Assuming inspector width ~320, padding 24
      120, // Below top toolbar
    );

    final String tapGroupId = 'text_box_${widget.textData.id}';
    int activeTab = initialTab;
    String? inlineColorType;
    Offset? preExpansionPosition;
    bool isDragging = false;
    _inspectorPageController = PageController(initialPage: initialTab);

    _inspectorOverlay = OverlayEntry(
      builder: (context) {
        return AnimatedPositioned(
          duration: isDragging
              ? Duration.zero
              : const Duration(milliseconds: 300),
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
                    void switchTab(int index, {bool animate = true}) {
                      setOverlayState(() => activeTab = index);
                      if (animate) {
                        _inspectorPageController?.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                      if (mounted && isEditing) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted && isEditing) _focusNode.requestFocus();
                        });
                      }
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: 340,
                          padding: const EdgeInsets.only(
                            bottom: 24,
                            top: 20,
                            left: 24,
                            right: 24,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? const Color(0xFF1E1E1E).withAlpha(180)
                                : Colors.white.withAlpha(220),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white.withAlpha(30)
                                  : Colors.black.withAlpha(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "تنسيق النص",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: widget.isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: widget.isDarkMode
                                            ? Colors.white.withAlpha(20)
                                            : Colors.black.withAlpha(10),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: widget.isDarkMode
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
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
                                  crossFadeState: inlineColorType == null
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  firstChild: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Segmented Control Tabs
                                      Container(
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: widget.isDarkMode
                                              ? Colors.black.withAlpha(60)
                                              : Colors.black.withAlpha(15),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => switchTab(0),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  margin: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: activeTab == 0
                                                        ? (widget.isDarkMode
                                                              ? Colors.white24
                                                              : Colors.white)
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    boxShadow:
                                                        activeTab == 0 &&
                                                            !widget.isDarkMode
                                                        ? [
                                                            const BoxShadow(
                                                              color: Colors
                                                                  .black12,
                                                              blurRadius: 4,
                                                              offset: Offset(
                                                                0,
                                                                2,
                                                              ),
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.type,
                                                        size: 14,
                                                        color: activeTab == 0
                                                            ? Colors.blue
                                                            : (widget.isDarkMode
                                                                  ? Colors
                                                                        .white54
                                                                  : Colors
                                                                        .black54),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "التحرير",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              activeTab == 0
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                          color: activeTab == 0
                                                              ? Colors.blue
                                                              : (widget.isDarkMode
                                                                    ? Colors
                                                                          .white54
                                                                    : Colors
                                                                          .black54),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => switchTab(1),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  margin: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: activeTab == 1
                                                        ? (widget.isDarkMode
                                                              ? Colors.white24
                                                              : Colors.white)
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    boxShadow:
                                                        activeTab == 1 &&
                                                            !widget.isDarkMode
                                                        ? [
                                                            const BoxShadow(
                                                              color: Colors
                                                                  .black12,
                                                              blurRadius: 4,
                                                              offset: Offset(
                                                                0,
                                                                2,
                                                              ),
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.box,
                                                        size: 14,
                                                        color: activeTab == 1
                                                            ? Colors.blue
                                                            : (widget.isDarkMode
                                                                  ? Colors
                                                                        .white54
                                                                  : Colors
                                                                        .black54),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "الصندوق",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              activeTab == 1
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                          color: activeTab == 1
                                                              ? Colors.blue
                                                              : (widget.isDarkMode
                                                                    ? Colors
                                                                          .white54
                                                                    : Colors
                                                                          .black54),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => switchTab(2),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  margin: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: activeTab == 2
                                                        ? (widget.isDarkMode
                                                              ? Colors.white24
                                                              : Colors.white)
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    boxShadow:
                                                        activeTab == 2 &&
                                                            !widget.isDarkMode
                                                        ? [
                                                            const BoxShadow(
                                                              color: Colors
                                                                  .black12,
                                                              blurRadius: 4,
                                                              offset: Offset(
                                                                0,
                                                                2,
                                                              ),
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.bookmark,
                                                        size: 14,
                                                        color: activeTab == 2
                                                            ? Colors.blue
                                                            : (widget.isDarkMode
                                                                  ? Colors
                                                                        .white54
                                                                  : Colors
                                                                        .black54),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "الأنماط",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              activeTab == 2
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                          color: activeTab == 2
                                                              ? Colors.blue
                                                              : (widget.isDarkMode
                                                                    ? Colors
                                                                          .white54
                                                                    : Colors
                                                                          .black54),
                                                        ),
                                                      ),
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
                                          controller: _inspectorPageController,
                                          onPageChanged: (index) => switchTab(index, animate: false),
                                          children: [
                                            // Page 0: Editing Toolbar
                                            SingleChildScrollView(
                                              child: // New Tab 2 - Generic Editing Tools
                                              ExcludeFocus(
                                                child: TextFieldTapRegion(
                                                  groupId: tapGroupId,
                                                  child: Theme(
                                                    data: Theme.of(context)
                                                        .copyWith(
                                                          canvasColor: Colors
                                                              .transparent,
                                                          tooltipTheme:
                                                              const TooltipThemeData(
                                                                waitDuration:
                                                                    Duration(
                                                                      days: 365,
                                                                    ),
                                                                showDuration:
                                                                    Duration
                                                                        .zero,
                                                              ),
                                                        ),
                                                    child: quill.QuillSimpleToolbar(
                                                      controller:
                                                          _quillController,
                                                      config: quill.QuillSimpleToolbarConfig(
                                                        color:
                                                            Colors.transparent,
                                                        multiRowsDisplay: true,
                                                        showFontFamily: true,
                                                        showFontSize: true,
                                                        buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                                                          fontFamily: quill.QuillToolbarFontFamilyButtonOptions(
                                                            initialValue:
                                                                GoogleFonts.cairo()
                                                                    .fontFamily!,
                                                            defaultDisplayText:
                                                                'Cairo',
                                                            items: {
                                                              'Cairo':
                                                                  GoogleFonts.cairo()
                                                                      .fontFamily!,
                                                              'Amiri':
                                                                  GoogleFonts.amiri()
                                                                      .fontFamily!,
                                                              'Tajawal':
                                                                  GoogleFonts.tajawal()
                                                                      .fontFamily!,
                                                              'Changa':
                                                                  GoogleFonts.changa()
                                                                      .fontFamily!,
                                                              'Aref Ruqaa':
                                                                  GoogleFonts.arefRuqaa()
                                                                      .fontFamily!,
                                                              'Pacifico':
                                                                  GoogleFonts.pacifico()
                                                                      .fontFamily!,
                                                              'Roboto Mono':
                                                                  GoogleFonts.robotoMono()
                                                                      .fontFamily!,
                                                              'Rubik':
                                                                  GoogleFonts.rubik()
                                                                      .fontFamily!,
                                                            },
                                                            childBuilder:
                                                                (
                                                                  dynamic
                                                                  options,
                                                                  dynamic extra,
                                                                ) {
                                                                  return _ScopedMenuAnchor<
                                                                    MapEntry<
                                                                      String,
                                                                      String
                                                                    >
                                                                  >(
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          40,
                                                                        ),
                                                                    groupId:
                                                                        tapGroupId,
                                                                    displayValue:
                                                                        extra.currentValue ==
                                                                            'Clear'
                                                                        ? 'الخط'
                                                                        : extra
                                                                              .currentValue,
                                                                    items:
                                                                        (options.items
                                                                                    as Map<
                                                                                      String,
                                                                                      String
                                                                                    >? ??
                                                                                {})
                                                                            .entries
                                                                            .toList(),
                                                                    itemLabel:
                                                                        (e) => e
                                                                            .key,
                                                                    itemStyle: (e) =>
                                                                        TextStyle(
                                                                          fontFamily:
                                                                              e.value,
                                                                        ),
                                                                    onSelected: (e) {
                                                                      extra.controller.formatSelection(
                                                                        quill
                                                                            .Attribute.fromKeyValue(
                                                                          'font',
                                                                          e.value ==
                                                                                  'Clear'
                                                                              ? null
                                                                              : e.value,
                                                                        ),
                                                                      );
                                                                      options
                                                                          .onSelected
                                                                          ?.call(
                                                                            e.value,
                                                                          );
                                                                    },
                                                                  );
                                                                },
                                                          ),
                                                          fontSize: quill.QuillToolbarFontSizeButtonOptions(
                                                            initialValue: '16',
                                                            defaultDisplayText:
                                                                '16',
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
                                                            childBuilder:
                                                                (
                                                                  dynamic
                                                                  options,
                                                                  dynamic extra,
                                                                ) {
                                                                  return _ScopedMenuAnchor<
                                                                    MapEntry<
                                                                      String,
                                                                      String
                                                                    >
                                                                  >(
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          40,
                                                                        ),
                                                                    groupId:
                                                                        tapGroupId,
                                                                    displayValue:
                                                                        extra.currentValue ==
                                                                            'Clear'
                                                                        ? '16'
                                                                        : extra
                                                                              .currentValue,
                                                                    items:
                                                                        (options.items
                                                                                    as Map<
                                                                                      String,
                                                                                      String
                                                                                    >? ??
                                                                                {})
                                                                            .entries
                                                                            .toList(),
                                                                    itemLabel:
                                                                        (e) => e
                                                                            .key,
                                                                    onSelected: (e) {
                                                                      extra.controller.formatSelection(
                                                                        quill
                                                                            .Attribute.fromKeyValue(
                                                                          'size',
                                                                          e.value ==
                                                                                  'Clear'
                                                                              ? null
                                                                              : e.value,
                                                                        ),
                                                                      );
                                                                      options
                                                                          .onSelected
                                                                          ?.call(
                                                                            e.value,
                                                                          );
                                                                    },
                                                                  );
                                                                },
                                                          ),
                                                          color: quill.QuillToolbarColorButtonOptions(
                                                            customOnPressedCallback:
                                                                (
                                                                  controller,
                                                                  isBackground,
                                                                ) async {
                                                                  setOverlayState(() {
                                                                    if (inlineColorType !=
                                                                        'font') {
                                                                      if (inlineColorType ==
                                                                          null) {
                                                                        double
                                                                        screenHeight = MediaQuery.of(
                                                                          context,
                                                                        ).size.height;
                                                                        double
                                                                        expandedHeightEstimate =
                                                                            600.0;
                                                                        if (_inspectorPosition!.dy +
                                                                                expandedHeightEstimate >
                                                                            screenHeight -
                                                                                24) {
                                                                          preExpansionPosition ??=
                                                                              _inspectorPosition;
                                                                          double
                                                                          newDy =
                                                                              screenHeight -
                                                                              expandedHeightEstimate -
                                                                              24;
                                                                          if (newDy <
                                                                              24)
                                                                            newDy =
                                                                                24.0;
                                                                          _inspectorPosition = Offset(
                                                                            _inspectorPosition!.dx,
                                                                            newDy,
                                                                          );
                                                                        }
                                                                      }
                                                                      inlineColorType =
                                                                          'font';
                                                                    } else {
                                                                      inlineColorType =
                                                                          null;
                                                                      if (preExpansionPosition !=
                                                                          null) {
                                                                        _inspectorPosition =
                                                                            preExpansionPosition;
                                                                        preExpansionPosition =
                                                                            null;
                                                                      }
                                                                    }
                                                                  });
                                                                },
                                                          ),
                                                          backgroundColor: quill.QuillToolbarColorButtonOptions(
                                                            customOnPressedCallback:
                                                                (
                                                                  controller,
                                                                  isBackground,
                                                                ) async {
                                                                  setOverlayState(() {
                                                                    if (inlineColorType !=
                                                                        'background') {
                                                                      if (inlineColorType ==
                                                                          null) {
                                                                        double
                                                                        screenHeight = MediaQuery.of(
                                                                          context,
                                                                        ).size.height;
                                                                        double
                                                                        expandedHeightEstimate =
                                                                            600.0;
                                                                        if (_inspectorPosition!.dy +
                                                                                expandedHeightEstimate >
                                                                            screenHeight -
                                                                                24) {
                                                                          preExpansionPosition ??=
                                                                              _inspectorPosition;
                                                                          double
                                                                          newDy =
                                                                              screenHeight -
                                                                              expandedHeightEstimate -
                                                                              24;
                                                                          if (newDy <
                                                                              24)
                                                                            newDy =
                                                                                24.0;
                                                                          _inspectorPosition = Offset(
                                                                            _inspectorPosition!.dx,
                                                                            newDy,
                                                                          );
                                                                        }
                                                                      }
                                                                      inlineColorType =
                                                                          'background';
                                                                    } else {
                                                                      inlineColorType =
                                                                          null;
                                                                      if (preExpansionPosition !=
                                                                          null) {
                                                                        _inspectorPosition =
                                                                            preExpansionPosition;
                                                                        preExpansionPosition =
                                                                            null;
                                                                      }
                                                                    }
                                                                  });
                                                                },
                                                          ),
                                                        ),
                                                        showHeaderStyle: true,
                                                        showBoldButton: true,
                                                        showItalicButton: true,
                                                        showUnderLineButton:
                                                            true,
                                                        showStrikeThrough: true,
                                                        showColorButton: true,
                                                        showBackgroundColorButton:
                                                            true,
                                                        showAlignmentButtons:
                                                            true,
                                                        showLeftAlignment: true,
                                                        showCenterAlignment:
                                                            true,
                                                        showRightAlignment:
                                                            true,
                                                        showJustifyAlignment:
                                                            true,
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
                                                        showClipboardCopy:
                                                            false,
                                                        showClipboardCut: false,
                                                        showClipboardPaste:
                                                            false,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Page 1: Box Decoration
                                            SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Container Color Grid
                                                  Text(
                                                    "لون الخلفية",
                                                    style: TextStyle(
                                                      color: widget.isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black87,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Wrap(
                                                    spacing: 12,
                                                    runSpacing: 12,
                                                    children:
                                                        [
                                                          Colors.transparent,
                                                          Colors
                                                              .yellow
                                                              .shade200,
                                                          Colors.blue.shade100,
                                                          Colors.green.shade100,
                                                          Colors.pink.shade100,
                                                          Colors
                                                              .purple
                                                              .shade100,
                                                          Colors
                                                              .orange
                                                              .shade100,
                                                        ].map((c) {
                                                          final isSelected =
                                                              widget
                                                                  .textData
                                                                  .fillColor ==
                                                              c;
                                                          return GestureDetector(
                                                            onTap: () {
                                                              setState(
                                                                () =>
                                                                    widget
                                                                            .textData
                                                                            .fillColor =
                                                                        c,
                                                              );
                                                              setOverlayState(
                                                                () {},
                                                              );
                                                            },
                                                            child: AnimatedContainer(
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        200,
                                                                  ),
                                                              width: 44,
                                                              height: 44,
                                                              decoration: BoxDecoration(
                                                                color: c,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      isSelected
                                                                          ? 16
                                                                          : 10,
                                                                    ),
                                                                border: Border.all(
                                                                  color:
                                                                      isSelected
                                                                      ? Colors
                                                                            .blue
                                                                            .withAlpha(
                                                                              150,
                                                                            )
                                                                      : (widget.isDarkMode
                                                                            ? Colors.white24
                                                                            : Colors.black12),
                                                                  width:
                                                                      isSelected
                                                                      ? 2
                                                                      : 1,
                                                                ),
                                                                boxShadow:
                                                                    isSelected &&
                                                                        c !=
                                                                            Colors.transparent
                                                                    ? [
                                                                        BoxShadow(
                                                                          color: c.withAlpha(
                                                                            100,
                                                                          ),
                                                                          blurRadius:
                                                                              8,
                                                                          spreadRadius:
                                                                              2,
                                                                        ),
                                                                      ]
                                                                    : null,
                                                              ),
                                                              child:
                                                                  isSelected &&
                                                                      c !=
                                                                          Colors
                                                                              .transparent
                                                                  ? Icon(
                                                                      Icons
                                                                          .check,
                                                                      size: 20,
                                                                      color:
                                                                          c.computeLuminance() >
                                                                              0.5
                                                                          ? Colors.black87
                                                                          : Colors.white,
                                                                    )
                                                                  : (c ==
                                                                            Colors.transparent
                                                                        ? Icon(
                                                                            LucideIcons.ban,
                                                                            size:
                                                                                20,
                                                                            color:
                                                                                widget.isDarkMode
                                                                                ? Colors.white54
                                                                                : Colors.black54,
                                                                          )
                                                                        : null),
                                                            ),
                                                          );
                                                        }).toList(),
                                                  ),
                                                  const SizedBox(height: 24),

                                                  // Border Color Grid
                                                  Text(
                                                    "لون الإطار",
                                                    style: TextStyle(
                                                      color: widget.isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black87,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Wrap(
                                                    spacing: 12,
                                                    runSpacing: 12,
                                                    children:
                                                        [
                                                          Colors.transparent,
                                                          Colors.black,
                                                          Colors.grey,
                                                          Colors.blue,
                                                          Colors.red,
                                                          Colors.green,
                                                          Colors.purple,
                                                        ].map((c) {
                                                          final isSelected =
                                                              widget
                                                                  .textData
                                                                  .borderColor ==
                                                              c;
                                                          return GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                widget
                                                                        .textData
                                                                        .borderColor =
                                                                    c;
                                                                widget
                                                                        .textData
                                                                        .borderWidth =
                                                                    c ==
                                                                        Colors
                                                                            .transparent
                                                                    ? 0
                                                                    : 2.0;
                                                              });
                                                              setOverlayState(
                                                                () {},
                                                              );
                                                            },
                                                            child: AnimatedContainer(
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        200,
                                                                  ),
                                                              width: 44,
                                                              height: 44,
                                                              decoration: BoxDecoration(
                                                                color: c,
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                  color:
                                                                      isSelected
                                                                      ? Colors
                                                                            .blue
                                                                            .withAlpha(
                                                                              150,
                                                                            )
                                                                      : (widget.isDarkMode
                                                                            ? Colors.white24
                                                                            : Colors.black12),
                                                                  width:
                                                                      isSelected
                                                                      ? 2
                                                                      : 1,
                                                                ),
                                                                boxShadow:
                                                                    isSelected &&
                                                                        c !=
                                                                            Colors.transparent
                                                                    ? [
                                                                        BoxShadow(
                                                                          color: c.withAlpha(
                                                                            100,
                                                                          ),
                                                                          blurRadius:
                                                                              8,
                                                                          spreadRadius:
                                                                              2,
                                                                        ),
                                                                      ]
                                                                    : null,
                                                              ),
                                                              child:
                                                                  isSelected &&
                                                                      c !=
                                                                          Colors
                                                                              .transparent
                                                                  ? Icon(
                                                                      Icons
                                                                          .check,
                                                                      size: 20,
                                                                      color:
                                                                          c.computeLuminance() >
                                                                              0.5
                                                                          ? Colors.black87
                                                                          : Colors.white,
                                                                    )
                                                                  : (c ==
                                                                            Colors.transparent
                                                                        ? Icon(
                                                                            LucideIcons.ban,
                                                                            size:
                                                                                20,
                                                                            color:
                                                                                widget.isDarkMode
                                                                                ? Colors.white54
                                                                                : Colors.black54,
                                                                          )
                                                                        : null),
                                                            ),
                                                          );
                                                        }).toList(),
                                                  ),
                                                  const SizedBox(height: 24),

                                                  // Border Radius Slider
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "الزوايا",
                                                        style: TextStyle(
                                                          color:
                                                              widget.isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black87,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: SliderTheme(
                                                          data: SliderTheme.of(context).copyWith(
                                                            trackHeight: 6,
                                                            thumbShape:
                                                                const RoundSliderThumbShape(
                                                                  enabledThumbRadius:
                                                                      10,
                                                                ),
                                                            overlayShape:
                                                                const RoundSliderOverlayShape(
                                                                  overlayRadius:
                                                                      20,
                                                                ),
                                                            activeTrackColor:
                                                                Colors.blue,
                                                            inactiveTrackColor:
                                                                widget
                                                                    .isDarkMode
                                                                ? Colors.white12
                                                                : Colors.black
                                                                      .withAlpha(
                                                                        15,
                                                                      ),
                                                            thumbColor:
                                                                Colors.blue,
                                                          ),
                                                          child: Slider(
                                                            value: widget
                                                                .textData
                                                                .borderRadius,
                                                            min: 0,
                                                            max: 32,
                                                            divisions: 8,
                                                            onChanged: (val) {
                                                              setState(
                                                                () =>
                                                                    widget
                                                                            .textData
                                                                            .borderRadius =
                                                                        val,
                                                              );
                                                              setOverlayState(
                                                                () {},
                                                              );
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
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      final currentStyle =
                                                          _quillController
                                                              .getSelectionStyle();
                                                      final newPreset =
                                                          TextPreset(
                                                            fillColor: widget
                                                                .textData
                                                                .fillColor,
                                                            borderColor: widget
                                                                .textData
                                                                .borderColor,
                                                            borderWidth: widget
                                                                .textData
                                                                .borderWidth,
                                                            borderRadius: widget
                                                                .textData
                                                                .borderRadius,
                                                            textAttributes:
                                                                Map.from(
                                                                  currentStyle
                                                                      .attributes,
                                                                ),
                                                          );
                                                      setState(
                                                        () =>
                                                            InteractiveTextInspectorMixin
                                                                .savedPresets
                                                                .add(newPreset),
                                                      );
                                                      setOverlayState(() {});
                                                    },
                                                    icon: const Icon(
                                                      Icons.bookmark_add,
                                                      size: 16,
                                                    ),
                                                    label: const Text(
                                                      "حفظ التنسيق كنمط",
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      elevation: 0,
                                                      backgroundColor: Colors
                                                          .blue
                                                          .withAlpha(150),
                                                      foregroundColor:
                                                          Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                      ),
                                                      minimumSize: const Size(
                                                        double.infinity,
                                                        44,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  if (InteractiveTextInspectorMixin
                                                      .savedPresets
                                                      .isEmpty)
                                                    const Center(
                                                      child: Padding(
                                                        padding: EdgeInsets.all(
                                                          16.0,
                                                        ),
                                                        child: Text(
                                                          "لا توجد أنماط محفوظة",
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    Wrap(
                                                      spacing: 12,
                                                      runSpacing: 12,
                                                      children: InteractiveTextInspectorMixin.savedPresets.asMap().entries.map((
                                                        entry,
                                                      ) {
                                                        final idx = entry.key;
                                                        final preset =
                                                            entry.value;
                                                        return GestureDetector(
                                                          onTap: () {
                                                            if (!_quillController
                                                                .selection
                                                                .isCollapsed) {
                                                              // Apply only text configurations natively mapped onto selection
                                                              preset.textAttributes.forEach((
                                                                key,
                                                                attribute,
                                                              ) {
                                                                _quillController
                                                                    .formatSelection(
                                                                      attribute,
                                                                    );
                                                              });
                                                            } else {
                                                              // Mutate bounding styles globally
                                                              setState(() {
                                                                widget
                                                                    .textData
                                                                    .fillColor = preset
                                                                    .fillColor;
                                                                widget
                                                                    .textData
                                                                    .borderColor = preset
                                                                    .borderColor;
                                                                widget
                                                                    .textData
                                                                    .borderWidth = preset
                                                                    .borderWidth;
                                                                widget
                                                                    .textData
                                                                    .borderRadius = preset
                                                                    .borderRadius;
                                                              });
                                                              // Broadcast pure text changes cross entire editor space
                                                              final fullDocLength =
                                                                  _quillController
                                                                      .document
                                                                      .length;
                                                              preset.textAttributes.forEach((
                                                                key,
                                                                attribute,
                                                              ) {
                                                                _quillController
                                                                    .formatText(
                                                                      0,
                                                                      fullDocLength,
                                                                      attribute,
                                                                    );
                                                              });
                                                            }
                                                            setOverlayState(
                                                              () {},
                                                            );
                                                          },
                                                          child: AnimatedContainer(
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      200,
                                                                ),
                                                            width: 50,
                                                            height: 50,
                                                            decoration: BoxDecoration(
                                                              color: preset
                                                                  .fillColor,
                                                              border: Border.all(
                                                                color:
                                                                    preset.borderColor ==
                                                                        Colors
                                                                            .transparent
                                                                    ? (widget.isDarkMode
                                                                          ? Colors.white24
                                                                          : Colors.black12)
                                                                    : preset
                                                                          .borderColor,
                                                                width:
                                                                    preset.borderWidth ==
                                                                        0
                                                                    ? 1
                                                                    : preset
                                                                          .borderWidth,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    preset.borderRadius ==
                                                                            0
                                                                        ? 4
                                                                        : preset
                                                                              .borderRadius,
                                                                  ),
                                                              boxShadow: const [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black12,
                                                                  blurRadius: 4,
                                                                  offset:
                                                                      Offset(
                                                                        0,
                                                                        2,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              "Aa",
                                                              style: TextStyle(
                                                                fontFamily: preset
                                                                    .textAttributes['font']
                                                                    ?.value
                                                                    ?.toString(),
                                                                color:
                                                                    preset
                                                                            .textAttributes['color']
                                                                            ?.value !=
                                                                        null
                                                                    ? (preset.textAttributes['color']!.value
                                                                              is String
                                                                          ? Color(
                                                                              int.parse(
                                                                                (preset.textAttributes['color']!.value
                                                                                        as String)
                                                                                    .replaceFirst(
                                                                                      '#',
                                                                                      '0xFF',
                                                                                    ),
                                                                              ),
                                                                            )
                                                                          : null)
                                                                    : (preset.fillColor.computeLuminance() >
                                                                              0.5
                                                                          ? Colors.black87
                                                                          : Colors.white),
                                                                fontWeight:
                                                                    preset
                                                                            .textAttributes['bold']
                                                                            ?.value ==
                                                                        true
                                                                    ? FontWeight
                                                                          .bold
                                                                    : FontWeight
                                                                          .w600,
                                                                fontStyle:
                                                                    preset
                                                                            .textAttributes['italic']
                                                                            ?.value ==
                                                                        true
                                                                    ? FontStyle
                                                                          .italic
                                                                    : FontStyle
                                                                          .normal,
                                                                fontSize: 16,
                                                              ),
                                                            ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.arrow_back_ios_new,
                                                  size: 16,
                                                  color: widget.isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                onPressed: () {
                                                  setOverlayState(() {
                                                    inlineColorType = null;
                                                    if (preExpansionPosition !=
                                                        null) {
                                                      _inspectorPosition =
                                                          preExpansionPosition;
                                                      preExpansionPosition =
                                                          null;
                                                    }
                                                  });
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                inlineColorType == 'font'
                                                    ? "لون النص"
                                                    : "لون تمييز النص",
                                                style: TextStyle(
                                                  color: widget.isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            icon: const Icon(
                                              LucideIcons.ban,
                                              size: 14,
                                            ),
                                            label: const Text("شفاف"),
                                            style: TextButton.styleFrom(
                                              foregroundColor: widget.isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black54,
                                              textStyle: const TextStyle(
                                                fontSize: 12,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 0,
                                                  ),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              minimumSize: Size.zero,
                                            ),
                                            onPressed: () {
                                              if (inlineColorType == 'font') {
                                                _quillController.formatSelection(
                                                  const quill.ColorAttribute(
                                                    null,
                                                  ),
                                                );
                                              } else {
                                                _quillController.formatSelection(
                                                  const quill.BackgroundAttribute(
                                                    null,
                                                  ),
                                                );
                                              }
                                              setOverlayState(() {
                                                inlineColorType = null;
                                                if (preExpansionPosition !=
                                                    null) {
                                                  _inspectorPosition =
                                                      preExpansionPosition;
                                                  preExpansionPosition = null;
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Builder(
                                        builder: (context) {
                                          Color initialColor = widget.isDarkMode
                                              ? Colors.white
                                              : Colors.black;
                                          try {
                                            final style = _quillController
                                                .getSelectionStyle();
                                            final attr =
                                                inlineColorType == 'font'
                                                ? style
                                                      .attributes['color']
                                                      ?.value
                                                : style
                                                      .attributes['background']
                                                      ?.value;
                                            if (attr != null &&
                                                attr is String) {
                                              initialColor = Color(
                                                int.parse(
                                                  attr.replaceFirst(
                                                    '#',
                                                    '0xFF',
                                                  ),
                                                ),
                                              );
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
                                                    final hex =
                                                        '#${color.value.toRadixString(16).padLeft(8, '0')}';
                                                    if (inlineColorType ==
                                                        'font') {
                                                      _quillController
                                                          .formatSelection(
                                                            quill.ColorAttribute(
                                                              hex,
                                                            ),
                                                          );
                                                    } else {
                                                      _quillController
                                                          .formatSelection(
                                                            quill.BackgroundAttribute(
                                                              hex,
                                                            ),
                                                          );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
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
    
    // Force native focus reclamation whenever the inspector rendering forces a focus drop natively:
    if (mounted && isEditing) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && isEditing) _focusNode.requestFocus();
      });
    }
  }
}

class _SlideFadeIn extends StatefulWidget {
  final Widget child;
  const _SlideFadeIn({required this.child});

  @override
  State<_SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<_SlideFadeIn>
    with SingleTickerProviderStateMixin {
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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
                const Icon(Icons.arrow_drop_down, size: 18),
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