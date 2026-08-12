#!/bin/zsh
set -euo pipefail

# 版本号：优先从 git tag 推导（如 v1.2.0 → 1.2.0），无 tag 时留空；
# build 号用提交计数，失败回退为 1。
VERSION=$(git describe --tags --match 'v*' 2>/dev/null | sed 's/^v//' || true)
BUILD=$(git rev-list --count HEAD 2>/dev/null || echo "1")

swift build -c release

APP_PATH=".build/release/NotchTodo.app"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
cp ".build/release/NotchTodo" "$APP_PATH/Contents/MacOS/NotchTodo"

# 拷贝 Info.plist 并注入版本号
cp "Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
if [[ -n "$VERSION" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_PATH/Contents/Info.plist"
fi
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$APP_PATH/Contents/Info.plist"

# ad-hoc 签名（无 Developer ID 时的兜底，缓解 Gatekeeper 误报）
codesign --force --sign - "$APP_PATH"

# 打包 zip 便于分发
ZIP_PATH="NotchTodo-macOS-arm64-${VERSION:-local}.zip"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "App: $APP_PATH"
echo "Zip: $ZIP_PATH"
