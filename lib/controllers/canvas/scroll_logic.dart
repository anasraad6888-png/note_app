part of '../canvas_controller.dart';

extension CanvasControllerScroll on CanvasController {
  void scrollToActiveText(double keyboardHeight, double screenHeight) {
    if (activeEditingText == null) return;
    if (!scrollController.hasClients) return;
    if (keyboardHeight < 100) return; // Keyboard not meaningfully open

    final pageIndex = currentPageIndex;
    final textRect = activeEditingText!.rect;

    // ListView padding top: 80, page vertical padding: 20 each side, page height: 900
    // => each page slot = 940px, page top = 80 + pageIndex * 940 + 20
    const double listTopPadding = 80.0;
    const double pageSlotHeight = 940.0;
    const double pageTopPadding = 20.0;
    final double pageTopInScroll =
        listTopPadding + pageIndex * pageSlotHeight + pageTopPadding;

    // Y-center of text box in scroll space
    final double textCenterY =
        pageTopInScroll + textRect.top + textRect.height / 2;

    // Visible region between top toolbar (~60px) and keyboard + text toolbar (~130px)
    const double topClearance = 60.0;
    final double bottomClearance = keyboardHeight + 70.0; // text toolbar ~70px
    final double visibleHeight =
        (screenHeight - topClearance - bottomClearance).clamp(100.0, double.infinity);

    // Desired scroll: text center lands in the middle of the visible region
    final double desired =
        textCenterY - topClearance - visibleHeight / 2;

    final double clamped = desired.clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );

    // Only scroll if the text is not already fully visible
    final double currentOffset = scrollController.offset;
    final double visibleTop = currentOffset + topClearance;
    final double visibleBottom = currentOffset + screenHeight - bottomClearance;
    final double textTop = pageTopInScroll + textRect.top;
    final double textBottom = textTop + textRect.height;
    if (textTop >= visibleTop && textBottom <= visibleBottom) return;

    scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void jumpToPage(int index) {
    if (index < 0 || index >= document.pages.length) return;

    currentPageIndex = index;

    // Calculate the scroll position
    // ListView padding top: 140, page padding vertical: 20*2=40, page height: 900
    double scrollPosition = 140.0 + (index * 940.0);

    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    // notifyListeners() is called by the currentPageIndex setter
  }

}
