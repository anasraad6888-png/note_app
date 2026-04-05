part of '../canvas_controller.dart';

extension CanvasControllerOcr on CanvasController {
  Future<void> extractTextForPage(int pageIndex) async {
    if (pdfDocument == null) return;
    if (pdfTextBounds.containsKey(pageIndex)) return;
    if (_currentlyExtractingPage == pageIndex) return;

    _currentlyExtractingPage = pageIndex;
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final doc = pdfDocument!;
      if (pageIndex >= doc.pagesCount) return;

      final page = await doc.getPage(pageIndex + 1);
      final scale = 700 / page.width;
      final renderW = page.width * scale * 2;
      final renderH = page.height * scale * 2;
      final image = await page.render(
        width: renderW,
        height: renderH,
        format: PdfPageImageFormat.jpeg,
        quality: 90,
      );
      await page.close();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/pdf_temp_ocr_$pageIndex.jpg');
      await tempFile.writeAsBytes(image!.bytes);

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final recognizedText = await textRecognizer.processImage(inputImage);

      List<Rect> boxes = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final rect = line.boundingBox;
          boxes.add(
            Rect.fromLTRB(
              rect.left / 2,
              rect.top / 2,
              rect.right / 2,
              rect.bottom / 2,
            ),
          );
        }
      }

      pdfTextBounds[pageIndex] = boxes;
      tempFile.deleteSync();
    } catch (e) {
      debugPrint("OCR extraction failed for page $pageIndex: $e");
    } finally {
      if (_currentlyExtractingPage == pageIndex)
        _currentlyExtractingPage = null;
      await textRecognizer.close();
      notifyListeners();
    }
  }

  Future<void> performOCR(BuildContext context) async {
    if (activeSelectionGroup == null || activeSelectionGroup!.strokes.isEmpty) {
      showMessage?.call("لا يوجد حبر مكتوب بالتحديد لقراءته!");
      return;
    }

    try {
      final group = activeSelectionGroup!;
      final bounds = group.initialBoundingBox!;
      final width = bounds.width;
      final height = bounds.height;
      if (width <= 0 || height <= 0) return;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = Colors.white,
      );
      canvas.translate(-bounds.left, -bounds.top);

      final painter = DrawingPainter(
        group.strokes,
        pageTemplates[currentPageIndex],
        isDarkMode: false,
        version: contentVersion,
      );
      painter.paint(canvas, Size(bounds.right, bounds.bottom));

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      final inputImage = InputImage.fromFilePath(file.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      await textRecognizer.close();

      final text = recognizedText.text.trim();
      file.deleteSync();

      if (text.isEmpty) {
        showMessage?.call("لم يتم التعرف على أية نصوص.");
        return;
      }

      final pageIndex = group.pageIndex;
      final txtData = PageText(
        id: UniqueKey().toString(),
        text: text,
        rect: Rect.fromLTWH(
          bounds.left,
          bounds.bottom + 10,
          math.max(200, bounds.width),
          math.max(60, bounds.height),
        ),
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: 24.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      pagesTexts[pageIndex].add(txtData);
      saveStrokes();
      notifyListeners();
      showMessage?.call("تم تحويل النص بنجاح!");
    } catch (e) {
      showMessage?.call("خطأ أثناء قراءة النص: $e", isError: true);
    }
  }

}
