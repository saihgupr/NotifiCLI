#!/bin/bash
# Extract app icon and create a NotifiCLI variant (Incremental Build)
# Usage: ./add-icon.sh "/Applications/Keyboard Maestro.app" KeyboardMaestro

set -e

# Resolve script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

APP_PATH="$1"
VARIANT_NAME="$2"
DISPLAY_NAME="${3:-$VARIANT_NAME}"
ICONS_DIR="icons"
BUILD_DIR="build"

if [ -z "$APP_PATH" ] || [ -z "$VARIANT_NAME" ]; then
    echo "Usage: ./add-icon.sh \"/path/to/App.app\" VariantName"
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found: $APP_PATH"
    exit 1
fi

# --- 1. Locate Base Resources ---

# Determine source for binaries and Info.plist
# We prefer the local build/ directory, but fallback to /Applications if needed
if [ -d "$BUILD_DIR/NotifiCLI.app" ]; then
    BASE_SRC="$BUILD_DIR/NotifiCLI.app"
elif [ -d "/Applications/NotifiCLI.app" ]; then
    BASE_SRC="/Applications/NotifiCLI.app"
else
    echo "❌ Error: NotifiCLI base app not found in build/ or /Applications."
    echo "   Please run ./build.sh once to create the base application."
    exit 1
fi

NOTIFICLI_BIN="$BASE_SRC/Contents/MacOS/NotifiCLI-Binary"
PERSISTENT_BIN="$BASE_SRC/Contents/Apps/NotifiPersistent.app/Contents/MacOS/NotifiPersistent"

# Fallback for persistent if not embedded yet (local dev case)
if [ ! -f "$PERSISTENT_BIN" ] && [ -d "$BUILD_DIR/NotifiPersistent.app" ]; then
    PERSISTENT_BIN="$BUILD_DIR/NotifiPersistent.app/Contents/MacOS/NotifiPersistent"
fi

if [ ! -f "$NOTIFICLI_BIN" ]; then
    echo "❌ Error: NotifiCLI binary not found at $NOTIFICLI_BIN"
    exit 1
fi

# Locate Info.plist templates (prefer local source files, fallback to built app)
if [ -f "Info.plist" ]; then
    INFO_PLIST_SRC="Info.plist"
else
    INFO_PLIST_SRC="$BASE_SRC/Contents/Info.plist"
fi

if [ -f "Info_Persistent.plist" ]; then
    INFO_PERSISTENT_PLIST_SRC="Info_Persistent.plist"
elif [ -f "$BASE_SRC/Contents/Apps/NotifiPersistent.app/Contents/Info.plist" ]; then
    INFO_PERSISTENT_PLIST_SRC="$BASE_SRC/Contents/Apps/NotifiPersistent.app/Contents/Info.plist"
else
    # Fallback to standard info plist if persistent specific one is missing in app bundle
    INFO_PERSISTENT_PLIST_SRC="$INFO_PLIST_SRC"
fi

# --- 2. Extract Icon ---

# Find the app icon from Info.plist
PLIST="$APP_PATH/Contents/Info.plist"
if [ ! -f "$PLIST" ]; then
    echo "❌ Error: No Info.plist found in target app"
    exit 1
fi

ICON_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$PLIST" 2>/dev/null || echo "")

# Handle cases where ICON_NAME is a path or missing extension
if [ -n "$ICON_NAME" ]; then
    # Some apps specify a full path or a name without extension
    if [[ "$ICON_NAME" != *.icns ]]; then
        # Try with .icns
        if [ -f "$APP_PATH/Contents/Resources/${ICON_NAME}.icns" ]; then
            ICON_PATH="$APP_PATH/Contents/Resources/${ICON_NAME}.icns"
        elif [ -f "$APP_PATH/Contents/Resources/${ICON_NAME}" ]; then
            ICON_PATH="$APP_PATH/Contents/Resources/${ICON_NAME}"
        fi
    else
        ICON_PATH="$APP_PATH/Contents/Resources/$ICON_NAME"
    fi
fi

