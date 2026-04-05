part of '../canvas_controller.dart';

extension CanvasControllerColors on CanvasController {
  
  // ==========================================
  // 🛠️ Generic Helpers (الدوال المساعدة العامة)
  // ==========================================

  void _loadColorList(String key, List<Color> targetList) {
    try {
      final box = Hive.box('settingsBox');
      final colors = box.get(key);
      if (colors != null && colors is List && colors.isNotEmpty) {
        targetList.clear();
        targetList.addAll(colors.map((c) => Color(c as int)));
      }
    } catch (_) {}
  }

  void _saveColorList(String key, List<Color> sourceList) {
    try {
      Hive.box('settingsBox').put(key, sourceList.map((c) => c.toARGB32()).toList());
    } catch (_) {}
  }

  void _changeColor(List<Color> list, int index, Color newColor, Color activeColor, ValueChanged<Color> updateActiveColor, VoidCallback onSave) {
    if (index >= 0 && index < list.length) {
      // [إصلاح Bug]: التحقق مما إذا كان اللون المعدل هو اللون النشط حالياً قبل الكتابة فوقه
      bool wasActive = activeColor == list[index];
      list[index] = newColor;
      if (wasActive) updateActiveColor(newColor);
      onSave();
      notifyListeners();
    }
  }

  void _addCustomColor(List<Color> defaults, List<Color> customs, Color color, ValueChanged<Color> updateActiveColor, VoidCallback onSave, {int maxCustoms = 7, int maxCombined = 999}) {
    if (defaults.contains(color) || customs.contains(color)) {
      updateActiveColor(color);
      notifyListeners();
      return;
    }

    bool canAdd = maxCombined != 999 
        ? (defaults.length + customs.length) < maxCombined 
        : customs.length < maxCustoms;

    if (canAdd) {
      customs.add(color);
      updateActiveColor(color);
      onSave();
      notifyListeners();
    }
  }

  void _deleteColor(List<Color> targetList, List<Color> otherList, int index, VoidCallback onSave) {
    if (index >= 0 && index < targetList.length) {
      if ((targetList.length + otherList.length) > 3) {
        targetList.removeAt(index);
        onSave();
        notifyListeners();
      }
    }
  }

  // ==========================================
  // 🖌️ Pen Settings (إعدادات القلم)
  // ==========================================

  void loadPenColors() {
    _loadColorList('defaultPenColors', defaultPenColors);
    _loadColorList('customPenColors', customPenColors);
    try {
      final box = Hive.box('settingsBox');
      final widths = box.get('strokeWidthPresets');
      if (widths != null && widths is List) {
        strokeWidthPresets = widths.map((w) => (w as num).toDouble()).toList();
      }
      activeStrokeWidthIndex = box.get('activeStrokeWidthIndex', defaultValue: 1);
      if (activeStrokeWidthIndex >= 0 && activeStrokeWidthIndex < strokeWidthPresets.length) {
        strokeWidth = strokeWidthPresets[activeStrokeWidthIndex];
      }
      isSettingsMagnetActive = box.get('isSettingsMagnetActive', defaultValue: true);
      final posIndex = box.get('toolbarPosition_${document.id}', defaultValue: ToolbarPosition.bottom.index);
      toolbarPosition = ToolbarPosition.values[posIndex as int];
    } catch (_) {}
  }

  void savePenColors() {
    _saveColorList('defaultPenColors', defaultPenColors);
    _saveColorList('customPenColors', customPenColors);
    try {
      final box = Hive.box('settingsBox');
      box.put('strokeWidthPresets', strokeWidthPresets);
      box.put('activeStrokeWidthIndex', activeStrokeWidthIndex);
      box.put('isSettingsMagnetActive', isSettingsMagnetActive);
    } catch (_) {}
  }

  void selectStrokeWidthPreset(int index) {
    if (index >= 0 && index < strokeWidthPresets.length) {
      activeStrokeWidthIndex = index;
      strokeWidth = strokeWidthPresets[index];
      savePenColors();
      notifyListeners();
    }
  }

  void updateStrokeWidthPreset(int index, double newWidth) {
    if (index >= 0 && index < strokeWidthPresets.length) {
      strokeWidthPresets[index] = newWidth;
      if (activeStrokeWidthIndex == index) strokeWidth = newWidth;
      savePenColors();
      notifyListeners();
    }
  }

