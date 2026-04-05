import 'package:flutter/material.dart';
import 'dart:ui';

class InspectorOverlayFrame extends StatelessWidget {
  final Offset inspectorPosition;
  final bool isDragging;
  final bool isDarkMode;
  final int activeTab;
  final VoidCallback onClose;
  final VoidCallback onPanStart;
  final Function(Offset) onPanUpdate;
  final VoidCallback onPanEnd;
  final String tapGroupId;
  final Widget child;

  const InspectorOverlayFrame({
    Key? key,
    required this.inspectorPosition,
    required this.isDragging,
    required this.isDarkMode,
    required this.activeTab,
    required this.onClose,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.tapGroupId,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: inspectorPosition.dx,
      top: inspectorPosition.dy,
      child: GestureDetector(
        onPanStart: (_) => onPanStart(),
        onPanUpdate: (details) => onPanUpdate(details.delta),
        onPanEnd: (_) => onPanEnd(),
        onPanCancel: () => onPanEnd(),
        child: TapRegion(
          groupId: tapGroupId,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 270,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1A1A1E).withAlpha(210)
                        : Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withAlpha(22)
                          : Colors.black.withAlpha(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDarkMode ? 60 : 25),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
