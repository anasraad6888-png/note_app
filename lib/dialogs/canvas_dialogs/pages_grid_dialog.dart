import 'package:flutter/material.dart';
import '../../controllers/canvas_controller.dart';
import '../pages_manager_dialog.dart';

class PagesGridDialog {
  static void showPagesGridDialog({
    required BuildContext context,
    required CanvasController canvasCtrl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // transparent to let PagesManagerDialog handle shape/color
      builder: (context) {
        return PagesManagerDialog(canvasCtrl: canvasCtrl);
      },
    );
  }
}
