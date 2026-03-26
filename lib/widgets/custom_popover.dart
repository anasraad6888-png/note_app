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
  // إغلاق النافذة السابقة بسلاسة لتجنب التداخل البصري
  if (SmartDialog.checkExist(tag: 'custom_popover')) {
    SmartDialog.dismiss(tag: 'custom_popover');
    await Future.delayed(const Duration(milliseconds: 150));
  }
  
  if (!context.mounted) return;

  // التحقق من حالة الثيم لضبط الظل والحدود
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  await SmartDialog.showAttach(
    tag: 'custom_popover',
    targetContext: context,
    // التوجيه الذكي
    alignment: alignment ?? (isTopHalf ? Alignment.bottomCenter : Alignment.topCenter),
    usePenetrate: false, 
    keepSingle: true,
    maskColor: Colors.transparent, // [تحسين]: منع تعتيم لوحة الرسم خلف النافذة
    animationTime: const Duration(milliseconds: 200), // وقت أطول قليلاً لنعومة الانزلاق
    
    // [تحسين]: إضافة حركة انزلاق وتلاشي مخصصة وفخمة
    animationBuilder: (controller, child, animationParam) {
      return SlideTransition(
        position: Tween<Offset>(
          // الانزلاق يأتي من اتجاه الزر
          begin: Offset(0, isTopHalf ? -0.05 : 0.05),
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
        width: width ?? 320,
        height: height,
        margin: const EdgeInsets.all(12.0), // مسافة أمان أكبر من حافة الشاشة
        decoration: BoxDecoration(
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
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: bodyBuilder(dialogContext),
        ),
      );
    },
  );
}