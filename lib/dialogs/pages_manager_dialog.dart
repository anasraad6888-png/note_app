import 'package:flutter/material.dart';
import '../../models/canvas_models.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../controllers/canvas_controller.dart';
import '../../painters/canvas_painters.dart';
import '../widgets/pdf_page_background.dart';
import 'dart:ui'; // For ImageFilter.blur

class PagesManagerDialog extends StatefulWidget {
  final CanvasController canvasCtrl;

  const PagesManagerDialog({super.key, required this.canvasCtrl});

  @override
  State<PagesManagerDialog> createState() => _PagesManagerDialogState();
}

class _PagesManagerDialogState extends State<PagesManagerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMultiSelectMode = false;
  final Set<int> _selectedPages = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedPages.contains(index)) {
        _selectedPages.remove(index);
        if (_selectedPages.isEmpty) _isMultiSelectMode = false;
      } else {
        _selectedPages.add(index);
      }
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    widget.canvasCtrl.reorderPage(oldIndex, newIndex);
    setState(() {}); // Refresh grid
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.canvasCtrl.isDarkMode;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF141414) : const Color(0xFFF7F7F9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 40, spreadRadius: 0)
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Sleek Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 4),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              
              // Premium Header
              _buildHeader(isDarkMode),

              // Modern Custom Segmented Control
              if (!_isMultiSelectMode)
                 _buildSegmentedTabControl(isDarkMode),
                
              const SizedBox(height: 8),

              // Divider
              Divider(height: 1, color: isDarkMode ? Colors.white10 : Colors.black.withAlpha(15)),

              // Tab Views
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.canvasCtrl,
                  builder: (context, _) {
                    return TabBarView(
                      controller: _tabController,
                      physics: _isMultiSelectMode ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                      children: [
                        _buildThumbnailsGrid(isDarkMode, onlyBookmarks: false),
                        _buildOutlineView(isDarkMode),
                        _buildThumbnailsGrid(isDarkMode, onlyBookmarks: true),
                      ],
                    );
                  }
                ),
              ),
              
              // Spacer for the floating bottom bar
              if (_isMultiSelectMode) const SizedBox(height: 90),
            ],
          ),

          // Floating MultiSelect Action Bar
          if (_isMultiSelectMode)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: _buildFloatingActionBar(isDarkMode),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabControl(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
          borderRadius: BorderRadius.circular(24),
        ),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Row(
              children: [
                _buildTabPill(0, 'المصغرات', LucideIcons.layoutGrid, isDarkMode),
                _buildTabPill(1, 'المخطط', LucideIcons.listOrdered, isDarkMode),
                _buildTabPill(2, 'المفضلة', LucideIcons.bookmark, isDarkMode),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label, IconData icon, bool isDarkMode) {
    bool isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDarkMode ? const Color(0xFF2C2C2E) : Colors.white) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected && !isDarkMode
                ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))]
                : isSelected && isDarkMode
                ? [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? const Color(0xFFFF7F6A) : (isDarkMode ? Colors.white54 : Colors.black54)),
              const SizedBox(width: 8),
              Text(
                label, 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                  color: isSelected ? const Color(0xFFFF7F6A) : (isDarkMode ? Colors.white54 : Colors.black54)
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isMultiSelectMode 
                    ? 'تم تحديد ${_selectedPages.length}' 
                    : 'إدارة الصفحات',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDarkMode ? Colors.white : const Color(0xFF1E1E1E),
                  ),
                ),
                if (!_isMultiSelectMode)
                   Text(
                     'المستند يحتوي على ${widget.canvasCtrl.pagesPoints.length} صفحات',
                     style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white54 : Colors.black54),
                   ),
              ],
            ),
          ),
          Row(
            children: [
              if (!_isMultiSelectMode) ...[
                _buildHeaderIcon(
                  LucideIcons.checkSquare, 
                  isDarkMode, 
                  onTap: () {
                    setState(() {
                      _isMultiSelectMode = true;
                      _selectedPages.clear();
                    });
                  },
                  tooltip: 'تحديد متعدد'
                ),
                const SizedBox(width: 8),
                _buildHeaderIcon(
                  LucideIcons.plus, 
                  isDarkMode, 
                  color: const Color(0xFFFF7F6A),
                  bgColor: const Color(0xFFFF7F6A).withAlpha(20),
                  onTap: () {
                    int targetIndex = widget.canvasCtrl.currentPageIndex + 1;
                    widget.canvasCtrl.addBlankPageAt(targetIndex);
                    widget.canvasCtrl.jumpToPage(targetIndex);
                  },
                  tooltip: 'إضافة صفحة فارغة'
                ),
                const SizedBox(width: 8),
                _buildHeaderIcon(
                  LucideIcons.x, 
                  isDarkMode, 
                  onTap: () => Navigator.pop(context),
                  bgColor: isDarkMode ? Colors.white10 : Colors.black.withAlpha(10),
                ),
              ] else ...[
                TextButton(
                  onPressed: () => setState(() {
                    _isMultiSelectMode = false;
                    _selectedPages.clear();
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white70 : Colors.black54,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  child: const Text('إلغاء'),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, bool isDarkMode, {VoidCallback? onTap, String? tooltip, Color? color, Color? bgColor}) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: bgColor ?? Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: color ?? (isDarkMode ? Colors.white70 : Colors.black87)),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailsGrid(bool isDarkMode, {required bool onlyBookmarks}) {
    final pagesCount = widget.canvasCtrl.pagesPoints.length;
    List<int> validIndices = [];
    for (int i = 0; i < pagesCount; i++) {
      if (!onlyBookmarks || widget.canvasCtrl.pagesBookmarks[i]) {
        validIndices.add(i);
      }
    }

    if (validIndices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                shape: BoxShape.circle,
              ),
              child: Icon(onlyBookmarks ? LucideIcons.bookmarkMinus : LucideIcons.fileX, size: 48, color: isDarkMode ? Colors.white54 : Colors.black38),
            ),
            const SizedBox(height: 24),
            Text(
              onlyBookmarks ? 'لا توجد صفحات مفضلة' : 'المستند فارغ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              onlyBookmarks ? 'المس رمز العلامة المرجعية أعلى الصفحة لحفظها' : 'اضغط على + لإضافة صفحة جديدة',
              style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
            ),
          ],
        ),
      );
    }

    if (onlyBookmarks) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 0.72,
        ),
        itemCount: validIndices.length,
        itemBuilder: (context, gridIndex) {
          final pageIndex = validIndices[gridIndex];
          return _buildPageCard(pageIndex, isDarkMode, key: ObjectKey(widget.canvasCtrl.pagesScreenshotControllers[pageIndex]));
        },
      );
    }

    return ReorderableGridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.72, 
      ),
      itemCount: validIndices.length,
      onReorder: (oldIndex, newIndex) {
        _handleReorder(validIndices[oldIndex], validIndices[newIndex]);
      },
      itemBuilder: (context, gridIndex) {
        final pageIndex = validIndices[gridIndex];
        return _buildPageCard(pageIndex, isDarkMode, key: ObjectKey(widget.canvasCtrl.pagesScreenshotControllers[pageIndex]));
      },
    );
  }

  Widget _buildPageCard(int index, bool isDarkMode, {Key? key}) {
    bool isCurrent = widget.canvasCtrl.currentPageIndex == index;
    bool isSelected = _selectedPages.contains(index);
    bool isBookmarked = widget.canvasCtrl.pagesBookmarks[index];

    return GestureDetector(
      key: key,
      onTap: () {
        if (_isMultiSelectMode) {
          _toggleSelection(index);
        } else {
          widget.canvasCtrl.jumpToPage(index);
          Navigator.pop(context);
        }
      },
      child: AnimatedScale(
        scale: isSelected ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFFFF7F6A) 
                  : (isCurrent ? Colors.blue.withAlpha(120) : (isDarkMode ? Colors.white10 : Colors.black12)),
              width: isSelected || isCurrent ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? const Color(0xFFFF7F6A).withAlpha(40) : Colors.black.withAlpha(isDarkMode ? 30 : 5),
                blurRadius: isSelected ? 16 : 12,
                spreadRadius: isSelected ? 2 : 0,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Inner content (Thumbnail)
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildLazyThumbnail(index, isDarkMode),
                      
                      // Darken if selected
                      if (isSelected)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          color: const Color(0xFFFF7F6A).withAlpha(20),
                        ),
                    ],
                  ),
                ),

                // Top right actions: Bookmark
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () {
                      widget.canvasCtrl.pagesBookmarks[index] = !isBookmarked;
                      widget.canvasCtrl.saveStrokes(); 
                      setState((){});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black.withAlpha(150) : Colors.white.withAlpha(220),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)],
                      ),
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        size: 16,
                        color: isBookmarked ? Colors.amber : (isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                ),

                // Top left: Selection Checkmark
                if (_isMultiSelectMode)
                  Positioned(
                    top: 8, left: 8,
                    child: AnimatedScale(
                      scale: isSelected ? 1.0 : 0.8,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFF7F6A) : (isDarkMode ? Colors.black54 : Colors.white70),
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? const Color(0xFFFF7F6A) : Colors.grey.withAlpha(100), width: 1.5),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.check, size: 14, color: isSelected ? Colors.white : Colors.transparent),
                        ),
                      ),
                    ),
                  ),

                // Bottom strip overlay (Page Number & Menu)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withAlpha(isDarkMode ? 220 : 150),
                          Colors.transparent,
                        ],
                      )
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Glassmorphic badge for page number
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                border: Border.all(color: Colors.white.withAlpha(50), width: 0.5),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        
                        if (!_isMultiSelectMode)
                          GestureDetector(
                            onTapDown: (details) => _showBeautifulContextMenu(context, index, details.globalPosition, isDarkMode),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.moreHorizontal, size: 18, color: Colors.white),
                            ),
                          ),
                      ],
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

  void _showBeautifulContextMenu(BuildContext context, int index, Offset position, bool isDarkMode) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
      elevation: 12,
      shadowColor: Colors.black.withAlpha(50),
      items: [
        _buildPopupItem('add_outline', 'إضافة للمخطط', LucideIcons.heading, isDarkMode),
        const PopupMenuDivider(),
        _buildPopupItem('add_before', 'إضافة صفحة قبل', LucideIcons.arrowUpToLine, isDarkMode),
        _buildPopupItem('add_after', 'إضافة صفحة بعد', LucideIcons.arrowDownToLine, isDarkMode),
        const PopupMenuDivider(),
        _buildPopupItem('duplicate', 'تكرار الصفحة', LucideIcons.copy, isDarkMode),
        _buildPopupItem('clear', 'تفريغ المحتوى', LucideIcons.eraser, isDarkMode),
        const PopupMenuDivider(),
        _buildPopupItem('delete', 'حذف الصفحة', LucideIcons.trash2, isDarkMode, isDestructive: true),
      ],
    ).then((action) {
      if (action != null) _handleSinglePageAction(action, index);
    });
  }

  PopupMenuItem<String> _buildPopupItem(String value, String title, IconData icon, bool isDarkMode, {bool isDestructive = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? Colors.redAccent : (isDarkMode ? Colors.white70 : Colors.black87)),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : (isDarkMode ? Colors.white : Colors.black87), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLazyThumbnail(int index, bool isDarkMode) {
    final cachedBytes = widget.canvasCtrl.pageThumbnails[index];
    if (cachedBytes != null) {
      return Image.memory(cachedBytes, fit: BoxFit.cover);
    }

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: Container(
          width: 700,
          height: 900,
          color: isDarkMode ? Colors.black : Colors.white,
          child: Stack(
            children: [
               if (widget.canvasCtrl.pdfDocument != null && widget.canvasCtrl.pdfPageMapping[index] != null)
                 Positioned.fill(
                   child: PdfPageBackground(
                     document: widget.canvasCtrl.pdfDocument!,
                     pageNumber: widget.canvasCtrl.pdfPageMapping[index]!,
                   ),
                 ),
               CustomPaint(
                  size: const Size(700, 900),
                  painter: ThumbnailVectorPainter(
                    widget.canvasCtrl.pagesPoints[index],
                    widget.canvasCtrl.pagesShapes[index],
                    widget.canvasCtrl.pagesTables[index],
                    isDarkMode: isDarkMode,
                  ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSinglePageAction(String action, int index) {
    if (action == 'add_outline') {
      _promptAddOutline(index);
    } else if (action == 'add_before') {
      widget.canvasCtrl.addBlankPageAt(index);
    } else if (action == 'add_after') {
      widget.canvasCtrl.addBlankPageAt(index + 1);
    } else if (action == 'duplicate') {
      widget.canvasCtrl.duplicatePage(index);
    } else if (action == 'clear') {
      widget.canvasCtrl.clearPage(index);
    } else if (action == 'delete') {
      widget.canvasCtrl.deletePage(index);
    }
  }

  void _promptAddOutline(int index) {
    String outlineTitle = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة عنوان للمخطط', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'أدخل عنوان هذه الصفحة',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withAlpha(10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => outlineTitle = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F6A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              if (outlineTitle.trim().isNotEmpty) {
                widget.canvasCtrl.pagesOutlines[index] = outlineTitle.trim();
                widget.canvasCtrl.saveStrokes();
                widget.canvasCtrl.notifyListeners();
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineView(bool isDarkMode) {
    final outlineEntries = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.canvasCtrl.pagesOutlines.length; i++) {
      if (widget.canvasCtrl.pagesOutlines[i] != null) {
        outlineEntries.add({
          'index': i,
          'title': widget.canvasCtrl.pagesOutlines[i]!,
        });
      }
    }

    if (outlineEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.list, size: 48, color: isDarkMode ? Colors.white54 : Colors.black38),
            ),
            const SizedBox(height: 24),
            Text(
              'لا يوجد مخطط مضاف',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف المخططات عبر خيارات الصفحة لسهولة التنقل',
              style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: outlineEntries.length,
      itemBuilder: (context, idx) {
        final entry = outlineEntries[idx];
        final pageIndex = entry['index'] as int;
        final title = entry['title'] as String;
        return _buildOutlineCard(pageIndex, title, isDarkMode);
      },
    );
  }

  Widget _buildOutlineCard(int index, String title, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black.withAlpha(10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(isDarkMode? 10 : 3), blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            widget.canvasCtrl.jumpToPage(index);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7F6A).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFFF7F6A)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 20),
                  splashRadius: 20,
                  onPressed: () {
                    widget.canvasCtrl.pagesOutlines[index] = null;
                    widget.canvasCtrl.saveStrokes();
                    setState((){});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionBar(bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black.withAlpha(200) : Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDarkMode ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 24, offset: const Offset(0, 8))
            ]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(
                 icon: LucideIcons.copy, 
                 label: 'تكرار', 
                 isDarkMode: isDarkMode,
                 onTap: _selectedPages.isEmpty ? null : () {
                   final sorted = _selectedPages.toList()..sort();
                   for (int i = sorted.length - 1; i >= 0; i--) {
                     widget.canvasCtrl.duplicatePage(sorted[i]);
                   }
                   setState(() => _isMultiSelectMode = false);
                 }),
              
              _actionButton(
                 icon: LucideIcons.share, 
                 label: 'تصدير', 
                 isDarkMode: isDarkMode,
                 onTap: _selectedPages.isEmpty ? null : () {
                   final sorted = _selectedPages.toList()..sort();
                   Navigator.pop(context);
                   widget.canvasCtrl.shareAsPdf(pageIndices: sorted);
                 }),

              _actionButton(
                 icon: LucideIcons.trash2, 
                 label: 'حذف', 
                 color: Colors.redAccent,
                 isDarkMode: isDarkMode,
                 onTap: _selectedPages.isEmpty ? null : () {
                   widget.canvasCtrl.deleteSelectedPages(_selectedPages.toList());
                   setState(() {
                     _isMultiSelectMode = false;
                     _selectedPages.clear();
                   });
                 }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required bool isDarkMode, VoidCallback? onTap, Color? color}) {
    final activeColor = color ?? (isDarkMode ? Colors.white : Colors.black87);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.3 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: activeColor, size: 22),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: activeColor, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class ThumbnailVectorPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  final List<PageShape> shapes;
  final List<PageTable> tables;
  final bool isDarkMode;

  ThumbnailVectorPainter(this.points, this.shapes, this.tables, {required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final ptPaint = points[i]!.paint;
        final paint = Paint()
          ..color = getSmartColor(ptPaint.color, isDarkMode)
          ..strokeWidth = ptPaint.strokeWidth
          ..strokeCap = ptPaint.strokeCap
          ..strokeJoin = ptPaint.strokeJoin
          ..style = ptPaint.style;
        canvas.drawLine(points[i]!.offset, points[i + 1]!.offset, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        final ptPaint = points[i]!.paint;
        final paint = Paint()
          ..color = getSmartColor(ptPaint.color, isDarkMode)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(points[i]!.offset, ptPaint.strokeWidth / 2, paint);
      }
    }

    final shapePainter = ShapePainter(shapes, null, const PageTemplate(type: CanvasBackgroundType.blank), isDarkMode: isDarkMode, version: 0);
    shapePainter.paint(canvas, size);

    final tablePainter = TablePainter(tables: tables, currentTable: null);
    tablePainter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
