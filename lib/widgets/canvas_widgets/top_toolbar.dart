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

  Widget _buildIsland(List<Widget> children, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: (isDarkMode ? Colors.black : Colors.white).withAlpha(100),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDarkMode ? Colors.white : Colors.black).withAlpha(20),
          width: 0.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildToolButton(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback? onPressed,
  ) {
    return IconButton(
      icon: Icon(
        icon,
        color: onPressed == null ? color.withAlpha(100) : color,
        size: 20,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 20,
    );
  }

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
              
              final activeColor = const Color(0xFFFF7F6A);
              final inactiveColor = isDark ? Colors.white12 : Colors.black12;

              return GestureDetector(
                onTap: () {
                  if (!isActive) {
                    canvasCtrl.updateToolbarPosition(pos);
                    // Update local state to animate the glowing UI instantaneously
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
                          color: isActive ? activeColor.withAlpha(120) : Colors.transparent,
                          blurRadius: isActive ? 10 : 0,
                          spreadRadius: isActive ? 2 : 0,
                        )
                      ],
                      border: Border.all(
                        color: isActive ? Colors.white.withAlpha(50) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    margin: isHorizontal 
                      ? EdgeInsets.symmetric(horizontal: isActive ? 0 : 16, vertical: isActive ? 0 : 5)
                      : EdgeInsets.symmetric(vertical: isActive ? 0 : 16, horizontal: isActive ? 0 : 5),
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
                      Icon(LucideIcons.move, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        'إرساء شريط الأدوات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Interactive iPad Simulator
                  SizedBox(
                    width: 180,
                    height: 140,
                    child: Stack(
                      children: [
                        // The Screen Outline
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(isDark ? 60 : 10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                              border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1.5),
                            ),
                            child: Center(
                              child: Icon(LucideIcons.penTool, color: isDark ? Colors.white24 : Colors.black26, size: 32),
                            ),
                          ),
                        ),
                        // Top Toolbar Dock
                        Positioned(
                          top: 0, left: 18, right: 18, height: 16,
                          child: buildToolbarPill(ToolbarPosition.top, true),
                        ),
                        // Bottom Toolbar Dock
                        Positioned(
                          bottom: 0, left: 18, right: 18, height: 16,
                          child: buildToolbarPill(ToolbarPosition.bottom, true),
                        ),
                        // Left Toolbar Dock
                        Positioned(
                          left: 0, top: 18, bottom: 18, width: 16,
                          child: buildToolbarPill(ToolbarPosition.left, false),
                        ),
                        // Right Toolbar Dock
                        Positioned(
                          right: 0, top: 18, bottom: 18, width: 16,
                          child: buildToolbarPill(ToolbarPosition.right, false),
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                return ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (canvasCtrl.isDarkMode
                                    ? Colors.grey.shade900
                                    : Colors.white)
                                .withAlpha(isTargeted ? 200 : 160),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              (canvasCtrl.isDarkMode
                                      ? Colors.white
                                      : Colors.black)
                                  .withAlpha(30),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(
                              canvasCtrl.isDarkMode ? 40 : 15,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main Toolbar Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Island 1: Navigation & Title
                                _buildIsland([
                                  if (onClose != null ||
                                      canvasCtrl.onDocumentClose != null) ...[
                                    _buildToolButton(
                                      LucideIcons.arrowLeft,
                                      'رجوع',
                                      canvasCtrl.isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                      onClose ?? canvasCtrl.onDocumentClose,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      color:
                                          (canvasCtrl.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black)
                                              .withAlpha(30),
                                    ),
                                  ],
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () =>
                                        CanvasDialogs.showEditTitleDialog(
                                          context: context,
                                          document: canvasCtrl.document,
                                          isDarkMode: canvasCtrl.isDarkMode,
                                          onSave: () =>
                                              canvasCtrl.saveStrokes(),
                                        ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            canvasCtrl.document.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: canvasCtrl.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            LucideIcons.edit2,
                                            size: 14,
                                            color: canvasCtrl.isDarkMode
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ], canvasCtrl.isDarkMode),

                                const SizedBox(width: 12),
                                // Island 2: Document Actions
                                _buildIsland([
                                  _buildToolButton(
                                    Icons.note_add,
                                    'إضافة صفحة',
                                    const Color(0xFFFF7F6A),
                                    () => canvasCtrl.addPage(),
                                  ),
                                  _buildToolButton(
                                    LucideIcons.share2,
                                    'مشاركة',
                                    const Color(0xFFFF7F6A),
                                    () => CanvasDialogs.showExportDialog(
                                      context: context,
                                      isDarkMode: canvasCtrl.isDarkMode,
                                      onExportImage: () =>
                                          canvasCtrl.saveCurrentPageToGallery(
                                            canvasCtrl.currentPageIndex,
                                          ),
                                      onExportPdf: canvasCtrl.shareAsPdf,
                                    ),
                                  ),
                                  Builder(
                                    builder: (btnContext) => _buildToolButton(
                                      LucideIcons.fileText,
                                      'إعدادات الصفحة',
                                      Colors.blueGrey,
                                      () =>
                                          CanvasDialogs.showPageSettingsDialog(
                                            context: btnContext,
                                            canvasCtrl: canvasCtrl,
                                            isTopHalf: true,
                                          ),
                                    ),
                                  ),
                                  _buildToolButton(
                                    canvasCtrl.isDarkMode
                                        ? LucideIcons.sun
                                        : LucideIcons.moon,
                                    'الوضع الليلي',
                                    canvasCtrl.isDarkMode
                                        ? Colors.amber
                                        : Colors.blueGrey,
                                    canvasCtrl.toggleDarkMode,
                                  ),
                                  _buildToolButton(
                                    LucideIcons.mic,
                                    'التسجيل المتزامن',
                                    (canvasCtrl
                                                .document
                                                .audioPaths
                                                .isNotEmpty ||
                                            audioCtrl.isRecording)
                                        ? Colors.redAccent
                                        : Colors.blueGrey,
                                    audioCtrl.toggleAudioBar,
                                  ),
                                  _buildToolButton(
                                    LucideIcons.layoutGrid,
                                    'عرض وتصنيف الصفحات',
                                    Colors.blueGrey,
                                    canvasCtrl.onShowPagesGridDialog,
                                  ),
                                  Builder(
                                    builder: (btnCtx) => _buildToolButton(
                                      LucideIcons.move,
                                      'إرساء شريط الأدوات',
                                      const Color(0xFFFF7F6A),
                                      () => _showPositionPopover(btnCtx),
                                    ),
                                  ),
                                ], canvasCtrl.isDarkMode),

                                const SizedBox(width: 12),
                                // Island 3: History & Clipboard
                                _buildIsland([
                                  if (canvasCtrl.clipboardGroup != null)
                                    _buildToolButton(
                                      LucideIcons.clipboardPaste,
                                      'لصق',
                                      const Color(0xFFFF7F6A),
                                      () => canvasCtrl.pasteClipboard(
                                        canvasCtrl.currentPageIndex,
                                        Offset(
                                          MediaQuery.of(context).size.width / 2,
                                          MediaQuery.of(context).size.height /
                                              2,
                                        ),
                                      ),
                                    ),
                                  _buildToolButton(
                                    LucideIcons.undo,
                                    'تراجع',
                                    Colors.blue,
                                    canvasCtrl.canUndo
                                        ? () => canvasCtrl.undo(
                                            canvasCtrl.currentPageIndex,
                                          )
                                        : null,
                                  ),
                                  _buildToolButton(
                                    LucideIcons.redo,
                                    'إعادة',
                                    Colors.blue,
                                    canvasCtrl.canRedo
                                        ? () => canvasCtrl.redo(
                                            canvasCtrl.currentPageIndex,
                                          )
                                        : null,
                                  ),
                                ], canvasCtrl.isDarkMode),
                              ],
                            ),
                          ),

                          // Docked Drawing Tools
                          if (canvasCtrl.toolbarPosition ==
                              ToolbarPosition.top) ...[
                            const SizedBox(height: 12),
                            Draggable<String>(
                              data: 'dock_tools',
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width - 40,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Opacity(
                                        opacity: 0.8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                (canvasCtrl.isDarkMode
                                                        ? Colors.grey.shade900
                                                        : Colors.white)
                                                    .withAlpha(180),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFFF7F6A),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                  20,
                                                ),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: IntrinsicWidth(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                DrawingToolsRow(
                                                  canvasCtrl: canvasCtrl,
                                                  audioCtrl: audioCtrl,
                                                  direction: Axis.horizontal,
                                                ),
                                                if (canvasCtrl
                                                        .isSettingsMagnetActive &&
                                                    (canvasCtrl
                                                            .showPenSettingsRow ||
                                                        canvasCtrl
                                                            .showHighlighterSettingsRow ||
                                                        canvasCtrl
                                                            .showLaserSettingsRow ||
                                                        canvasCtrl
                                                            .showTextSettingsRow ||
                                                        canvasCtrl
                                                            .showEraserSettingsRow ||
                                                        canvasCtrl
                                                            .showLassoSettingsRow ||
                                                        canvasCtrl
                                                            .showAddSettingsRow)) ...[
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          canvasCtrl.isDarkMode
                                                          ? Colors.grey.shade900
                                                                .withAlpha(240)
                                                          : Colors.white
                                                                .withAlpha(240),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            canvasCtrl
                                                                .isDarkMode
                                                            ? Colors.white10
                                                            : Colors.black12,
                                                      ),
                                                    ),
                                                    child: SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child:
                                                          DrawingToolsRow.buildSettingsRow(
                                                            canvasCtrl,
                                                            context,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          fit: FlexFit.loose,
                                          child: DrawingToolsRow(
                                            canvasCtrl: canvasCtrl,
                                            audioCtrl: audioCtrl,
                                            direction: Axis.horizontal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (canvasCtrl.isSettingsMagnetActive &&
                                        (canvasCtrl.showPenSettingsRow ||
                                            canvasCtrl
                                                .showHighlighterSettingsRow ||
                                            canvasCtrl.showLaserSettingsRow ||
                                            canvasCtrl.showTextSettingsRow ||
                                            canvasCtrl.showEraserSettingsRow ||
                                            canvasCtrl.showLassoSettingsRow ||
                                            canvasCtrl.showAddSettingsRow)) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: canvasCtrl.isDarkMode
                                              ? Colors.grey.shade900.withAlpha(
                                                  240,
                                                )
                                              : Colors.white.withAlpha(240),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: canvasCtrl.isDarkMode
                                                ? Colors.white10
                                                : Colors.black12,
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child:
                                              DrawingToolsRow.buildSettingsRow(
                                                canvasCtrl,
                                                context,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              onDragStarted: () =>
                                  canvasCtrl.setDraggingPalette(true),
                              onDragEnd: (_) =>
                                  canvasCtrl.setDraggingPalette(false),
                              onDraggableCanceled: (_, _) =>
                                  canvasCtrl.setDraggingPalette(false),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        fit: FlexFit.loose,
                                        child: DrawingToolsRow(
                                          canvasCtrl: canvasCtrl,
                                          audioCtrl: audioCtrl,
                                          direction: Axis.horizontal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (canvasCtrl.isSettingsMagnetActive &&
                                      (canvasCtrl.showPenSettingsRow ||
                                          canvasCtrl
                                              .showHighlighterSettingsRow ||
                                          canvasCtrl.showLaserSettingsRow ||
                                          canvasCtrl.showTextSettingsRow ||
                                          canvasCtrl.showEraserSettingsRow ||
                                          canvasCtrl.showLassoSettingsRow ||
                                          canvasCtrl.showAddSettingsRow)) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                          key: canvasCtrl.dockedSettingsKey,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: canvasCtrl.isDarkMode
                                                ? Colors.grey.shade900
                                                      .withAlpha(240)
                                                : Colors.white.withAlpha(240),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: canvasCtrl.isDarkMode
                                                  ? Colors.white10
                                                  : Colors.black12,
                                            ),
                                          ),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child:
                                                DrawingToolsRow.buildSettingsRow(
                                                  canvasCtrl,
                                                  context,
                                                ),
                                          ),
                                        )
                                        .animate()
                                        .fade(duration: 200.ms)
                                        .scale(
                                          begin: const Offset(0.9, 0.9),
                                          curve: Curves.easeOut,
                                        ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
