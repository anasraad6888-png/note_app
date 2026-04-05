import 'package:flutter/material.dart';
import '../../canvas_widgets/text_toolbar_dock.dart';


class SlideFadeIn extends StatefulWidget {
  final Widget child;
  const SlideFadeIn({required this.child});

  @override
  State<SlideFadeIn> createState() => SlideFadeInState();
}

class SlideFadeInState extends State<SlideFadeIn>
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

class ScopedMenuAnchor<T> extends StatelessWidget {
  final Offset offset;
  final String groupId;
  final String displayValue;
  final List<T> items;
  final String Function(T) itemLabel;
  final TextStyle Function(T)? itemStyle;
  final void Function(T) onSelected;

  const ScopedMenuAnchor({
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