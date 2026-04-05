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
  bool removeBackgroundDecoration = false,
  String tag = 'custom_popover',
}) async {
  // إغلاق النافذة السابقة بسلاسة لتجنب التداخل البصري
  if (SmartDialog.checkExist(tag: tag)) {
    SmartDialog.dismiss(tag: tag);
    await Future.delayed(const Duration(milliseconds: 150));
  }
  
  if (!context.mounted) return;

  // التحقق من حالة الثيم لضبط الظل والحدود
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  Alignment finalAlignment = alignment ?? Alignment.bottomCenter;
  if (alignment == null && context.mounted) {
    try {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final Offset globalPos = box.localToGlobal(Offset.zero);
      final double screenW = MediaQueryData.fromView(View.of(context)).size.width;
      final double center = globalPos.dx + (box.size.width / 2);
      
      if (center > screenW * 0.65) {
        finalAlignment = isTopHalf ? Alignment.bottomRight : Alignment.topRight;
      } else if (center < screenW * 0.35) {
        finalAlignment = isTopHalf ? Alignment.bottomLeft : Alignment.topLeft;
      } else {
        finalAlignment = isTopHalf ? Alignment.bottomCenter : Alignment.topCenter;
      }
    } catch (_) {
      finalAlignment = isTopHalf ? Alignment.bottomCenter : Alignment.topCenter;
    }
  } else if (alignment != null) {
    finalAlignment = alignment;
  }

  await SmartDialog.showAttach(
    tag: tag,
    targetContext: context,
    // التوجيه الذكي المتقدم
    alignment: finalAlignment,
    usePenetrate: false, 
    keepSingle: true,
    maskColor: Colors.transparent, // [تحسين]: منع تعتيم لوحة الرسم خلف النافذة
    animationTime: const Duration(milliseconds: 200), // وقت أطول قليلاً لنعومة الانزلاق
    
    // [تحسين]: إضافة حركة انزلاق وتلاشي مخصصة وفخمة
    animationBuilder: (controller, child, animationParam) {
      Offset slideOffset = Offset(0, isTopHalf ? -0.05 : 0.05);
      if (finalAlignment == Alignment.centerLeft) slideOffset = const Offset(0.05, 0);
      else if (finalAlignment == Alignment.centerRight) slideOffset = const Offset(-0.05, 0);

      return SlideTransition(
        position: Tween<Offset>(
          // الانزلاق يأتي من اتجاه الزر
          begin: slideOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic, // منحنى سرعة يبطئ في النهاية
        )),
        child: FadeTransition(
          opacity: controller,
          child: child,
        ),
      );
    },
    
    builder: (dialogContext) {
      return Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(12.0), // مسافة أمان أكبر من حافة الشاشة
        decoration: removeBackgroundDecoration ? null : BoxDecoration(
          color: backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20), // زوايا دائرية أكثر عصرية
          
          // [تحسين]: حدود خفيفة جداً تعطي مظهر الزجاج، وظل يتكيف مع الثيم
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            )
          ],
        ),
        clipBehavior: removeBackgroundDecoration ? Clip.none : Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: bodyBuilder(dialogContext),
        ),
      );
    },
  );
}