  void changeDefaultPenColor(int index, Color newColor) => _changeColor(defaultPenColors, index, newColor, selectedColor, (c) => selectedColor = c, savePenColors);
  void addCustomPenColor(Color color) => _addCustomColor(defaultPenColors, customPenColors, color, (c) => selectedColor = c, savePenColors);
  void changeCustomPenColor(int index, Color newColor) => _changeColor(customPenColors, index, newColor, selectedColor, (c) => selectedColor = c, savePenColors);
  void deleteCustomPenColor(int index) => _deleteColor(customPenColors, defaultPenColors, index, savePenColors);
  void deleteDefaultPenColor(int index) => _deleteColor(defaultPenColors, customPenColors, index, savePenColors);

  // ==========================================
  // 🖍️ Highlighter Settings (إعدادات التظليل)
  // ==========================================

  void loadHighlighterColors() {
    _loadColorList('defaultHighlighterColors', defaultHighlighterColors);
    _loadColorList('customHighlighterColors', customHighlighterColors);
  }

  void saveHighlighterColors() {
    _saveColorList('defaultHighlighterColors', defaultHighlighterColors);
    _saveColorList('customHighlighterColors', customHighlighterColors);
  }

  void changeDefaultHighlighterColor(int index, Color newColor) => _changeColor(defaultHighlighterColors, index, newColor, highlighterColor, (c) => highlighterColor = c, saveHighlighterColors);
  void addCustomHighlighterColor(Color color) => _addCustomColor(defaultHighlighterColors, customHighlighterColors, color, (c) => highlighterColor = c, saveHighlighterColors);
  void changeCustomHighlighterColor(int index, Color newColor) => _changeColor(customHighlighterColors, index, newColor, highlighterColor, (c) => highlighterColor = c, saveHighlighterColors);
  void deleteCustomHighlighterColor(int index) => _deleteColor(customHighlighterColors, defaultHighlighterColors, index, saveHighlighterColors);
  void deleteDefaultHighlighterColor(int index) => _deleteColor(defaultHighlighterColors, customHighlighterColors, index, saveHighlighterColors);

  // ==========================================
  // 🔴 Laser Settings (إعدادات الليزر)
  // ==========================================

  void loadLaserColors() {
    _loadColorList('defaultLaserColors', defaultLaserColors);
    _loadColorList('customLaserColors', customLaserColors);
  }

  void saveLaserColors() {
    _saveColorList('defaultLaserColors', defaultLaserColors);
    _saveColorList('customLaserColors', customLaserColors);
  }

  void changeDefaultLaserColor(int index, Color newColor) => _changeColor(defaultLaserColors, index, newColor, laserColor, (c) => laserColor = c, saveLaserColors);
  void addCustomLaserColor(Color color) => _addCustomColor(defaultLaserColors, customLaserColors, color, (c) => laserColor = c, saveLaserColors);
  void changeCustomLaserColor(int index, Color newColor) => _changeColor(customLaserColors, index, newColor, laserColor, (c) => laserColor = c, saveLaserColors);
  void deleteCustomLaserColor(int index) => _deleteColor(customLaserColors, defaultLaserColors, index, saveLaserColors);
  void deleteDefaultLaserColor(int index) => _deleteColor(defaultLaserColors, customLaserColors, index, saveLaserColors);

  // ==========================================
  // 🔤 Text Settings (إعدادات النصوص)
  // ==========================================

  void loadTextColors() {
    _loadColorList('defaultTextColors', defaultTextColors);
    _loadColorList('customTextColors', customTextColors);
  }

  void saveTextColors() {
    _saveColorList('defaultTextColors', defaultTextColors);
    _saveColorList('customTextColors', customTextColors);
  }

  void changeDefaultTextColor(int index, Color newColor) => _changeColor(defaultTextColors, index, newColor, defaultTextColor, (c) => defaultTextColor = c, saveTextColors);
  // لاحظ تحديد maxCombined للنصوص بـ 5 كما كان في كودك القديم
  void addCustomTextColor(Color color) => _addCustomColor(defaultTextColors, customTextColors, color, (c) => defaultTextColor = c, saveTextColors, maxCombined: 5);
  void changeCustomTextColor(int index, Color newColor) => _changeColor(customTextColors, index, newColor, defaultTextColor, (c) => defaultTextColor = c, saveTextColors);
  void deleteCustomTextColor(int index) => _deleteColor(customTextColors, defaultTextColors, index, saveTextColors);
  void deleteDefaultTextColor(int index) => _deleteColor(defaultTextColors, customTextColors, index, saveTextColors);

  // ==========================================
  // 🎨 Global Color Palette (لوحة الألوان الثابتة)
  // ==========================================
  
  List<Color> get colors => [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.grey,
    Colors.white,
  ];
}