import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class CustomColorPickerDialog {
  static void showCustomColorPicker({
    required BuildContext context,
    required bool isDarkMode,
    required Color initialColor,
    required Function(Color) onColorChanged,
  }) {
    Color selectedColor = initialColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
        title: Text(
          'اختر اللون',
          textAlign: TextAlign.right,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Theme(
                data: isDarkMode
                    ? ThemeData.dark().copyWith(
                        canvasColor: const Color(0xFF2C2C2E),
                      )
                    : ThemeData.light(),
                child: ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) => selectedColor = color,
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha: true,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  onColorChanged(const Color(0x00000000));
                  Navigator.pop(context);
                },
                child: Text(
                  'بدون لون (شفاف)',
                  style: TextStyle(
                    color: isDarkMode ? Colors.redAccent.shade100 : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: isDarkMode ? Colors.white70 : null),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F6A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              onColorChanged(selectedColor);
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
