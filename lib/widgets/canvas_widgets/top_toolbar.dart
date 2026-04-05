import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/canvas_controller.dart';
import '../../models/canvas_models.dart';
import '../../dialogs/canvas_dialogs.dart';
import 'drawing_tools_row.dart';
import '../custom_popover.dart';

class CanvasTopToolbar extends StatelessWidget {
  final CanvasController canvasCtrl;
  final AudioController audioCtrl;
  final VoidCallback? onClose;

  const CanvasTopToolbar({
    super.key,
    required this.canvasCtrl,
    required this.audioCtrl,
    this.onClose,
  });

  // ── Colour helpers ──────────────────────────────────────────────────────────
  Color get _fg => canvasCtrl.isDarkMode ? Colors.white : Colors.black87;
  Color get _accent => const Color(0xFFFF7F6A);

  // ── Thin vertical divider ──────────────────────────────────────────────────
  Widget _divider() => Container(
        width: 1,
        height: 16,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: (canvasCtrl.isDarkMode ? Colors.white : Colors.black).withAlpha(25),
      );

  // ── Single icon button — compact 36×36 hit area ───────────────────────────
  Widget _btn({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color? color,
    bool active = false,
  }) {
    final c = color ?? _fg;
    return Tooltip(
      message: tooltip,
      preferBelow: true,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: active
                  ? _accent.withAlpha(30)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 17,
              color: onTap == null
                  ? c.withAlpha(60)
                  : active
                      ? _accent
                      : c.withAlpha(200),
            ),
          ),
        ),
      ),
    );
  }

  // ── Small "pill" group: glass background ──────────────────────────────────
  Widget _group(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: (canvasCtrl.isDarkMode ? Colors.white : Colors.black)
            .withAlpha(canvasCtrl.isDarkMode ? 12 : 7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (canvasCtrl.isDarkMode ? Colors.white : Colors.black)
              .withAlpha(18),
          width: 0.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  // ── Document title chip ───────────────────────────────────────────────────
  Widget _titleChip(BuildContext context) {
    return GestureDetector(
      onTap: () => CanvasDialogs.showEditTitleDialog(
        context: context,
        document: canvasCtrl.document,
        isDarkMode: canvasCtrl.isDarkMode,
        onSave: () => canvasCtrl.saveStrokes(),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (canvasCtrl.isDarkMode ? Colors.white : Colors.black)
                .withAlpha(canvasCtrl.isDarkMode ? 15 : 8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  canvasCtrl.document.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: -0.2,
                    color: canvasCtrl.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                LucideIcons.edit2,
                size: 11,
                color: canvasCtrl.isDarkMode
                    ? Colors.white38
                    : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Position popup ─────────────────────────────────────────────────────────
  void _showPositionPopover(BuildContext btnContext) {
    bool isDark = canvasCtrl.isDarkMode;

    showCustomPopover(
      context: btnContext,
      isTopHalf: true,
      width: 260,
      height: 250,
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      bodyBuilder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildToolbarPill(ToolbarPosition pos, bool isHorizontal) {
              final isActive = canvasCtrl.toolbarPosition == pos;
              final activeColor = _accent;
              final inactiveColor = isDark ? Colors.white12 : Colors.black12;

              return GestureDetector(
                onTap: () {
                  if (!isActive) {
                    canvasCtrl.updateToolbarPosition(pos);
                    if (context.mounted) setState(() {});
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    decoration: BoxDecoration(
                      color: isActive ? activeColor : inactiveColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isActive
                              ? activeColor.withAlpha(120)
                              : Colors.transparent,
                          blurRadius: isActive ? 10 : 0,
                          spreadRadius: isActive ? 2 : 0,
                        )
                      ],
                    ),
                    margin: isHorizontal
                        ? EdgeInsets.symmetric(
                            horizontal: isActive ? 0 : 16,
                            vertical: isActive ? 0 : 5)
                        : EdgeInsets.symmetric(
                            vertical: isActive ? 0 : 16,
                            horizontal: isActive ? 0 : 5),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.move,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        'إرساء شريط الأدوات',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 180,
                    height: 140,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.black12,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(LucideIcons.penTool,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                  size: 32),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 18,
                          right: 18,
                          height: 16,
                          child: buildToolbarPill(ToolbarPosition.top, true),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 18,
                          right: 18,
                          height: 16,
                          child:
                              buildToolbarPill(ToolbarPosition.bottom, true),
                        ),
                        Positioned(
                          left: 0,
                          top: 18,
                          bottom: 18,
                          width: 16,
                          child: buildToolbarPill(ToolbarPosition.left, false),
                        ),
                        Positioned(
                          right: 0,
                          top: 18,
                          bottom: 18,
                          width: 16,
                          child:
                              buildToolbarPill(ToolbarPosition.right, false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Main build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 14,
      left: 14,
      right: 14,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            DragTarget<String>(
              onWillAcceptWithDetails: (details) =>
                  details.data == 'dock_tools' &&
                  canvasCtrl.toolbarPosition != ToolbarPosition.top,
              onAcceptWithDetails: (details) {
                canvasCtrl.updateToolbarPosition(ToolbarPosition.top);
                canvasCtrl.setDraggingPalette(false);
              },
              builder: (context, candidateData, rejectedData) {
                bool isTargeted = candidateData.isNotEmpty;
                return IntrinsicWidth(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        // ── Compact vertical padding ──────────────────────────
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (canvasCtrl.isDarkMode
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.white)
                                  .withAlpha(isTargeted ? 220 : 185),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (canvasCtrl.isDarkMode
                                    ? Colors.white
                                    : Colors.black)
                                .withAlpha(22),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withAlpha(canvasCtrl.isDarkMode ? 50 : 18),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Main toolbar row ─────────────────────────────
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Group 1 — Back + Title
                                  _group([
                                    if (onClose != null ||
                                        canvasCtrl.onDocumentClose != null) ...[
                                      _btn(
                                        icon: LucideIcons.arrowLeft,
                                        tooltip: 'رجوع',
                                        onTap: onClose ??
                                            canvasCtrl.onDocumentClose,
                                      ),
                                      _divider(),
                                    ],
                                    _titleChip(context),
                                  ]),

                                  const SizedBox(width: 8),

                                  // Group 2 — Document actions
                                  _group([
                                    _btn(
                                      icon: LucideIcons.filePlus2,
                                      tooltip: 'إضافة صفحة',
                                      color: _accent,
                                      onTap: () => canvasCtrl.addPage(),
                                    ),
                                    _btn(
                                      icon: LucideIcons.share2,
                                      tooltip: 'مشاركة',
                                      color: _accent,
                                      onTap: () => CanvasDialogs.showExportDialog(
                                        context: context,
                                        isDarkMode: canvasCtrl.isDarkMode,
                                        onExportImage: () =>
                                            canvasCtrl.saveCurrentPageToGallery(
                                                canvasCtrl.currentPageIndex),
                                        onExportPdf: canvasCtrl.shareAsPdf,
                                      ),
                                    ),
                                    _divider(),
                                    Builder(
                                      builder: (btnCtx) => _btn(
                                        icon: LucideIcons.fileText,
                                        tooltip: 'إعدادات الصفحة',
                                        onTap: () =>
                                            CanvasDialogs.showPageSettingsDialog(
                                          context: btnCtx,
                                          canvasCtrl: canvasCtrl,
                                          isTopHalf: true,
                                        ),
                                      ),
                                    ),
                                    _btn(
                                      icon: canvasCtrl.isDarkMode
                                          ? LucideIcons.sun
                                          : LucideIcons.moon,
                                      tooltip: 'الوضع الليلي',
                                      color: canvasCtrl.isDarkMode
                                          ? Colors.amber
                                          : _fg,
                                      onTap: canvasCtrl.toggleDarkMode,
                                    ),
                                    _divider(),
                                    // Mic — with recording animation
                                    Builder(builder: (btnCtx) {
                                      Widget mic = CompositedTransformTarget(
                                        link: audioCtrl.audioWindowLink,
                                        child: _btn(
                                          icon: LucideIcons.mic,
                                          tooltip: 'التسجيل المتزامن',
                                          active: audioCtrl.isRecording,
                                          color: audioCtrl.isRecording
                                              ? Colors.redAccent
                                              : _fg,
                                          onTap: () =>
                                              audioCtrl.toggleAudioBar(),
                                        ),
                                      );
                                      if (audioCtrl.isRecording) {
                                        mic = mic
                                            .animate(
                                                onPlay: (c) =>
                                                    c.repeat(reverse: true))
                                            .tint(
                                                color: Colors.redAccent,
                                                end: 1.0,
                                                duration: 1200.ms,
                                                curve: Curves.easeInOut);
                                      } else {
                                        mic = mic
                                            .animate(
                                                target: (audioCtrl.isPlaying &&
                                                        !audioCtrl.isAudioBarVisible)
                                                    ? 1.0
                                                    : 0.0)
                                            .tint(
                                                color: _accent,
                                                end: 1.0,
                                                duration: 400.ms);
                                      }
                                      return mic;
                                    }),
                                    _btn(
                                      icon: LucideIcons.layoutGrid,
                                      tooltip: 'عرض الصفحات',
                                      onTap: canvasCtrl.onShowPagesGridDialog,
                                    ),
                                    _divider(),
                                    Builder(
                                      builder: (btnCtx) => _btn(
                                        icon: LucideIcons.move,
                                        tooltip: 'إرساء شريط الأدوات',
                                        color: _accent,
                                        onTap: () =>
                                            _showPositionPopover(btnCtx),
                                      ),
                                    ),
                                    _btn(
                                      icon: LucideIcons.zoomIn,
                                      tooltip: 'التحكم بالتكبير',
                                      active: canvasCtrl.isZoomSliderVisible,
                                      onTap: () {
                                        canvasCtrl.toggleZoomSlider();
                                        canvasCtrl.notifyListeners();
                                      },
                                    ),
                                  ]),

                                  const SizedBox(width: 8),

                                  // Group 3 — Undo / Redo + paste
                                  _group([
                                    if (canvasCtrl.clipboardGroup != null)
                                      _btn(
                                        icon: LucideIcons.clipboardPaste,
                                        tooltip: 'لصق',
                                        color: _accent,
                                        onTap: () => canvasCtrl.pasteClipboard(
                                          canvasCtrl.currentPageIndex,
                                          Offset(
                                            MediaQuery.of(context).size.width /
                                                2,
                                            MediaQuery.of(context).size.height /
                                                2,
                                          ),
                                        ),
                                      ),
                                    _btn(
                                      icon: LucideIcons.undo,
                                      tooltip: 'تراجع',
                                      color: const Color(0xFF5B8DEF),
                                      onTap: canvasCtrl.canUndo
                                          ? () => canvasCtrl
                                              .undo(canvasCtrl.currentPageIndex)
                                          : null,
                                    ),
                                    _btn(
                                      icon: LucideIcons.redo,
                                      tooltip: 'إعادة',
                                      color: const Color(0xFF5B8DEF),
                                      onTap: canvasCtrl.canRedo
                                          ? () => canvasCtrl
                                              .redo(canvasCtrl.currentPageIndex)
                                          : null,
                                    ),
                                  ]),
                                ],
                              ),
                            ),

                            // ── Docked drawing tools (when toolbar at top) ───
                            if (canvasCtrl.toolbarPosition ==
                                ToolbarPosition.top) ...[
                              const SizedBox(height: 8),
                              Draggable<String>(
                                data: 'dock_tools',
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: _buildDockedTools(context,
                                      opacity: 0.8),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.0,
                                  child: _buildDockedTools(context),
                                ),
                                onDragStarted: () =>
                                    canvasCtrl.setDraggingPalette(true),
                                onDragEnd: (_) =>
                                    canvasCtrl.setDraggingPalette(false),
                                onDraggableCanceled: (_, _) =>
                                    canvasCtrl.setDraggingPalette(false),
                                child: _buildDockedTools(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          ),   // Column
        ),     // Align
      ),       // SafeArea
    );
  }

  // ── Docked tools helper (DRY) ───────────────────────────────────────────────
  Widget _buildDockedTools(BuildContext context, {double opacity = 1.0}) {
    final bool hasSettings = canvasCtrl.isSettingsMagnetActive &&
        (canvasCtrl.showPenSettingsRow ||
            canvasCtrl.showHighlighterSettingsRow ||
            canvasCtrl.showLaserSettingsRow ||
            canvasCtrl.showTextSettingsRow ||
            canvasCtrl.showEraserSettingsRow ||
            canvasCtrl.showLassoSettingsRow ||
            canvasCtrl.showAddSettingsRow);

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tools row — shrink-wrapped, no Flexible/Row needed
        DrawingToolsRow(
          canvasCtrl: canvasCtrl,
          audioCtrl: audioCtrl,
          direction: Axis.horizontal,
        ),
        if (hasSettings) ...[
          const SizedBox(height: 6),
          Container(
            key: canvasCtrl.dockedSettingsKey,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: canvasCtrl.isDarkMode
                  ? Colors.grey.shade900.withAlpha(240)
                  : Colors.white.withAlpha(240),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: canvasCtrl.isDarkMode
                    ? Colors.white10
                    : Colors.black12,
              ),
            ),
            child: DrawingToolsRow.buildSettingsRow(canvasCtrl, context),
          )
              .animate()
              .fade(duration: 200.ms)
              .scale(
                  begin: const Offset(0.95, 0.95),
                  curve: Curves.easeOut),
        ],
      ],
    );

    return opacity < 1.0 ? Opacity(opacity: opacity, child: content) : content;
  }
}
