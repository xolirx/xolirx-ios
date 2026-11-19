#!/bin/bash
# Сборка IPA на macOS. Запуск:  DEVELOPMENT_TEAM=XXXXXXXXXX ./build-ipa.sh
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Нужен Xcode: эта сборка выполняется только на macOS."
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Установите XcodeGen: brew install xcodegen"
  exit 1
fi

TEAM="${DEVELOPMENT_TEAM:-}"
if [ -z "$TEAM" ]; then
  echo "Укажите Team ID вашего Apple-аккаунта:"
  echo "  DEVELOPMENT_TEAM=XXXXXXXXXX ./build-ipa.sh"
  echo "Team ID виден в https://developer.apple.com/account → Membership."
  exit 1
fi

xcodegen generate

xcodebuild \
  -project Xolirx.xcodeproj \
  -scheme Xolirx \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/Xolirx.xcarchive \
  DEVELOPMENT_TEAM="$TEAM" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive

xcodebuild \
  -exportArchive \
  -archivePath build/Xolirx.xcarchive \
  -exportPath build/ipa \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates

echo
echo "Готово: $(pwd)/build/ipa/XOLIRX.ipa"
