import 'package:flutter/material.dart';
import '../../models/note_document.dart';

class EditTitleDialog {
  static void show({
    required BuildContext context,
    required NoteDocument document,
    required bool isDarkMode,
    required VoidCallback onSave,
  }) {
    final controller = TextEditingController(text: document.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
          title: Text(
            'إعادة تسمية المستند',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isDarkMode ? Colors.white : null),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: isDarkMode ? Colors.white : null),
            decoration: InputDecoration(
              hintText: 'أدخل الاسم الجديد',
              hintStyle: TextStyle(color: isDarkMode ? Colors.white60 : null),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(color: isDarkMode ? Colors.white70 : null),
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  document.title = controller.text.trim();
                  onSave();
                }
                Navigator.pop(context);
              },
              child: Text(
                'حفظ',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFFFF7F6A) : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
