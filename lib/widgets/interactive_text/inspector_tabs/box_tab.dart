import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BoxTab extends StatelessWidget {
  final bool isDarkMode;
  final dynamic textData;
  final VoidCallback onDataChanged;

  const BoxTab({
    Key? key,
    required this.isDarkMode,
    required this.textData,
    required this.onDataChanged,
  }) : super(key: key);

  List<Color> get _bgColors => [
        Colors.transparent,
        Colors.yellow.shade200,
        Colors.blue.shade100,
        Colors.green.shade100,
        Colors.pink.shade100,
        Colors.purple.shade100,
        Colors.orange.shade100,
      ];

  List<Color> get _borderColors => [
        Colors.transparent,
        Colors.black,
        Colors.grey,
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.purple,
      ];

  @override
  Widget build(BuildContext context) {
    final label = TextStyle(
      color: isDarkMode ? Colors.white54 : Colors.black45,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Background colors ────────────────────────────────────────────
        Text("لون الخلفية", style: label),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _bgColors
              .map((c) => _buildSwatch(
                    color: c,
                    isSelected: textData.fillColor == c,
                    isCircle: false,
                    onTap: () {
                      textData.fillColor = c;
                      onDataChanged();
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        // ── Border colors ─────────────────────────────────────────────────
        Text("لون الإطار", style: label),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _borderColors
              .map((c) => _buildSwatch(
                    color: c,
                    isSelected: textData.borderColor == c,
                    isCircle: true,
                    onTap: () {
                      textData.borderColor = c;
                      textData.borderWidth = c == Colors.transparent ? 0.0 : 2.0;
                      onDataChanged();
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        // ── Border radius slider ─────────────────────────────────────────
        Row(
          children: [
            Text("الزوايا", style: label),
            const Spacer(),
            Text(
              "${textData.borderRadius.round()}",
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: const Color(0xFFFF7F6A),
            inactiveTrackColor:
                isDarkMode ? Colors.white12 : Colors.black.withAlpha(12),
            thumbColor: const Color(0xFFFF7F6A),
          ),
          child: Slider(
            value: textData.borderRadius,
            min: 0,
            max: 32,
            divisions: 8,
            onChanged: (val) {
              textData.borderRadius = val;
              onDataChanged();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSwatch({
    required Color color,
    required bool isSelected,
    required bool isCircle,
    required VoidCallback onTap,
  }) {
    final isTransparent = color == Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isTransparent ? null : color,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(7),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF7F6A)
                : (isDarkMode ? Colors.white.withAlpha(50) : Colors.black.withAlpha(20)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected && !isTransparent
              ? [
                  BoxShadow(
                    color: color.withAlpha(100),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isTransparent
            ? Center(
                child: Icon(
                  LucideIcons.ban,
                  size: 14,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              )
            : isSelected
                ? Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white,
                    ),
                  )
                : null,
      ),
    );
  }
}
