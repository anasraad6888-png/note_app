import re

content = open("lib/dialogs/unified_color_picker_dialog.dart", "r").read()

new_build = """  Widget _buildSmallGrid(bool isDarkMode) {
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "لوحة الألوان",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.open_in_full,
                      size: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'ألوان متقدمة',
                    onPressed: () {
                      setState(() {
                        _isExpanded = true;
                      });
                    },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: ProCompactColorPicker.curatedColors.length,
            itemBuilder: (context, index) {
              final color = ProCompactColorPicker.curatedColors[index];
              final isSelected = _selectedColor.value == color.value;
              
              return GestureDetector(
                onTap: () => _updateColor(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : Colors.black.withOpacity(0.1),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ] : [],
                  ),
                  child: isSelected 
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                        size: 14,
                      )
                    : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Do NOT return Dialog here, as showCustomPopover wraps this in a Container + Material
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      width: _isExpanded ? 550 : 340,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 400),
        firstCurve: Curves.easeOutQuart,
        secondCurve: Curves.easeOutQuart,
        sizeCurve: Curves.easeOutQuart,
        crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: _buildSmallGrid(isDarkMode),
        secondChild: Container(
          width: 550,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () {
                              setState(() => _isExpanded = false);
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "محرر الألوان المتقدم",
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.canvasRepaintKey != null)
                            IconButton(
                              icon: const Icon(
                                LucideIcons.pipette,
                                size: 18,
                                color: Color(0xFFFF7F6A),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: 'لقط لون من الشاشة',
                              onPressed: () async {
                                final canvasContext = widget.canvasRepaintKey?.currentContext;
                                if (canvasContext == null) return;
                                
                                final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
                                
                                _closeDialog();
                                await Future.delayed(
                                  const Duration(milliseconds: 200),
                                );

                                if (canvasContext.mounted) {
                                  RenderRepaintBoundary boundary =
                                      canvasContext.findRenderObject()
                                          as RenderRepaintBoundary;
                                  import('dart:ui') as ui;
                                  var image = await boundary.toImage(
                                    pixelRatio: pixelRatio,
                                  );

                                  if (canvasContext.mounted) {
                                    Color? pickedColor = await Navigator.of(canvasContext)
                                        .push(
                                          PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (context, _, _) =>
                                                EyedropperOverlay(
                                                  capturedImage: image,
                                                ),
                                          ),
                                        );

                                    if (pickedColor != null) {
                                      _updateColor(pickedColor);
                                    }
                                  }
                                }
                              },
                            ),
                          if (widget.onDelete != null)
                            TextButton.icon(
                              icon: const Icon(LucideIcons.ban, size: 14),
                              label: const Text("شفاف"),
                              style: TextButton.styleFrom(
                                foregroundColor: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                textStyle: const TextStyle(fontSize: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: Size.zero,
                              ),
                              onPressed: () {
                                widget.onDelete!();
                                _closeDialog();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(
                  cardColor: Colors.transparent,
                ),
                child: SizedBox(
                  height: 250,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ProCompactColorPicker(
                      pickerColor: _selectedColor,
                      onColorChanged: _updateColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }"""

idx = content.find("  Widget _buildSmallGrid(bool isDarkMode) {")
if idx == -1:
    print("Could not find build method")
else:
    content = content[:idx] + new_build + "\n}\n"
    # fix the dynamic ui import bug in Python replacement (we can just add it to top of file if dart:ui is missing, but dart:ui is already imported in this file as ui)
    content = content.replace("import('dart:ui') as ui;", "")
    
    open("lib/dialogs/unified_color_picker_dialog.dart", "w").write(content)
    print("DONE")

