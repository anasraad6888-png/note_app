import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../interactive_text_widget.dart'; // Assumed location of TextPreset if it still resides there

class PresetsTab extends StatelessWidget {
  final quill.QuillController quillController;
  final dynamic textData;
  final bool isDarkMode;
  final List<TextPreset> savedPresets;
  final Function(TextPreset) onPresetSaved;
  final VoidCallback onDataChanged;

  const PresetsTab({
    Key? key,
    required this.quillController,
    required this.textData,
    required this.isDarkMode,
    required this.savedPresets,
    required this.onPresetSaved,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              final currentStyle = quillController.getSelectionStyle();
              final newPreset = TextPreset(
                fillColor: textData.fillColor,
                borderColor: textData.borderColor,
                borderWidth: textData.borderWidth,
                borderRadius: textData.borderRadius,
                textAttributes: Map.from(currentStyle.attributes),
              );
              onPresetSaved(newPreset);
            },
            icon: const Icon(Icons.bookmark_add, size: 16),
            label: const Text("حفظ التنسيق كنمط"),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.blue.withAlpha(150),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: 16),
          if (savedPresets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("لا توجد أنماط محفوظة", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: savedPresets.map((preset) {
                return GestureDetector(
                  onTap: () {
                    if (!quillController.selection.isCollapsed) {
                      preset.textAttributes.forEach((key, attribute) {
                        quillController.formatSelection(attribute);
                      });
                    } else {
                      textData.fillColor = preset.fillColor;
                      textData.borderColor = preset.borderColor;
                      textData.borderWidth = preset.borderWidth;
                      textData.borderRadius = preset.borderRadius;
                      
                      final fullDocLength = quillController.document.length;
                      preset.textAttributes.forEach((key, attribute) {
                        quillController.formatText(0, fullDocLength, attribute);
                      });
                    }
                    onDataChanged();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: preset.fillColor,
                      border: Border.all(
                        color: preset.borderColor == Colors.transparent
                            ? (isDarkMode ? Colors.white24 : Colors.black12)
                            : preset.borderColor,
                        width: preset.borderWidth == 0 ? 1 : preset.borderWidth,
                      ),
                      borderRadius: BorderRadius.circular(
                        preset.borderRadius == 0 ? 4 : preset.borderRadius,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Aa",
                      style: TextStyle(
                        fontFamily: preset.textAttributes['font']?.value?.toString(),
                        color: preset.textAttributes['color']?.value != null
                            ? (preset.textAttributes['color']!.value is String
                                ? Color(int.parse((preset.textAttributes['color']!.value as String).replaceFirst('#', '0xFF')))
                                : null)
                            : (preset.fillColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white),
                        fontWeight: preset.textAttributes['bold']?.value == true ? FontWeight.bold : FontWeight.w600,
                        fontStyle: preset.textAttributes['italic']?.value == true ? FontStyle.italic : FontStyle.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
