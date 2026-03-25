import 'package:flutter/material.dart';
import '../models/canvas_models.dart';
import '../painters/canvas_painters.dart';

class InteractiveShapeWidget extends StatefulWidget {
  final PageShape shape;
  final int pageIndex;
  final bool readOnly;
  final bool isDarkMode;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const InteractiveShapeWidget({
    super.key,
    required this.shape,
    required this.pageIndex,
    required this.onSave,
    required this.onDelete,
    required this.onUpdate,
    this.readOnly = false,
    this.isDarkMode = false,
  });

  @override
  State<InteractiveShapeWidget> createState() => _InteractiveShapeWidgetState();
}

class _InteractiveShapeWidgetState extends State<InteractiveShapeWidget> {
  bool isSelected = false;

  Widget _buildHandle({
    required Widget child,
    required Color color,
    required Color borderColor,
    VoidCallback? onTap,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragStartCallback? onPanStart,
    VoidCallback? onPanEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: (_) {
        if (onPanEnd != null) onPanEnd();
        widget.onSave();
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          padding: const EdgeInsets.all(4),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.shape;
    return Positioned(
      left: shape.rect.left - 50,
      top: shape.rect.top - 50,
      width: shape.rect.width + 100,
      height: shape.rect.height + 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Visible Shape Layer
          Positioned(
            left: 50,
            top: 50,
            width: shape.rect.width,
            height: shape.rect.height,
            child: IgnorePointer(
              child: CustomPaint(
                painter: LocalShapePainter(shape, widget.isDarkMode),
                size: Size.infinite,
              ),
            ),
          ),
          
          // Invisible touch target over the shape
          Positioned(
            left: 50,
            top: 50,
            width: shape.rect.width,
            height: shape.rect.height,
            child: GestureDetector(
              onTapUp: widget.readOnly ? null : (_) {
                setState(() => isSelected = true);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: isSelected
                      ? Border.all(color: const Color(0xFFFF7F6A).withValues(alpha: 0.5), width: 1.5, style: BorderStyle.solid)
                      : null,
                ),
              ),
            ),
          ),
          
          if (isSelected && !widget.readOnly)
            Positioned(
              top: 50 - 20,
              left: 50 - 20,
              child: _buildHandle(
                color: Colors.white,
                borderColor: Colors.grey.shade300,
                onPanUpdate: (details) {
                  setState(() {
                    shape.rect = shape.rect.shift(details.delta);
                  });
                  widget.onUpdate();
                },
                child: const Icon(Icons.drag_indicator, size: 14, color: Colors.blue),
              ),
            ),
            
          if (isSelected && !widget.readOnly)
            Positioned(
              top: 50 - 20,
              right: 50 - 20,
              child: _buildHandle(
                color: Colors.white,
                borderColor: Colors.red.shade200,
                onTap: widget.onDelete,
                child: const Icon(Icons.close, size: 14, color: Colors.red),
              ),
            ),
            
          if (isSelected && !widget.readOnly)
            Positioned(
              bottom: 50 - 20,
              left: 50 - 20,
              child: _buildHandle(
                color: Colors.white,
                borderColor: Colors.grey.shade300,
                onPanUpdate: (details) {
                  setState(() {
                    double newWidth = shape.rect.width - details.delta.dx;
                    double newHeight = shape.rect.height + details.delta.dy;
                    if (newWidth < 20) newWidth = 20;
                    if (newHeight < 20) newHeight = 20;

                    double deltaX = shape.rect.width - newWidth;
                    shape.rect = Rect.fromLTWH(
                      shape.rect.left + deltaX,
                      shape.rect.top,
                      newWidth,
                      newHeight,
                    );
                  });
                  widget.onUpdate();
                },
                child: const Icon(Icons.aspect_ratio, size: 14, color: Colors.grey),
              ),
            ),

          if (isSelected && !widget.readOnly)
            Positioned(
              bottom: 50 - 20,
              right: 50 - 20,
              child: _buildHandle(
                color: Colors.white,
                borderColor: Colors.grey.shade300,
                onPanUpdate: (details) {
                  setState(() {
                    double newWidth = shape.rect.width + details.delta.dx;
                    double newHeight = shape.rect.height + details.delta.dy;
                    if (newWidth < 20) newWidth = 20;
                    if (newHeight < 20) newHeight = 20;

                    shape.rect = Rect.fromLTWH(
                      shape.rect.left,
                      shape.rect.top,
                      newWidth,
                      newHeight,
                    );
                  });
                  widget.onUpdate();
                },
                child: const Icon(Icons.aspect_ratio, size: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

class LocalShapePainter extends CustomPainter {
  final PageShape shape;
  final bool isDarkMode;
  final PageTemplate template;

  LocalShapePainter(this.shape, this.isDarkMode, [PageTemplate? template])
      : template = template ?? PageTemplate(type: CanvasBackgroundType.blank);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-shape.rect.left, -shape.rect.top);
    ShapePainter([shape], null, template, isDarkMode: isDarkMode, version: 0).paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LocalShapePainter old) => true;
}
