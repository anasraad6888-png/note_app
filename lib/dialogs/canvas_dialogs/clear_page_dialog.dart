import 'package:flutter/material.dart';

class ClearPageDialog {
  static void show({
    required BuildContext context,
    required bool isDarkMode,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
        title: Text(
          'مسح الصفحة',
          style: TextStyle(color: isDarkMode ? Colors.white : null),
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع محتويات هذه الصفحة؟',
          style: TextStyle(color: isDarkMode ? Colors.white70 : null),
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
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
