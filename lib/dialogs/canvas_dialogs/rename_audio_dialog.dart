import 'package:flutter/material.dart';

import '../../controllers/audio_controller.dart';

class RenameAudioDialog {
  static void showRenameAudioDialog({
    required BuildContext context,
    required bool isDarkMode,
    required int index,
    required AudioController audioCtrl,
  }) {
    String currentName = audioCtrl.document.audioMetadata[index]['name'] ?? '';
    TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : null,
        title: Text(
          'إعادة تسمية التسجيل',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'اسم التسجيل الجديد',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
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
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                audioCtrl.renameRecording(index, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
