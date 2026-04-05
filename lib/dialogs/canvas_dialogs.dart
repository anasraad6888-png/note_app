import 'package:flutter/material.dart';
import '../models/note_document.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/audio_controller.dart';

import 'canvas_dialogs/edit_title_dialog.dart';
import 'canvas_dialogs/export_dialog.dart';
import 'canvas_dialogs/clear_page_dialog.dart';
import 'canvas_dialogs/erase_filters_dialog.dart';
import 'canvas_dialogs/table_settings_dialog.dart';
import 'canvas_dialogs/shape_settings_dialog.dart';
import 'canvas_dialogs/custom_color_picker_dialog.dart';
import 'canvas_dialogs/pages_grid_dialog.dart';
import 'canvas_dialogs/rename_audio_dialog.dart';
import 'canvas_dialogs/page_settings_dialog.dart';

class CanvasDialogs {
  static void showEditTitleDialog({
    required BuildContext context,
    required NoteDocument document,
    required bool isDarkMode,
    required VoidCallback onSave,
  }) {
    EditTitleDialog.show(
      context: context,
      document: document,
      isDarkMode: isDarkMode,
      onSave: onSave,
    );
  }

  static void showExportDialog({
    required BuildContext context,
    required bool isDarkMode,
    required VoidCallback onExportImage,
    required VoidCallback onExportPdf,
  }) {
    ExportDialog.show(
      context: context,
      isDarkMode: isDarkMode,
      onExportImage: onExportImage,
      onExportPdf: onExportPdf,
    );
  }

  static void showClearPageDialog({
    required BuildContext context,
    required bool isDarkMode,
    required VoidCallback onConfirm,
  }) {
    ClearPageDialog.show(
      context: context,
      isDarkMode: isDarkMode,
      onConfirm: onConfirm,
    );
  }

  static void showEraseFiltersDialog({
    required BuildContext context,
    required bool isDarkMode,
    required Set<String> eraseFilters,
    required Function(String, bool) onSetFilter,
  }) {
    EraseFiltersDialog.show(
      context: context,
      isDarkMode: isDarkMode,
      eraseFilters: eraseFilters,
      onSetFilter: onSetFilter,
    );
  }

  static void showTableSettingsDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
    required bool isTopHalf,
    Alignment? alignment,
  }) {
    TableSettingsDialog.showTableSettingsDialog(
      context: context,
      canvasCtrl: canvasCtrl,
      isTopHalf: isTopHalf,
      alignment: alignment,
    );
  }

  static void showShapeSettingsDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
    required bool isTopHalf,
    Alignment? alignment,
  }) {
    ShapeSettingsDialog.showShapeSettingsDialog(
      context: context,
      canvasCtrl: canvasCtrl,
      isTopHalf: isTopHalf,
      alignment: alignment,
    );
  }

  static void showCustomColorPicker({
    required BuildContext context,
    required bool isDarkMode,
    required Color initialColor,
    required Function(Color) onColorChanged,
  }) {
    CustomColorPickerDialog.showCustomColorPicker(
      context: context,
      isDarkMode: isDarkMode,
      initialColor: initialColor,
      onColorChanged: onColorChanged,
    );
  }

  static void showPagesGridDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
  }) {
    PagesGridDialog.showPagesGridDialog(
      context: context,
      canvasCtrl: canvasCtrl,
    );
  }

  static void showRenameAudioDialog({
    required BuildContext context,
    required bool isDarkMode,
    required int index,
    required AudioController audioCtrl,
  }) {
    RenameAudioDialog.showRenameAudioDialog(
      context: context,
      isDarkMode: isDarkMode,
      index: index,
      audioCtrl: audioCtrl,
    );
  }

  static void showPageSettingsDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
    bool isTopHalf = false,
  }) {
    PageSettingsDialog.showPageSettingsDialog(
      context: context,
      canvasCtrl: canvasCtrl,
      isTopHalf: isTopHalf,
    );
  }
}
