import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../custom_popover.dart';
import '../../dialogs/unified_color_picker_dialog.dart';
import '../../controllers/canvas_controller.dart';
import '../../controllers/audio_controller.dart';
import '../../dialogs/canvas_dialogs.dart';
import '../../models/canvas_models.dart';
import 'advanced_pen_settings.dart';
import 'settings_rows/shared_settings_helpers.dart';
export 'settings_rows/shared_settings_helpers.dart';
import 'settings_rows/add_settings_row.dart';
import 'settings_rows/pen_settings_row.dart';
import 'settings_rows/highlighter_settings_row.dart';
import 'settings_rows/laser_settings_row.dart';
import 'settings_rows/eraser_settings_row.dart';
import 'settings_rows/lasso_settings_row.dart';
import 'settings_rows/text_settings_row.dart';

class DrawingToolsRow extends StatefulWidget {
  final CanvasController canvasCtrl;
  final AudioController audioCtrl;
  final Axis direction;

  const DrawingToolsRow({
    super.key,
    required this.canvasCtrl,
    required this.audioCtrl,
    this.direction = Axis.horizontal,
  });

  @override
  State<DrawingToolsRow> createState() => _DrawingToolsRowState();

  // --- Static Helper for Settings ---
  static Widget buildSettingsRow(
    CanvasController canvasCtrl,
    BuildContext context, {
    bool reversed = false,
    bool isVertical = false,
  }) {
    Widget settingsWidget = const SizedBox.shrink();

    if (canvasCtrl.showAddSettingsRow) {
      settingsWidget = AddSettingsRow(canvasCtrl: canvasCtrl, reversed: reversed, isVertical: isVertical);
    } else if (canvasCtrl.showPenSettingsRow) {
      settingsWidget = PenSettingsRow(canvasCtrl: canvasCtrl, reversed: reversed, isVertical: isVertical);
    } else if (canvasCtrl.showHighlighterSettingsRow) {
      settingsWidget = HighlighterSettingsRow(canvasCtrl: canvasCtrl, reversed: reversed, isVertical: isVertical);
    } else if (canvasCtrl.showLaserSettingsRow) {
      settingsWidget = LaserSettingsRow(canvasCtrl: canvasCtrl, reversed: reversed, isVertical: isVertical);
    } else if (canvasCtrl.showEraserSettingsRow) {
      settingsWidget = EraserSettingsRow(canvasCtrl: canvasCtrl, reversed: reversed, isVertical: isVertical);
    } else if (canvasCtrl.showLassoSettingsRow) {
      settingsWidget = LassoSettingsRow(canvasCtrl: canvasCtrl, reversed: reversed, isVertical: isVertical);
    } else if (canvasCtrl.showTextSettingsRow) {
      settingsWidget = TextSettingsRow(canvasCtrl: canvasCtrl, reversed: reversed, isVertical: isVertical);
    }

    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(4),
          minimumSize: const Size(30, 30),
          maximumSize: const Size(30, 30),
          iconSize: 17,
        ),
      ),
      child: settingsWidget,
    );
  }
}

class _DrawingToolsRowState extends State<DrawingToolsRow> {
  late ScrollController _scrollController;
  bool _canScrollBackward = true;
  bool _canScrollForward = true;

  @override
  void initState() {
    super.initState();
    // 4 items * 54 wide = 216 for horizontal
    // 4 items * 48 tall = 192 for vertical
    double offset = widget.direction == Axis.vertical ? 192.0 : 216.0;
    _scrollController = ScrollController(initialScrollOffset: offset);
    _scrollController.addListener(_updateScrollState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
  }

  void _updateScrollState() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Robust threshold for bouncing physics and iOS simulator scaling quirks
    final canGoBack = pos.pixels > pos.minScrollExtent + 5.0;
    final canGoForward = pos.pixels < pos.maxScrollExtent - 5.0;
    
    if (canGoBack != _canScrollBackward || canGoForward != _canScrollForward) {
      if (mounted) {
        setState(() {
          _canScrollBackward = canGoBack;
          _canScrollForward = canGoForward;
        });
      }
    }
  }

