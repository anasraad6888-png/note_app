import 'package:flutter/material.dart';

// A premium, beautifully redesigned Material Color Picker.
class CustomSplitMaterialPicker extends StatefulWidget {
  const CustomSplitMaterialPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.onPrimaryChanged,
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<Color>? onPrimaryChanged;

  @override
  State<StatefulWidget> createState() => _CustomSplitMaterialPickerState();
}

class _CustomSplitMaterialPickerState extends State<CustomSplitMaterialPicker> {
  final List<List<Color>> _colorTypes = [
    [Colors.red, Colors.redAccent],
    [Colors.pink, Colors.pinkAccent],
    [Colors.purple, Colors.purpleAccent],
    [Colors.deepPurple, Colors.deepPurpleAccent],
    [Colors.indigo, Colors.indigoAccent],
    [Colors.blue, Colors.blueAccent],
    [Colors.lightBlue, Colors.lightBlueAccent],
    [Colors.cyan, Colors.cyanAccent],
    [Colors.teal, Colors.tealAccent],
    [Colors.green, Colors.greenAccent],
    [Colors.lightGreen, Colors.lightGreenAccent],
    [Colors.lime, Colors.limeAccent],
    [Colors.yellow, Colors.yellowAccent],
    [Colors.amber, Colors.amberAccent],
    [Colors.orange, Colors.orangeAccent],
    [Colors.deepOrange, Colors.deepOrangeAccent],
    [Colors.brown],
    [Colors.grey],
    [Colors.blueGrey],
    [Colors.black],
  ];

  List<Color> _currentColorType = [Colors.red, Colors.redAccent];
  Color _currentShading = Colors.transparent;

  List<Map<Color, String>> _shadingTypes(List<Color> colors) {
    List<Map<Color, String>> result = [];
    for (Color colorType in colors) {
      if (colorType == Colors.grey) {
        result.addAll([50, 100, 200, 300, 350, 400, 500, 600, 700, 800, 850, 900]
            .map((int shade) => {Colors.grey[shade]!: shade.toString()})
            .toList());
      } else if (colorType == Colors.black || colorType == Colors.white) {
        result.addAll([
          {Colors.black: ''},
          {Colors.white: ''}
        ]);
      } else if (colorType is MaterialAccentColor) {
        result.addAll([100, 200, 400, 700].map((int shade) => {colorType[shade]!: 'A$shade'}).toList());
      } else if (colorType is MaterialColor) {
        result.addAll([50, 100, 200, 300, 400, 500, 600, 700, 800, 900]
            .map((int shade) => {colorType[shade]!: shade.toString()})
            .toList());
      } else {
        result.add({const Color(0x00000000): ''});
      }
    }
    return result;
  }

  @override
  void initState() {
    for (List<Color> _colors in _colorTypes) {
      for (var color in _shadingTypes(_colors)) {
        if (widget.pickerColor.value == color.keys.first.value) {
          _currentColorType = _colors;
          _currentShading = color.keys.first;
          break; // Optimization
        }
      }
    }
    super.initState();
  }

  bool useWhiteForeground(Color backgroundColor) =>
      1.05 / (backgroundColor.computeLuminance() + 0.05) > 4.5;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 420,
      height: 380, // slightly slicker height
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Sleek Grid of Primary Colors
          SizedBox(
            width: 90, // Room for 2 columns nicely spaced
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12, // More elegant spacing
                mainAxisSpacing: 12,
              ),
              itemCount: _colorTypes.length,
              itemBuilder: (context, index) {
                final colors = _colorTypes[index];
                final mainColor = colors[0];
                final isSelected = _currentColorType == colors;

                return GestureDetector(
                  onTap: () {
                    if (widget.onPrimaryChanged != null) widget.onPrimaryChanged!(mainColor);
                    setState(() {
                      _currentColorType = colors;
                      // Optional: Auto-select a middle shade when switching families
                      _currentShading = _shadingTypes(colors).first.keys.first;
                      widget.onColorChanged(_currentShading);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.all(isSelected ? 3 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? (isDark ? Colors.white : Colors.black87) 
                            : (isDark ? Colors.white12 : Colors.black12),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: mainColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ] : [],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mainColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Elegant Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: VerticalDivider(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 1,
              thickness: 1,
            ),
          ),

          // Right Side: Minimalist Shades List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 8),
              itemCount: _shadingTypes(_currentColorType).length,
              itemBuilder: (context, index) {
                final shadeMap = _shadingTypes(_currentColorType)[index];
                final shadeColor = shadeMap.keys.first;
                final isSelected = _currentShading == shadeColor;

                return GestureDetector(
                  onTap: () {
                    setState(() => _currentShading = shadeColor);
                    widget.onColorChanged(shadeColor);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: EdgeInsets.only(
                      bottom: 8, 
                      left: isSelected ? 0 : 12, // Bulges out when selected
                      right: isSelected ? 0 : 12,
                    ),
                    height: 32, // Sleek rect
                    decoration: BoxDecoration(
                      color: shadeColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? (isDark ? Colors.white : Colors.black)
                            : Colors.transparent,
                        width: isSelected ? 2 : 0,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: shadeColor.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ] : [
                         BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: isSelected 
                        ? Icon(
                            Icons.check,
                            color: shadeColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
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