# Fallbacks if still not found
if [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; then
    if [ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]; then
        ICON_PATH="$APP_PATH/Contents/Resources/AppIcon.icns"
    elif [ -f "$APP_PATH/Contents/Resources/AppIcon-Internal.icns" ]; then
        ICON_PATH="$APP_PATH/Contents/Resources/AppIcon-Internal.icns"
    else
        # Search for any icns
        ICON_PATH=$(ls "$APP_PATH/Contents/Resources/"*.icns 2>/dev/null | head -n 1)
    fi
fi

# FINAL EXTRACTOR FALLBACK (For Tahoe/Sequoia system apps)
if [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; then
    # Create the png first using the swift helper
    EXTRACTOR_PNG="${ICONS_DIR}/${VARIANT_NAME}_extracted.png"
    mkdir -p "$ICONS_DIR"
    
    # Run the swift helper
    if swift "${DIR}/scripts/extract-icon.swift" "$APP_PATH" "$EXTRACTOR_PNG"; then
        # We now have a PNG. We need to convert it to ICNS if possible, 
        # but for add-icon.sh, we can just point to it and let the variant build logic handle it?
        # Actually, add-icon.sh currently expects an ICNS to copy.
        # Let's convert it to ICNS using iconutil (simplified)
        
        ICONSET_DIR="${ICONS_DIR}/${VARIANT_NAME}_extracted.iconset"
        mkdir -p "$ICONSET_DIR"
        # Create all required icon sizes for a valid iconset
        sips -z 16 16     "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_16x16.png" >/dev/null 2>&1
        sips -z 32 32     "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_16x16@2x.png" >/dev/null 2>&1
        sips -z 32 32     "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_32x32.png" >/dev/null 2>&1
        sips -z 64 64     "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_32x32@2x.png" >/dev/null 2>&1
        sips -z 128 128   "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_128x128.png" >/dev/null 2>&1
        sips -z 256 256   "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_128x128@2x.png" >/dev/null 2>&1
        sips -z 256 256   "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_256x256.png" >/dev/null 2>&1
        sips -z 512 512   "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_256x256@2x.png" >/dev/null 2>&1
        sips -z 512 512   "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_512x512.png" >/dev/null 2>&1
        sips -z 1024 1024 "$EXTRACTOR_PNG" --out "${ICONSET_DIR}/icon_512x512@2x.png" >/dev/null 2>&1
        iconutil -c icns "$ICONSET_DIR" -o "${ICONS_DIR}/${VARIANT_NAME}.icns" >/dev/null 2>&1
        rm -rf "$ICONSET_DIR"
        rm "$EXTRACTOR_PNG"
        
        if [ -f "${ICONS_DIR}/${VARIANT_NAME}.icns" ]; then
            ICON_PATH="${ICONS_DIR}/${VARIANT_NAME}.icns"
        fi
    fi
fi

if [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; then
    echo "❌ Error: Icon not found for app at $APP_PATH"
    exit 1
fi

# Ensure it's in the icons folder for reference
if [ "$ICON_PATH" != "$ICONS_DIR/${VARIANT_NAME}.icns" ]; then
    mkdir -p "$ICONS_DIR"
    cp "$ICON_PATH" "$ICONS_DIR/${VARIANT_NAME}.icns"
fi


# --- 3. Build Variant (Incremental) ---

# We only build the "NotifiCLI" variant for the usage command
# But logic supports both. Let's build both to match build.sh behavior
VARIANTS=("NotifiCLI" "NotifiPersistent")

# Ensure destination exists in the base (local build preferred)
# If local build doesn't exist, we create the structure
APPS_DIR="$BUILD_DIR/NotifiCLI.app/Contents/Apps"
mkdir -p "$APPS_DIR"

for BASE_TYPE in "${VARIANTS[@]}"; do
    APP_NAME="${BASE_TYPE}-${VARIANT_NAME}"
    TARGET_APP="$APPS_DIR/${APP_NAME}.app"
    
    # Clean previous
    rm -rf "$TARGET_APP"
    
    CONTENTS_DIR="${TARGET_APP}/Contents"
    MACOS_DIR="${CONTENTS_DIR}/MacOS"
    RESOURCES_DIR="${CONTENTS_DIR}/Resources"
    
    mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

    # 1. Info.plist
    cp "$INFO_PLIST_SRC" "${CONTENTS_DIR}/Info.plist"
    if [ "$BASE_TYPE" == "NotifiPersistent" ]; then
        cp "$INFO_PERSISTENT_PLIST_SRC" "${CONTENTS_DIR}/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.saihgupr.NotifiPersistent.${VARIANT_NAME}" "${CONTENTS_DIR}/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleName '${DISPLAY_NAME} (Persistent)'" "${CONTENTS_DIR}/Info.plist"
    else
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.saihgupr.NotifiCLI.${VARIANT_NAME}" "${CONTENTS_DIR}/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleName '${DISPLAY_NAME}'" "${CONTENTS_DIR}/Info.plist"
    fi
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${APP_NAME}" "${CONTENTS_DIR}/Info.plist"

    # 2. Icon
    cp "$ICON_PATH" "${RESOURCES_DIR}/AppIcon.icns"

    # 3. Binary
    if [ "$BASE_TYPE" == "NotifiPersistent" ]; then
        if [ ! -f "$PERSISTENT_BIN" ]; then
            echo "Skipping Persistent variant (binary not found)"
            continue
        fi
        cp "$PERSISTENT_BIN" "${MACOS_DIR}/${APP_NAME}"
    else
        cp "$NOTIFICLI_BIN" "${MACOS_DIR}/${APP_NAME}"
    fi

    # 4. Sign (Removed entitlements for Tahoe compatibility)
    xattr -cr "$TARGET_APP" 2>/dev/null
    codesign --force --deep -s - "$TARGET_APP" 2>/dev/null
    
    # 5. Remove quarantine (helps with Sequoia/Tahoe notification permissions)
    xattr -d com.apple.quarantine "$TARGET_APP" 2>/dev/null || true
done

echo "✅ Created variant: $VARIANT_NAME"

# --- 4. Attempt to Install to /Applications ---

INSTALLED_APPS_DIR="/Applications/NotifiCLI.app/Contents/Apps"
if [ -d "$INSTALLED_APPS_DIR" ] && [ -w "$INSTALLED_APPS_DIR" ]; then
    echo "📦 Installing to /Applications..."
    cp -R "$APPS_DIR/NotifiCLI-${VARIANT_NAME}.app" "$INSTALLED_APPS_DIR/"
    cp -R "$APPS_DIR/NotifiPersistent-${VARIANT_NAME}.app" "$INSTALLED_APPS_DIR/"
    echo "✅ Installed to /Applications/NotifiCLI.app"
fi
