part of '../canvas_controller.dart';

extension CanvasControllerExport on CanvasController {
  Future<void> saveCurrentPageToGallery(int index) async {
    try {
      if (pagesScreenshotControllers.isEmpty) return;
      final imageBytes = await pagesScreenshotControllers[index].capture(
        delay: const Duration(milliseconds: 10),
      );
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/export_image_$index.png';
        final file = await File(path).writeAsBytes(imageBytes);
        await Gal.putImage(file.path);
        showMessage?.call('تم الحفظ في معرض الصور بنجاح!');
      }
    } catch (e) {
      showMessage?.call('خطأ في الحفظ: $e', isError: true);
    }
  }

  Future<void> shareAsPdf({List<int>? pageIndices, Rect? sharePositionOrigin}) async {
    try {
      if (buildPageForExport == null) {
        throw Exception("دالة بناء صفحات التصدير غير مهيأة.");
      }

      final pdf = pw.Document();
      final indicesToExport = pageIndices ?? List.generate(pagesScreenshotControllers.length, (i) => i);
      final tempController = ScreenshotController();

      showMessage?.call('جاري تجهيز ${indicesToExport.length} صفحات للتصدير...', isError: false);

      for (var index in indicesToExport) {
        final widgetToCapture = buildPageForExport!(index);
        final imageBytes = await tempController.captureFromWidget(
          widgetToCapture,
          delay: const Duration(milliseconds: 150),
        );

        if (imageBytes.isNotEmpty) {
          final image = pw.MemoryImage(imageBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) => pw.Center(child: pw.Image(image)),
            ),
          );
        }
      }
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${document.title}.pdf';
      await File(path).writeAsBytes(await pdf.save());
      
      // On iPads, sharePositionOrigin must be provided and non-zero
      await Share.shareXFiles(
        [XFile(path)], 
        text: 'مشاركة مستند: ${document.title}',
        sharePositionOrigin: sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
      );
    } catch (e) {
      showMessage?.call('خطأ في التصدير: $e', isError: true);
    }
  }

}
