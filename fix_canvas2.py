import re

with open('lib/drawing_canvas.dart', 'r') as f:
    lines = f.readlines()

new_lines = []
skip = False

# Patterns to remove completely
k_inf_size_pattern = re.compile(r'_kInfiniteCanvasSize =')
inf_centered_pattern = re.compile(r'_infiniteCentered =')
start_value_listenable = re.compile(r'final isInfinitePage =')

in_value_listenable_inf_page = False
in_val_listenable_brackets = 0

for i, line in enumerate(lines):
    if k_inf_size_pattern.search(line):
        continue
    if inf_centered_pattern.search(line) and not 'if (_infiniteCentered)' in line: # avoid false positive with if statement, but wait, the if statement should also be removed
        continue
        
with open('lib/drawing_canvas.dart', 'r') as f:
    text = f.read()

# Remove the isInfinitePage toggle from ValueListenableBuilder
pattern1 = r'// Check if the current page has infinite.*?\n\s*if \(_infiniteCentered\) \{.*?\};\n\s*\}\n'
text = re.sub(pattern1, '', text, flags=re.DOTALL)

# Let's fix the startText thing.
text = text.replace('canvasCtrl.addTextAt(index, event.localPosition);', 'canvasCtrl.startText(index, event.localPosition);')

with open('lib/drawing_canvas.dart', 'w') as f:
    f.write(text)
