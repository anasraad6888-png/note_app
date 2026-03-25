import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

Future<void> showCustomPopover({
  required BuildContext context,
  required WidgetBuilder bodyBuilder,
  required bool isTopHalf,
  double? width,
  double? height,
  Color? backgroundColor,
  Alignment? alignment,
}) async {
  if (SmartDialog.checkExist(tag: 'custom_popover')) {
    SmartDialog.dismiss(tag: 'custom_popover');
    await Future.delayed(const Duration(milliseconds: 160));
  }
  
  if (!context.mounted) return;

  SmartDialog.showAttach(
    tag: 'custom_popover',
    targetContext: context,
    alignment: alignment ?? (isTopHalf ? Alignment.bottomCenter : Alignment.topCenter),
    usePenetrate: false,
    keepSingle: true,
    animationTime: const Duration(milliseconds: 150),
    builder: (dialogContext) {
      return Container(
        width: width ?? 320,
        height: height,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            )
          ],
        ),
        // Clip to ensure content doesn't bleed out of rounded corners
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: bodyBuilder(dialogContext),
        ),
      );
    },
  );
}
