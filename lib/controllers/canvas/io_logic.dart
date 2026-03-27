part of '../canvas_controller.dart';

extension CanvasIOLogic on CanvasController {
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = pickedFile.path.split('/').last;
        final savedImage = await File(
          pickedFile.path,
        ).copy('${directory.path}/$fileName');

        pagesImages[currentPageIndex].add(
          PageImage(
            savedImage.path,
            const Offset(50, 50),
            const Size(200, 200),
            timestamp: audioCtrl.isRecording ? audioCtrl.currentAudioTimeMs : 0,
            audioIndex: audioCtrl.isRecording
                ? audioCtrl.currentAudioIndex
                : null,
          ),
        );
        saveStrokes();
        notifyListeners();
      } catch (e) {
        debugPrint("Error saving image: $e");
      }
    }
  }

  Future<void> importPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = result.files.single.path!.split('/').last;
        final savedPdf = await File(
          result.files.single.path!,
        ).copy('${directory.path}/$fileName');

        String path = savedPdf.path;
        final doc = await PdfDocument.openFile(path);

        final Map<int, Size> sizes = {};
        for (int i = 1; i <= doc.pagesCount; i++) {
          final pg = await doc.getPage(i);
          final double scale = 700 / pg.width;
          sizes[i - 1] = Size(700, pg.height * scale);
          await pg.close();
        }

        document.pdfPath = path;
        pdfDocument = doc;
        pdfPageSizes.addAll(sizes);

        int pdfPages = doc.pagesCount;
        while (pagesPoints.length < pdfPages) {
          pagesPoints.add([]);
          redoPagesPoints.add([]);
          pagesImages.add([]);
          pagesTexts.add([]);
          pagesShapes.add([]);
          pagesTables.add([]);
          activeLaserStrokes.add([]);
          pagesScreenshotControllers.add(ScreenshotController());
          pagesBookmarks.add(false);
          pageTemplates.add(const PageTemplate());
        }
        saveStrokes();
        notifyListeners();
      } catch (e) {
        debugPrint("Error importing PDF: $e");
      }
    }
  }

  void _scheduleThumbnailGeneration() {
    final index = currentPageIndex;
    if (index < 0 || index >= pagesScreenshotControllers.length) return;

    _thumbnailTimer?.cancel();
    _thumbnailTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (_isDisposed) return;
      try {
        final imageBytes = await pagesScreenshotControllers[index].capture(
          delay: const Duration(milliseconds: 10),
          pixelRatio: 0.5, // تقليل الدقة لتسريع الالتقاط وتخفيف الذاكرة
        );
        if (imageBytes != null && !_isDisposed) {
          pageThumbnails[index] = imageBytes;
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Thumbnail capture failed for page $index: $e");
      }
    });
  }

  void saveStrokes() {
    _scheduleThumbnailGeneration();
    List<List<Map<String, dynamic>>> allPagesData = [];
    for (var page in pagesPoints) {
      List<Map<String, dynamic>> strokesData = [];
      for (var p in page) {
        if (p == null) {
          strokesData.add({});
        } else {
          strokesData.add({
            'dx': p.offset.dx,
            'dy': p.offset.dy,
            'color': p.paint.color.toARGB32(),
            'width': p.paint.strokeWidth,
            'timestamp': p.timestamp,
            'audioIndex': p.audioIndex,
          });
        }
      }
      allPagesData.add(strokesData);
    }

    List<List<Map<String, dynamic>>> allImagesData = [];
    for (var page in pagesImages) {
      List<Map<String, dynamic>> imagesData = [];
      for (var img in page) {
        if (!File(img.path).existsSync()) continue;
        imagesData.add(img.toMap());
      }
      allImagesData.add(imagesData);
    }

    List<List<Map<String, dynamic>>> allTextsData = [];
    for (var page in pagesTexts) {
      List<Map<String, dynamic>> textsData = [];
      for (var txt in page) {
        textsData.add(txt.toMap());
      }
      allTextsData.add(textsData);
    }

    List<List<Map<String, dynamic>>> allShapesData = [];
    for (var page in pagesShapes) {
      List<Map<String, dynamic>> shapesData = [];
      for (var shp in page) {
        shapesData.add(shp.toMap());
      }
      allShapesData.add(shapesData);
    }

    List<List<Map<String, dynamic>>> allTablesData = [];
    for (var page in pagesTables) {
      List<Map<String, dynamic>> tablesData = [];
      for (var tbl in page) {
        tablesData.add(tbl.toMap());
      }
      allTablesData.add(tablesData);
    }

    document.pages = allPagesData;
    document.pageImages = allImagesData;
    document.pageTexts = allTextsData;
    document.pageShapes = allShapesData;
    document.pageTables = allTablesData;
    document.pageBookmarks = List<bool>.from(pagesBookmarks);
    document.pageOutlines = List<String?>.from(pagesOutlines);
    onSave(document);
  }

  Future<void> loadPdfIfAny() async {
    if (document.pdfPath != null) {
      try {
        if (await File(document.pdfPath!).exists()) {
          final doc = await PdfDocument.openFile(document.pdfPath!);
          final Map<int, Size> sizes = {};
          for (int i = 1; i <= doc.pagesCount; i++) {
            final pg = await doc.getPage(i);
            final double scale = 700 / pg.width;
            sizes[i - 1] = Size(700, pg.height * scale);
            await pg.close();
          }
          pdfDocument = doc;
          pdfPageSizes.addAll(sizes);
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Error loading PDF: $e");
      }
    }
  }

  void loadStrokes() {
    pagesPoints.clear();
    redoPagesPoints.clear();
    pagesImages.clear();
    pagesTexts.clear();
    pagesShapes.clear();
    pagesTables.clear();
    activeLaserStrokes.clear();
    pagesScreenshotControllers.clear();

    int pageCount = document.pages.length;
    for (int i = 0; i < pageCount; i++) {
      List<DrawingPoint?> currentPagePoints = [];
      for (var strokeData in document.pages[i]) {
        if (strokeData.isEmpty) {
          currentPagePoints.add(null);
          continue;
        }
        currentPagePoints.add(
          DrawingPoint(
            Offset(strokeData['dx'], strokeData['dy']),
            Paint()
              ..color = Color(strokeData['color'])
              ..isAntiAlias = true
              ..strokeWidth = (strokeData['width'] ?? 5.0).toDouble()
              ..strokeCap = StrokeCap.round,
            timestamp: (strokeData['timestamp'] ?? 0) as int,
            audioIndex: strokeData['audioIndex'] as int?,
          ),
        );
      }
      pagesPoints.add(currentPagePoints);
      redoPagesPoints.add([]);
      pageTemplates.add(const PageTemplate());

      List<PageImage> currentImgs = [];
      if (i < document.pageImages.length) {
        for (var imgData in document.pageImages[i]) {
          if (imgData.isNotEmpty && File(imgData['path']).existsSync()) {
            currentImgs.add(PageImage.fromMap(imgData));
          }
        }
      }
      pagesImages.add(currentImgs);

      List<PageText> currentTxts = [];
      if (i < document.pageTexts.length) {
        for (var txtData in document.pageTexts[i]) {
          if (txtData.isNotEmpty) {
            currentTxts.add(PageText.fromMap(txtData));
          }
        }
      }
      pagesTexts.add(currentTxts);

      List<PageShape> currentShps = [];
      if (i < document.pageShapes.length) {
        for (var shpData in document.pageShapes[i]) {
          if (shpData.isNotEmpty) {
            currentShps.add(PageShape.fromMap(shpData));
          }
        }
      }
      pagesShapes.add(currentShps);

      List<PageTable> currentTbls = [];
      if (i < document.pageTables.length) {
        for (var tblData in document.pageTables[i]) {
          if (tblData.isNotEmpty) {
            currentTbls.add(PageTable.fromMap(tblData));
          }
        }
      }
      pagesTables.add(currentTbls);

      activeLaserStrokes.add([]);
      pagesScreenshotControllers.add(ScreenshotController());

      if (i < document.pageBookmarks.length) {
        pagesBookmarks.add(document.pageBookmarks[i]);
      } else {
        pagesBookmarks.add(false);
      }

      if (i < document.pageOutlines.length) {
        pagesOutlines.add(document.pageOutlines[i]);
      } else {
        pagesOutlines.add(null);
      }
    }

    if (pagesPoints.isEmpty) {
      pagesPoints.add([]);
      redoPagesPoints.add([]);
      pagesImages.add([]);
      pagesTexts.add([]);
      pagesShapes.add([]);
      pagesTables.add([]);
      activeLaserStrokes.add([]);
      pagesScreenshotControllers.add(ScreenshotController());
      pagesBookmarks.add(false);
      pagesOutlines.add(null);
      pageTemplates.add(const PageTemplate());
    }
    purgeStaleImages();
    notifyListeners();
  }
}