  @override
  void didUpdateWidget(DrawingToolsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direction != widget.direction) {
      double offset = widget.direction == Axis.vertical ? 192.0 : 216.0;
      _scrollController.dispose();
      _scrollController = ScrollController(initialScrollOffset: offset);
      _scrollController.addListener(_updateScrollState);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollState);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildScrollIndicator(IconData icon, bool visible) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 0.45 : 0.0, // Reduced opacity
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          padding: const EdgeInsets.all(2),
          child: Icon(
            icon, 
            size: 18, 
            color: widget.canvasCtrl.isDarkMode ? Colors.white54 : Colors.black54, // Dimmer icon color
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isVertical = widget.direction == Axis.vertical;
    final canvasCtrl = widget.canvasCtrl;
    final coralGlow = const Color(0xFFFF7F6A); // Soft salmon/coral

    bool isBasePen = !canvasCtrl.isLassoMode && !canvasCtrl.isEraserMode && !canvasCtrl.isHighlighterMode && !canvasCtrl.isLaserMode && !canvasCtrl.isPanZoomMode && !canvasCtrl.isTextMode && !canvasCtrl.isShapeMode && !canvasCtrl.isTableMode;
    bool isTemporarilyPanning = canvasCtrl.isMultiTouchPan && !canvasCtrl.isPanZoomMode;

    bool isBrush = isBasePen && canvasCtrl.currentPenType == PenType.brush && !isTemporarilyPanning;
    bool isPen = isBasePen && canvasCtrl.currentPenType != PenType.brush && !isTemporarilyPanning;

    final topRow = <Widget>[
       GlowingToolButton(
         key: const ValueKey('brush'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: Icons.brush,
         isActive: isBrush,
         hasSettings: true,
         isSettingsExpanded: canvasCtrl.showPenSettingsRow,
         activeColor: coralGlow,
         tooltip: 'فرشاة',
         onTap: () {
           if (!isBrush) {
             bool openSettings = canvasCtrl.disableAllTools();
             if (canvasCtrl.selectedColor == Colors.white) canvasCtrl.selectedColor = Colors.black;
             canvasCtrl.setPenType(PenType.brush);
             if (openSettings) canvasCtrl.showPenSettingsRow = true;
           } else {
             canvasCtrl.showPenSettingsRow = !canvasCtrl.showPenSettingsRow;
           }
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         key: const ValueKey('pencil'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: LucideIcons.pencil,
         isActive: isPen,
         hasSettings: true,
         isSettingsExpanded: canvasCtrl.showPenSettingsRow,
         activeColor: coralGlow,
         tooltip: 'قلم',
         onTap: () {
           if (!isPen) {
             bool openSettings = canvasCtrl.disableAllTools();
             if (canvasCtrl.selectedColor == Colors.white) canvasCtrl.selectedColor = Colors.black;
             if (canvasCtrl.currentPenType == PenType.brush) canvasCtrl.setPenType(PenType.ball);
             if (openSettings) canvasCtrl.showPenSettingsRow = true;
           } else {
             canvasCtrl.showPenSettingsRow = !canvasCtrl.showPenSettingsRow;
           }
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         key: const ValueKey('highlighter'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: Icons.border_color,
         isActive: canvasCtrl.isHighlighterMode && !isTemporarilyPanning,
         hasSettings: true,
         isSettingsExpanded: canvasCtrl.showHighlighterSettingsRow,
         activeColor: coralGlow,
         tooltip: 'تظليل',
         onTap: () {
           canvasCtrl.activateHighlighter();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         key: const ValueKey('lasso'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: LucideIcons.lasso,
         isActive: canvasCtrl.isLassoMode && !isTemporarilyPanning,
         hasSettings: true,
         isSettingsExpanded: canvasCtrl.showLassoSettingsRow,
         activeColor: coralGlow,
         tooltip: 'تحديد',
         onTap: () {
           canvasCtrl.activateLasso();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         key: const ValueKey('text'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: LucideIcons.type,
         isActive: canvasCtrl.isTextMode && !isTemporarilyPanning,
         hasSettings: true,
         isSettingsExpanded: canvasCtrl.showTextSettingsRow,
         activeColor: coralGlow,
         tooltip: 'نص',
         onTap: () {
           canvasCtrl.activateText();
           // update handled inside tools_logic.dart
         },
       ),
       GlowingToolButton(
         key: const ValueKey('eraser'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: LucideIcons.eraser,
         isActive: canvasCtrl.isEraserMode && !isTemporarilyPanning,
         hasSettings: true,
         isSettingsExpanded: canvasCtrl.showEraserSettingsRow,
         activeColor: coralGlow,
         tooltip: 'ممحاة',
         onTap: () {
           canvasCtrl.activateEraser();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         key: const ValueKey('zoom_map'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: Icons.zoom_out_map,
         isActive: canvasCtrl.isZoomWindowVisible,
         activeColor: coralGlow,
         tooltip: 'نافذة مكبرة',
         onTap: () {
           canvasCtrl.toggleZoomWindow(MediaQuery.of(context).size);
           canvasCtrl.notifyListeners();
         },
       ),
    ];

    final combinedItems = <Widget>[
       GlowingToolButton(
         key: const ValueKey('add_menu'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: LucideIcons.plus,
         isActive: canvasCtrl.showAddSettingsRow,
         hasSettings: true,
         isSettingsExpanded: canvasCtrl.showAddSettingsRow,
         activeColor: coralGlow,
         tooltip: 'أدوات الإضافة',
         onTap: () {
           canvasCtrl.toggleAddMenu();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         key: const ValueKey('ruler'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: LucideIcons.ruler,
         isActive: canvasCtrl.isRulerVisible,
         activeColor: coralGlow,
         tooltip: 'مسطرة',
         onTap: () {
           canvasCtrl.toggleRuler(MediaQuery.of(context).size);
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         key: const ValueKey('pan'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: LucideIcons.hand,
         isActive: canvasCtrl.isPanZoomMode || isTemporarilyPanning,
         activeColor: coralGlow,
         tooltip: 'تحريك',
         onTap: () {
           canvasCtrl.activatePanZoom();
           canvasCtrl.notifyListeners();
         },
       ),
       GlowingToolButton(
         key: const ValueKey('laser'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: LucideIcons.wand,
         isActive: canvasCtrl.isLaserMode && !isTemporarilyPanning,
         hasSettings: true,
         isSettingsExpanded: canvasCtrl.showLaserSettingsRow,
         activeColor: coralGlow,
         tooltip: 'ليزر',
         onTap: () {
           canvasCtrl.activateLaser();
           canvasCtrl.notifyListeners();
         },
       ),
       ...topRow,
       GlowingToolButton(
         key: const ValueKey('magnet'),
         toolbarPosition: canvasCtrl.toolbarPosition,
         icon: LucideIcons.magnet,
         isActive: canvasCtrl.isSettingsMagnetActive,
         activeColor: coralGlow,
         tooltip: 'ربط الإعدادات الإضافية',
         onTap: () {
           canvasCtrl.toggleSettingsMagnet();
         },
       ),
    ];

    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVertical ? 4 : 8,
        vertical: isVertical ? 8 : 3,
      ),
      decoration: BoxDecoration(
        color: canvasCtrl.isDarkMode ? const Color(0xD926262A) : const Color(0xE6F5F5F7), // Dark or light translucent pill
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: canvasCtrl.isDarkMode ? Colors.black.withAlpha(60) : Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isVertical ? double.infinity : math.min(MediaQuery.of(context).size.width * 0.9, 600),
              maxHeight: isVertical ? math.min(MediaQuery.of(context).size.height * 0.75, 600) : double.infinity,
            ),
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (notification) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _updateScrollState();
                });
                return false;
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Flex(
                    direction: isVertical ? Axis.vertical : Axis.horizontal,
                    mainAxisSize: MainAxisSize.min,
                    children: combinedItems,
                  ),
                ),
              ),
            ),
          ),
          if (isVertical) ...[
            Positioned(top: -16, child: _buildScrollIndicator(Icons.keyboard_arrow_up, _canScrollBackward)),
            Positioned(bottom: -16, child: _buildScrollIndicator(Icons.keyboard_arrow_down, _canScrollForward)),
          ] else ...[
            Positioned(left: -16, child: _buildScrollIndicator(Icons.keyboard_arrow_left, isRTL ? _canScrollForward : _canScrollBackward)),
            Positioned(right: -16, child: _buildScrollIndicator(Icons.keyboard_arrow_right, isRTL ? _canScrollBackward : _canScrollForward)),
          ]
        ],
      ),
    );
  }


}
