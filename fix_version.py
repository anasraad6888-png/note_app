import re

with open('lib/controllers/canvas_controller.dart', 'r') as f:
    code = f.read()

# Methods that modify content and should increment contentVersion
methods = [
    'addPoint', 'addEraserPoint', 'addHighlighterPoint', 'addLaserPoint',
    'startShape', 'updateShape', 'endShape',
    'startTable', 'updateTable', 'endTable',
    'translateSelection', 'scaleSelection', 'rotateSelection', 'commitSelection', 'recolorSelection',
    'deleteTable', 'deleteShape', 'deleteText', 'deleteImage',
    'addTextAt', 'updateText', 'updateImagePosition', 'updateImageSize',
    'undo', 'redo', 'clearPage', 'clearCurrentPage', 'updateLasso', 'pasteClipboard', 'duplicateSelection'
]

# Add contentVersion variable
code = re.sub(r'(class CanvasController extends ChangeNotifier \{\n)', r'\1  int contentVersion = 0;\n  void notifyContentChanged() {\n    contentVersion++;\n    notifyListeners();\n  }\n', code)

for method in methods:
    # Find the method block definition using regex. 
    # E.g. void addPoint(...) { ... }
    # This regex is a bit tricky, let's just replace notifyListeners() with notifyContentChanged()
    # inside the specific methods. We'll find the method signature, then find the next notifyListeners().
    pattern = r'(void\s+' + method + r'\s*\([^)]*\)\s*\{)(.*?)(notifyListeners\(\);)'
    
    def replacer(match):
        return match.group(1) + match.group(2) + 'notifyContentChanged();'
        
    code = re.sub(pattern, replacer, code, flags=re.DOTALL)

with open('lib/controllers/canvas_controller.dart', 'w') as f:
    f.write(code)

