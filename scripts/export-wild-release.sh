#!/usr/bin/env bash
# Archive + export Porteos Intelligence for install on your other Macs (no App Store).
# Requires: Xcode, Apple Developer Program, Developer ID cert in Keychain.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="PorteosIntelligence"
ARCHIVE_PATH="$ROOT/build/PorteosIntelligence.xcarchive"
EXPORT_PATH="$ROOT/build/export"
EXPORT_OPTIONS="$ROOT/scripts/ExportOptionsDeveloperID.plist"

echo "→ Clean build folder"
rm -rf "$ROOT/build"
mkdir -p "$ROOT/build"

echo "→ Archive (Release, macOS)"
xcodebuild \
  -project "$ROOT/PorteosIntelligence.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive

echo "→ Export Developer ID signed app"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

APP="$EXPORT_PATH/PorteosIntelligence.app"
if [[ ! -d "$APP" ]]; then
  echo "Export failed — PorteosIntelligence.app not found in $EXPORT_PATH" >&2
  exit 1
fi

echo ""
echo "✓ Ready: $APP"
echo ""
echo "Next (recommended before copying to other Macs):"
echo "  xcrun notarytool submit \"$APP\" --keychain-profile \"AC_PASSWORD\" --wait"
echo "  xcrun stapler staple \"$APP\""
echo ""
echo "Or use Xcode Organizer → Distribute App → Developer ID → Upload for notarization."
echo "See PorteosIntelligence/Documentation/DISTRIBUTION.md"
