import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ProCompactColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ProCompactColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  State<ProCompactColorPicker> createState() => _ProCompactColorPickerState();
}

class _ProCompactColorPickerState extends State<ProCompactColorPicker> {
  late HSVColor currentHsvColor;
  late TextEditingController hexController;

  static const List<Color> curatedColors = [
    // Greys / Neutrals
    Color(0xFF000000), Color(0xFF334155), Color(0xFF64748B), Color(0xFF94A3B8), Color(0xFFE2E8F0), Color(0xFFFFFFFF),
    // Reds/Oranges
    Color(0xFF7F1D1D), Color(0xFFDC2626), Color(0xFFF87171), Color(0xFFC2410C), Color(0xFFF97316), Color(0xFFFB923C),
    // Yellows/Greens
    Color(0xFF854D0E), Color(0xFFEAB308), Color(0xFFFDE047), Color(0xFF14532D), Color(0xFF16A34A), Color(0xFF4ADE80),
    // Blues
    Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF60A5FA), Color(0xFF0C4A6E), Color(0xFF0284C7), Color(0xFF38BDF8),
    // Purples/Pinks
    Color(0xFF3B0764), Color(0xFF9333EA), Color(0xFFD8B4FE), Color(0xFF831843), Color(0xFFDB2777), Color(0xFFF472B6),
  ];

  @override
  void initState() {
    super.initState();
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
    hexController = TextEditingController(text: colorToHex(widget.pickerColor, enableAlpha: false).toUpperCase());
  }

  void _updateColor(Color color) {
    setState(() {
      currentHsvColor = HSVColor.fromColor(color);
      hexController.text = colorToHex(color, enableAlpha: false).toUpperCase();
    });
    widget.onColorChanged(color);
  }

  void _onHsvChanged(HSVColor color) {
    setState(() {
      currentHsvColor = color;
      hexController.text = colorToHex(color.toColor(), enableAlpha: false).toUpperCase();
    });
    widget.onColorChanged(color.toColor());
  }

  @override
  void dispose() {
    hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 520,
      height: 250, // Adjusted height for top/bottom split
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Part: Controls and Sliders side-by-side
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Indicator & HEX
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: currentHsvColor.toColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: currentHsvColor.toColor().withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '#',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: hexController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                onSubmitted: (value) {
                                  final color = colorFromHex(value);
                                  if (color != null) {
                                    _updateColor(color);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Right: Sliders (Close to each other)
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24, // Thinner sleek slider
                      child: ColorPickerSlider(
                        TrackType.hue,
                        currentHsvColor,
                        _onHsvChanged,
                        displayThumbColor: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 24,
                      child: ColorPickerSlider(
                        TrackType.value,
                        currentHsvColor,
                        _onHsvChanged,
                        displayThumbColor: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Bottom Part: Full Width Color Grid (larger squares)
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: curatedColors.length,
              itemBuilder: (context, index) {
                final color = curatedColors[index];
                final isSelected = currentHsvColor.toColor().value == color.value;
                
                return GestureDetector(
                  onTap: () => _updateColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10), // Larger radius for larger size
                      border: Border.all(
                        color: isSelected 
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.black.withValues(alpha: 0.1),
                        width: isSelected ? 3 : 1, // Thicker border on selection to fit larger size
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                    child: isSelected 
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                          size: 18,
                        )
                      : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
