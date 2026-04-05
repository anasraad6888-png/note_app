import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A compact, elegant color picker designed specifically for the text
/// inspector window (fits within ~185px of height).
class InspectorColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final bool isDarkMode;

  const InspectorColorPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<InspectorColorPicker> createState() => _InspectorColorPickerState();
}

class _InspectorColorPickerState extends State<InspectorColorPicker> {
  late Color _selected;
  late TextEditingController _hexCtrl;

  // ── Curated palette (10 cols × 5 rows) ──────────────────────────────────
  static const List<List<Color>> _palette = [
    // Row 0 — Neutrals & transparent
    [
      Color(0xFFFFFFFF), Color(0xFFEEEEEE), Color(0xFFBDBDBD), Color(0xFF9E9E9E),
      Color(0xFF757575), Color(0xFF616161), Color(0xFF424242), Color(0xFF212121),
      Color(0xFF000000), Color(0x00000000),
    ],
    // Row 1 — Reds & Pinks
    [
      Color(0xFFFFCDD2), Color(0xFFEF9A9A), Color(0xFFEF5350), Color(0xFFD32F2F),
      Color(0xFFB71C1C), Color(0xFFF48FB1), Color(0xFFF06292), Color(0xFFC2185B),
      Color(0xFF880E4F), Color(0xFFFF4081),
    ],
    // Row 2 — Oranges & Yellows
    [
      Color(0xFFFFCCBC), Color(0xFFFF8A65), Color(0xFFFF5722), Color(0xFFE64A19),
      Color(0xFFBF360C), Color(0xFFFFF9C4), Color(0xFFFFEE58), Color(0xFFFDD835),
      Color(0xFFF9A825), Color(0xFFFF6F00),
    ],
    // Row 3 — Greens & Teals
    [
      Color(0xFFC8E6C9), Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF388E3C),
      Color(0xFF1B5E20), Color(0xFFB2EBF2), Color(0xFF4DD0E1), Color(0xFF0097A7),
      Color(0xFF006064), Color(0xFF00C853),
    ],
    // Row 4 — Blues & Purples
    [
      Color(0xFFBBDEFB), Color(0xFF64B5F6), Color(0xFF2196F3), Color(0xFF1565C0),
      Color(0xFF0D47A1), Color(0xFFE1BEE7), Color(0xFFAB47BC), Color(0xFF7B1FA2),
      Color(0xFF4A148C), Color(0xFF6200EA),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.pickerColor;
    _hexCtrl = TextEditingController(text: _colorToHex(_selected));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    if (c.a == 0) return 'شفاف';
    return c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  Color? _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
      if (clean.length == 8) return Color(int.parse(clean, radix: 16));
    } catch (_) {}
    return null;
  }

  void _pick(Color c) {
    setState(() {
      _selected = c;
      _hexCtrl.text = _colorToHex(c);
    });
    widget.onColorChanged(c);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textColor = isDark ? const Color(0xDEFFFFFF) : Colors.black87;
    final subColor = isDark ? Colors.white38 : Colors.black38;
    final fieldBg = isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF0F0F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Preview + Hex input ──────────────────────────────────────────
        Row(
          children: [
            // Color circle
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selected.a == 0 ? Colors.transparent : _selected,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black.withAlpha(20),
                    width: 1.5,
                  ),
                  // Checkerboard for transparent
                ),
                child: _selected.a == 0
                    ? ClipOval(
                        child: CustomPaint(painter: _CheckerPainter()),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Hex field
            Expanded(
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('#', style: TextStyle(color: subColor, fontSize: 12)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: TextField(
                        controller: _hexCtrl,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9a-fA-F]'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v.length == 6) {
                            final c = _hexToColor(v);
                            if (c != null) {
                              setState(() => _selected = c);
                              widget.onColorChanged(c);
                            }
                          }
                        },
                        onSubmitted: (v) {
                          final c = _hexToColor(v);
                          if (c != null) _pick(c);
                        },
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Hue slider reading as color dot column (quick hue pick)
            _buildHueStrip(isDark),
          ],
        ),

        const SizedBox(height: 10),

        // ── Color swatches grid ──────────────────────────────────────────
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _palette.map((row) => _buildRow(row)).toList(),
          ),
        ),
      ],
    );
  }

  // Compact vertical hue strip
  Widget _buildHueStrip(bool isDark) {
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localY = d.localPosition.dy.clamp(0, 100);
        final hue = (localY / 100) * 360;
        _pick(HSVColor.fromAHSV(1, hue, 1, 1).toColor());
      },
      onTapDown: (d) {
        final localY = d.localPosition.dy.clamp(0, 100);
        final hue = (localY / 100.0) * 360;
        _pick(HSVColor.fromAHSV(1, hue, 1, 1).toColor());
      },
      child: Container(
        width: 16,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
          ),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<Color> colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: colors.map((c) => _buildSwatch(c)).toList(),
    );
  }

  Widget _buildSwatch(Color c) {
    final isSelected = _selected.value == c.value;
    final isTransparent = c.a == 0;

    return GestureDetector(
      onTap: () => _pick(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isTransparent ? null : c,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : (widget.isDarkMode ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.a == 0 ? Colors.grey.withAlpha(80) : c.withAlpha(120),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isTransparent
            ? ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: CustomPaint(painter: _CheckerPainter()),
              )
            : isSelected
                ? Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: c.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white,
                    ),
                  )
                : null,
      ),
    );
  }
}

// Checkerboard painter for transparent swatches
class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const sq = 4.0;
    final p1 = Paint()..color = Colors.white;
    final p2 = Paint()..color = const Color(0xFFCCCCCC);
    canvas.drawRect(Offset.zero & size, p1);
    for (double y = 0; y < size.height; y += sq) {
      for (double x = 0; x < size.width; x += sq) {
        final isEven = ((x / sq) + (y / sq)).toInt().isEven;
        if (!isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, sq, sq), p2);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter old) => false;
}
