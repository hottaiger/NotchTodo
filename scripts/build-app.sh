#!/bin/zsh
set -euo pipefail
swift build -c release
APP_PATH=".build/release/NotchTodo.app"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
cp ".build/release/NotchTodo" "$APP_PATH/Contents/MacOS/NotchTodo"
cp "Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
echo "$APP_PATH"
