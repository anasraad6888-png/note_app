import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExportDialog {
  static void show({
    required BuildContext context,
    required bool isDarkMode,
    required VoidCallback onExportImage,
    required VoidCallback onExportPdf,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : null,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onExportImage();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.image, color: Colors.blue),
                      const SizedBox(width: 16),
                      Text(
                        'حفظ كصورة في المعرض (الصفحة الحالية)',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onExportPdf();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.filePlus, color: Colors.purple),
                      const SizedBox(width: 16),
                      Text(
                        'مشاركة الجميع كملف PDF',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
