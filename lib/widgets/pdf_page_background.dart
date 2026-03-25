import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfPageBackground extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;

  const PdfPageBackground({
    super.key,
    required this.document,
    required this.pageNumber,
  });

  @override
  State<PdfPageBackground> createState() => _PdfPageBackgroundState();
}

class _PdfPageBackgroundState extends State<PdfPageBackground> {
  PdfPageImage? _image;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    try {
      final page = await widget.document.getPage(widget.pageNumber);

      // Render at the PDF's natural aspect ratio scaled to canvas width (700pt × 2 for retina).
      // We do NOT force height — the image will letterbox inside the 700×900 container
      // via BoxFit.contain, preserving the PDF's original proportions without squishing.
      final double scale = 700 / page.width;
      final double renderW = page.width * scale * 2;
      final double renderH = page.height * scale * 2;

      final image = await page.render(
        width: renderW,
        height: renderH,
        format: PdfPageImageFormat.jpeg,
        quality: 90,
      );
      await page.close();

      if (mounted) {
        setState(() {
          _image = image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error rendering PDF page: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_image == null) {
      return const Center(child: Text('عذرًا، حدث خطأ في تحميل الصفحة'));
    }
    // The parent Container now has the correct PDF-computed height, so
    // BoxFit.fill fills it exactly — same proportions, no squishing, no letterbox.
    return SizedBox.expand(
      child: Image.memory(_image!.bytes, fit: BoxFit.fill),
    );
  }
}
