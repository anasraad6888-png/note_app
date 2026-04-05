import re

with open('lib/drawing_canvas.dart', 'r') as f:
    text = f.read()

# 1. Remove _kInfiniteCanvasSize
text = re.sub(r'const double _kInfiniteCanvasSize = \d+\.\d+;\n*', '', text)

# 2. Remove _infiniteCentered
text = re.sub(r'  bool _infiniteCentered = false;\n*', '', text)

# 3. Simplify Scaffold backgroundColor
scaffold_bg_pattern = r'backgroundColor: \(\) \{[^\}]*?\}\(\),'
scaffold_bg_replacement = '''backgroundColor: canvasCtrl.isDarkMode\n                ? const Color(0xFF000000)\n                : const Color(0xFFEDEDF2),'''
text = re.sub(scaffold_bg_pattern, scaffold_bg_replacement, text, flags=re.DOTALL)

# 4. Remove isInfinitePage logic inside ValueListenableBuilder
infinite_page_logic = r'// Check if the current page has infinite canvas enabled.*?if \(_infiniteCentered\) \{.*?\};\n\s*\}\n'
text = re.sub(infinite_page_logic, '', text, flags=re.DOTALL)

# 5. Remove _centerInfiniteCanvas and _buildInfinitePage methods
methods_pattern = r'/// Centers the TransformationController.*?(?=  Widget _buildPage\(int index\))'
text = re.sub(methods_pattern, '', text, flags=re.DOTALL)

# 6. Apply dark mode fix to _buildPage Container decoration
# Find: decoration: BoxDecoration(\n            color: Colors.transparent,\n...
decoration_pattern = r'decoration: BoxDecoration\(\s*color: Colors\.transparent,.*?border: canvasCtrl\.isDarkMode.*?width: 0\.5\),\s*\),'
decoration_replacement = '''decoration: BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: canvasCtrl.isDarkMode ? Colors.white.withAlpha(5) : Colors.black.withAlpha(15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: canvasCtrl.isDarkMode
                ? Border.all(color: Colors.white12, width: 0.5)
                : Border.all(color: Colors.black.withAlpha(10), width: 0.5),
          ),'''
# Actually wait, git checkout restored the OLD version of decoration which was:
old_decoration_pattern = r'decoration: BoxDecoration\(\s*color: canvasCtrl\.isDarkMode \? Colors\.black : Colors\.white,\s*boxShadow: \[\s*BoxShadow\(\s*color: Colors\.black\.withAlpha\(20\),\s*blurRadius: 10,\s*offset: const Offset\(0, 5\),\s*\),\s*\],\s*\),'

text = re.sub(old_decoration_pattern, decoration_replacement, text, flags=re.DOTALL)

with open('lib/drawing_canvas.dart', 'w') as f:
    f.write(text)
