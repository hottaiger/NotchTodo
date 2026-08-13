#!/bin/zsh
set -euo pipefail

# 生成 Resources/AppIcon.icns。
#   ./scripts/generate-icon.sh            # 渲染 SF Symbol 占位图标
#   ./scripts/generate-icon.sh icon.png   # 从提供的 1024x1024 png 生成正式图标
#
# 用户提供正式素材后，把 1024x1024 主图传进来重新生成即可替换占位图标。

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PNG="$WORK/icon.png"
ICONSET="$WORK/AppIcon.iconset"

if [[ -n "${1:-}" ]]; then
    cp "$1" "$PNG"
else
    echo "Rendering SF Symbol placeholder..."
    swift -e 'import AppKit
let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSColor.black.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
if let s = NSImage(systemSymbolName: "checklist", accessibilityDescription: nil), let c = s.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 560, weight: .regular)) {
    c.draw(in: NSRect(x: 232, y: 232, width: 560, height: 560))
}
image.unlockFocus()
let d = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
try! d.write(to: URL(fileURLWithPath: "'"$PNG"'"))'
fi

mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
    sips -z $s $s "$PNG" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) "$PNG" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
echo "Generated Resources/AppIcon.icns"
