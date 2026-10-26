"""Standard-library structural validation. This is NOT an Apple SDK compiler."""
from pathlib import Path
import re, json, plistlib, struct, xml.etree.ElementTree as ET
root = Path(__file__).resolve().parents[1]
raw = (root / 'PencilSlide.xcodeproj/project.pbxproj').read_text(encoding='utf-8-sig')
raw = re.sub(r'//[^\n]*', '', raw)
tokens = re.findall(r'"(?:\\.|[^"\\])*"|[{}()=;,]|[^\s{}()=;,]+', raw)
pos = 0
def pop():
    global pos
    t = tokens[pos]; pos += 1
    return t
def expect(t):
    actual = pop()
    assert actual == t, (actual, t, pos)
def value():
    t = pop()
    if t == '{':
        d = {}
        while tokens[pos] != '}':
            k = pop(); expect('='); assert k not in d, k
            d[k] = value(); expect(';')
        expect('}'); return d
    if t == '(':
        a = []
        while tokens[pos] != ')':
            a.append(value())
            if tokens[pos] == ',': pop()
        expect(')'); return a
    return json.loads(t) if t.startswith('"') else t
parsed = value()
assert pos == len(tokens)
objects = parsed['objects']
assert parsed['rootObject'] in objects
for identifier in re.findall(r'\b[0-9A-F]{24}\b', raw): assert identifier in objects, identifier
for obj in objects.values():
    if obj.get('isa') == 'PBXFileReference' and obj.get('sourceTree') == '<group>':
        assert (root / obj['path']).exists(), obj['path']
source_phase = next(o for o in objects.values() if o.get('isa') == 'PBXSourcesBuildPhase')
sources = {objects[objects[f]['fileRef']]['path'] for f in source_phase['files']}
expected = {p.relative_to(root).as_posix() for p in (root/'PencilSlide').glob('*.swift')}
assert sources == expected, (sources, expected)
assert len(sources) == 7
scheme = ET.parse(root/'PencilSlide.xcodeproj/xcshareddata/xcschemes/PencilSlide.xcscheme')
for ref in scheme.findall('.//BuildableReference'):
    assert objects[ref.attrib['BlueprintIdentifier']]['isa'] == 'PBXNativeTarget'
info = plistlib.loads((root/'PencilSlide/Info.plist').read_bytes())
assert info['NSPhotoLibraryUsageDescription']
assert info['UIStatusBarHidden'] is True
assert info['UIViewControllerBasedStatusBarAppearance'] is True
assert info['PHPhotoLibraryPreventAutomaticLimitedAccessAlert'] is True
assert len(info['UISupportedInterfaceOrientations~ipad']) == 4
catalog = root/'PencilSlide/Assets.xcassets/AppIcon.appiconset'
icons = json.loads((catalog/'Contents.json').read_text(encoding='utf-8'))['images']
for icon in icons:
    data = (catalog/icon['filename']).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    width, height = struct.unpack('>II', data[16:24])
    expected_pixels = round(float(icon['size'].split('x')[0])*int(icon['scale'][0]))
    assert width == height == expected_pixels
    assert data[25] == 2, 'icons must be opaque RGB without alpha'
workflow=(root/'.github/workflows/build-ipa.yml').read_text(encoding='utf-8-sig')
assert '\t' not in workflow
for required in ['runs-on: macos-15','swiftc PencilSlide/PencilTapPattern.swift','CODE_SIGNING_ALLOWED=NO','lipo -verify_arch arm64','retention-days: 3','PencilSlide-Sera-unsigned.ipa','set -euo pipefail']:
    assert required in workflow, required
# Basic delimiter scan ignores comments and quoted strings. Not Swift type checking.
for path in root.rglob('*.swift'):
    source=path.read_text(encoding='utf-8-sig')
    assert 'AppleProductTypes' not in source
    source=re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/', '', source)
    stack=[]
    for char in source:
        if char in '({[': stack.append(char)
        elif char in ')}]':
            assert stack and stack.pop() == {')':'(',']':'[','}':'{'}[char], path
    assert not stack, (path, stack)
app=(root/'PencilSlide/App.swift').read_text(encoding='utf-8')
assert 'struct PencilSlideApp: App' in app
assert 'PHPhotoLibraryChangeObserver' in app
assert '.statusBarHidden(true)' in app
assert 'performChanges(' not in app
assert 'struct SlideshowView' not in app
print(f'PASS: {len(sources)} compiled-source references, project objects/scheme, privacy plist, 10 opaque icon variants, workflow essentials and Swift delimiters.')
print('NOT VERIFIED HERE: Swift type checking, Apple SDK compilation, signing, installation, Pencil callbacks, system UI behavior.')
