import 'package:flutter/material.dart';

class EraseFiltersDialog {
  static void show({
    required BuildContext context,
    required bool isDarkMode,
    required Set<String> eraseFilters,
    required Function(String, bool) onSetFilter,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : null,
              title: Text(
                'ماذا تريد أن تمسح؟',
                style: TextStyle(color: isDarkMode ? Colors.white : null),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _filterTile(
                    context,
                    isDarkMode,
                    'رسومات القلم',
                    'pen',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'تظليل Highlighter',
                    'highlighter',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'الأشكال Shapes',
                    'shapes',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'الصور Images',
                    'images',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'النصوص Texts',
                    'texts',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                  _filterTile(
                    context,
                    isDarkMode,
                    'الجداول Tables',
                    'tables',
                    eraseFilters,
                    onSetFilter,
                    setDialogState,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'إغلاق',
                    style: TextStyle(color: isDarkMode ? Colors.white70 : null),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _filterTile(
    BuildContext context,
    bool isDarkMode,
    String title,
    String key,
    Set<String> eraseFilters,
    Function(String, bool) onSetFilter,
    StateSetter setDialogState,
  ) {
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white70 : null,
        ),
      ),
      value: eraseFilters.contains(key),
      onChanged: (v) {
        setDialogState(() {
          onSetFilter(key, v ?? false);
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
