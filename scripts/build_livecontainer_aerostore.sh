#!/usr/bin/env bash
set -euo pipefail

# Build LiveContainer+AeroStore combined unsigned IPA
# Prerequisites: Xcode 26+, LiveContainer submodule initialized
#
# Usage: bash scripts/build_livecontainer_aerostore.sh [release|debug]

CONFIG="${1:-Release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT"

echo "=== Step 1: Build AeroStore ==="
DD="${ROOT}/build/derived-aerostore"
SP="${ROOT}/build/source-packages"
mkdir -p "$DD" "$SP" "${ROOT}/build"

xcodebuild archive \
  -project "${ROOT}/AltStore.xcodeproj" \
  -scheme SideStore \
  -configuration "$CONFIG" \
  -archivePath "${ROOT}/build/AeroStore.xcarchive" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DD" \
  -clonedSourcePackagesDirPath "$SP" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  SWIFT_OPTIMIZATION_LEVEL="-Onone" \
  | tee "${ROOT}/build/aerostore-build.log"

echo "=== Step 1b: Package standalone AeroStore IPA ==="
AERO_APP="$(find "${ROOT}/build/AeroStore.xcarchive/Products/Applications" -maxdepth 1 -name "*.app" -print -quit)"
test -n "$AERO_APP" && test -d "$AERO_APP"
rm -rf "${ROOT}/build/Payload" "${ROOT}/build/AeroStore.ipa"
mkdir -p "${ROOT}/build/Payload"
cp -R "$AERO_APP" "${ROOT}/build/Payload/"
(cd "${ROOT}/build" && zip -qr AeroStore.ipa Payload)
rm -rf "${ROOT}/build/Payload"
ls -lh "${ROOT}/build/AeroStore.ipa"

echo "=== Step 2: Package AeroStore.app as AeroStoreApp.framework ==="
APP="$(find "${ROOT}/build/AeroStore.xcarchive/Products/Applications" -maxdepth 1 -name "*.app" -print -quit)"
test -n "$APP" && test -d "$APP"

FW="${ROOT}/build/AeroStoreApp.framework"
rm -rf "$FW"
mkdir -p "$FW"
cp -R "$APP/" "$FW/"

# Rename executable to AeroStoreApp
EXEC=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "${FW}/Info.plist" 2>/dev/null || echo "AeroStore")
if [ -f "${FW}/${EXEC}" ]; then
  mv "${FW}/${EXEC}" "${FW}/AeroStoreApp"
fi

# Update Info.plist for framework layout
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable AeroStoreApp" "${FW}/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string AeroStoreApp" "${FW}/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundlePackageType FMWK" "${FW}/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string FMWK" "${FW}/Info.plist"

echo "=== Step 3: Embed AeroStoreApp.framework into LiveContainer ==="
LC_DIR="${ROOT}/LiveContainer"
mkdir -p "${LC_DIR}/Frameworks"

# Remove old if present
rm -rf "${LC_DIR}/Frameworks/AeroStoreApp.framework"
cp -R "$FW" "${LC_DIR}/Frameworks/AeroStoreApp.framework"

# Ensure SideStore.framework is present (needed for XPC refresh protocol)
if [ ! -d "${LC_DIR}/Frameworks/SideStore.framework" ] && [ -d "${LC_DIR}/SideStore" ]; then
  echo "Warning: SideStore.framework not found. Build LiveContainer with SideStore first, or create a stub."
fi

echo "=== Step 4: Build LiveContainer ==="
DD_LC="${ROOT}/build/derived-livecontainer"
SP_LC="${ROOT}/build/source-packages"
LOG_LC="${ROOT}/build/livecontainer-build.log"

xcodebuild archive \
  -project "${LC_DIR}/LiveContainer.xcodeproj" \
  -scheme LiveContainer \
  -configuration "$CONFIG" \
  -archivePath "${ROOT}/build/LiveContainer.xcarchive" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DD_LC" \
  -clonedSourcePackagesDirPath "$SP_LC" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  | tee "$LOG_LC"

echo "=== Step 5: Package combined IPA ==="
LC_APP="$(find "${ROOT}/build/LiveContainer.xcarchive/Products/Applications" -maxdepth 1 -name "*.app" -print -quit)"
test -n "$LC_APP" && test -d "$LC_APP"

rm -rf "${ROOT}/build/Payload" "${ROOT}/build/LiveContainer+AeroStore.ipa"
mkdir -p "${ROOT}/build/Payload"
cp -R "$LC_APP" "${ROOT}/build/Payload/"
(cd "${ROOT}/build" && zip -qr LiveContainer+AeroStore.ipa Payload)
rm -rf "${ROOT}/build/Payload"

echo "=== Done ==="
echo "Standalone AeroStore IPA: ${ROOT}/build/AeroStore.ipa"
echo "Combined IPA:            ${ROOT}/build/LiveContainer+AeroStore.ipa"
ls -lh "${ROOT}/build/AeroStore.ipa" "${ROOT}/build/LiveContainer+AeroStore.ipa"
