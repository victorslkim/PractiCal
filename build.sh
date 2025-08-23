#!/bin/bash

# PractiCal iOS App Build Script
# Builds for physical device (if connected) or falls back to iOS Simulator

echo "🔨 Building PractiCal iOS App..."

# Load configuration
CONFIG_FILE="build.config"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Configuration file '$CONFIG_FILE' not found!"
    echo "📝 Please copy 'build.config.template' to '$CONFIG_FILE' and configure it with your Apple Developer details."
    echo ""
    echo "Example:"
    echo "  cp build.config.template build.config"
    echo "  # Edit build.config with your Team ID and Bundle ID"
    echo "  ./build.sh"
    exit 1
fi

# Source the configuration
source "$CONFIG_FILE"

# Validate required configuration
if [[ -z "$TEAM_ID" || "$TEAM_ID" == "YOUR_TEAM_ID_HERE" ]]; then
    echo "❌ TEAM_ID not configured in $CONFIG_FILE"
    echo "📝 Please edit $CONFIG_FILE and set your Apple Developer Team ID"
    exit 1
fi

if [[ -z "$BUNDLE_ID" || "$BUNDLE_ID" == "com.yourcompany.PractiCal" ]]; then
    echo "❌ BUNDLE_ID not configured in $CONFIG_FILE" 
    echo "📝 Please edit $CONFIG_FILE and set your app's Bundle ID"
    exit 1
fi

# Default values
APP_NAME=${APP_NAME:-PractiCal}
SIMULATOR_NAME=${SIMULATOR_NAME:-iPhone 16 Pro}

echo "📋 Configuration:"
echo "   Team ID: $TEAM_ID"
echo "   Bundle ID: $BUNDLE_ID"
echo "   App Name: $APP_NAME"

echo "🧹 Cleaning previous build artifacts..."
rm -rf "$APP_NAME.app" "$APP_NAME-Simulator.app" "$APP_NAME.app.entitlements"
rm -f PractiCal-Device PractiCal-Simulator
rm -f PractiCal/PractiCal PractiCal/PractiCal-Simulator PractiCal/PractiCal-iOS

# Source files list (shared between device and simulator builds)
SOURCE_FILES=(
    "PractiCal/PractiCalApp.swift"
    "PractiCal/Shared/Event.swift"
    "PractiCal/Shared/Event+Samples.swift"
    "PractiCal/Shared/LayoutConstants.swift"
    "PractiCal/Shared/AppSettings.swift"
    "PractiCal/Shared/CalendarManager.swift"
    "PractiCal/Shared/ThemeManager.swift"
    "PractiCal/Shared/WeekSettings.swift"
    "PractiCal/Shared/HolidaySystem.swift"
    "PractiCal/Shared/EventHelpers.swift"
    "PractiCal/SearchScreen/SearchResultRow.swift"
    "PractiCal/SearchScreen/SearchView.swift"
    "PractiCal/EventEditorScreen/EventEditorView.swift"
    "PractiCal/EventEditorScreen/EventFormSections.swift"
    "PractiCal/EventEditorScreen/EventInfoView.swift"
    "PractiCal/EventEditorScreen/AlertPickerSheet.swift"
    "PractiCal/SettingsScreen/SettingsView.swift"
    "PractiCal/SettingsScreen/CalendarPreview.swift"
    "PractiCal/SettingsScreen/EditEventSettingsView.swift"
    "PractiCal/SettingsScreen/NotificationSettingsView.swift"
    "PractiCal/SettingsScreen/HelpView.swift"
    "PractiCal/SettingsScreen/DefaultCalendarPickerSheet.swift"
    "PractiCal/SettingsScreen/DayCellPreview.swift"
    "PractiCal/SettingsScreen/EventRowCardCustomizationView.swift"
    "PractiCal/Localization/LanguageManager.swift"
    "PractiCal/Localization/LanguageManager+StringLocalized.swift"
    "PractiCal/Localization/LanguageManager+WeekdaySymbols.swift"
    "PractiCal/Localization/LanguageSelectionView.swift"
    "PractiCal/Localization/LocalizationHelper.swift"
    "PractiCal/Localization/LocalizationKeys.swift"
    "PractiCal/CalendarSelectionScreen/CalendarSelectionView.swift"
    "PractiCal/CalendarSelectionScreen/CalendarInfoView.swift"
    "PractiCal/MainScreen/MainView.swift"
    "PractiCal/MainScreen/HeaderView.swift"
    "PractiCal/MainScreen/CalendarViewModel.swift"
    "PractiCal/MainScreen/EventListView.swift"
    "PractiCal/MainScreen/WeekRowView.swift"
    "PractiCal/MainScreen/MonthView/MonthView.swift"
    "PractiCal/MainScreen/MonthView/LaneEvent.swift"
    "PractiCal/MainScreen/MonthView/DateNumbersRow.swift"
    "PractiCal/MainScreen/MonthView/EventsAreaView.swift"
    "PractiCal/MainScreen/MonthView/MultiDayLanesView.swift"
    "PractiCal/MainScreen/MonthView/SingleDayChipsView.swift"
)

# Function to find matching provisioning profile
find_provisioning_profile() {
    local DEV_TEAM=$1
    local PROFILE_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
    
    if ls "$PROFILE_DIR"/*.mobileprovision 2>/dev/null >/dev/null; then
        echo "📋 Searching for provisioning profiles..."
        for profile in "$PROFILE_DIR"/*.mobileprovision; do
            # Extract App ID from provisioning profile
            local PROFILE_APP_ID=$(security cms -D -i "$profile" 2>/dev/null | plutil -extract Entitlements.application-identifier raw -)
            if [[ "$PROFILE_APP_ID" == "$DEV_TEAM.$BUNDLE_ID" ]]; then
                echo "✅ Found matching provisioning profile: $(basename "$profile")"
                echo "$profile"
                return 0
            fi
        done
        echo "⚠️  No provisioning profile found for App ID: $DEV_TEAM.$BUNDLE_ID"
        return 1
    else
        echo "⚠️  No provisioning profiles found in $PROFILE_DIR"
        return 1
    fi
}

# Try to build for physical device first
build_for_device() {
    # Check if device is connected
    DEVICE_ID=""
    if [[ -n "$TARGET_DEVICE_ID" ]]; then
        # Use specific device if configured
        DEVICE_ID="$TARGET_DEVICE_ID"
        echo "📱 Using configured device: $DEVICE_ID"
    else
        # Auto-detect connected device - extract UUID from the line
        DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | grep -E "available \(paired\)" | head -1 | grep -o '[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}')
        if [[ -n "$DEVICE_ID" ]]; then
            local device_name=$(xcrun devicectl list devices 2>/dev/null | grep -E "available \(paired\)" | head -1 | awk -F'   ' '{print $1}')
            echo "📱 Found connected device: $device_name ($DEVICE_ID)"
        else
            echo "📱 No connected devices found"
            return 1
        fi
    fi
    
    # Find development certificate
    echo "🔍 Looking for development certificates..."
    local CERT_IDENTITY=""
    if [[ -n "$CODE_SIGN_IDENTITY" ]]; then
        CERT_IDENTITY="$CODE_SIGN_IDENTITY"
        echo "🔑 Using configured certificate: $CERT_IDENTITY"
    else
        CERT_IDENTITY=$(security find-identity -v -p codesigning | grep -E "(Apple Development|iPhone Developer)" | head -1 | cut -d'"' -f2)
    fi
    
    if [[ -n "$CERT_IDENTITY" ]]; then
        # Extract team ID from certificate (from Subject line) if not already configured
        local DETECTED_TEAM=$(security find-certificate -c "$CERT_IDENTITY" -p | openssl x509 -text -noout | grep "Subject:" | sed -n 's/.*OU=\([^,]*\).*/\1/p')
        echo "🔑 Found certificate: $CERT_IDENTITY"
        echo "👥 Team ID: $TEAM_ID (detected: $DETECTED_TEAM)"
        
        # Find matching provisioning profile
        MATCHING_PROFILE=$(find_provisioning_profile "$TEAM_ID")
        
        if [[ $? -eq 0 ]]; then
            echo "🔨 Building for device..."
            
            # Create entitlements file
            cat > "$APP_NAME.app.entitlements" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>$TEAM_ID.$BUNDLE_ID</string>
    <key>keychain-access-groups</key>
    <array>
        <string>$TEAM_ID.*</string>
    </array>
    <key>get-task-allow</key>
    <true/>
    <key>com.apple.developer.team-identifier</key>
    <string>$TEAM_ID</string>
</dict>
</plist>
EOF
            
            # Create Info.plist with dynamic values
            cat > "$APP_NAME.app/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UILaunchScreen</key>
    <dict/>
    <key>NSCalendarsUsageDescription</key>
    <string>This app needs access to your calendar to display and manage events.</string>
</dict>
</plist>
EOF
            
            if swiftc -target arm64-apple-ios17.0 -sdk $(xcrun --sdk iphoneos --show-sdk-path) "${SOURCE_FILES[@]}" -o "$APP_NAME.app/$APP_NAME" -import-objc-header PractiCal/PractiCal-Bridging-Header.h 2>/dev/null || swiftc -target arm64-apple-ios17.0 -sdk $(xcrun --sdk iphoneos --show-sdk-path) "${SOURCE_FILES[@]}" -o "$APP_NAME.app/$APP_NAME"; then
                if [[ -n "$MATCHING_PROFILE" ]]; then
                    # Embed provisioning profile
                    echo "📋 Embedding provisioning profile..."
                    cp "$MATCHING_PROFILE" $APP_NAME.app/embedded.mobileprovision
                fi
                
                echo "🔑 Code signing app..."
                codesign --force --sign "$CERT_IDENTITY" --entitlements "$APP_NAME.app.entitlements" "$APP_NAME.app"
                
                echo "📱 Installing app on device..."
                if xcrun devicectl device install app --device "$DEVICE_ID" "$APP_NAME.app"; then
                    echo "✅ App installed successfully!"
                    
                    echo "🚀 Launching app..."
                    if xcrun devicectl device process launch --device $DEVICE_ID $BUNDLE_ID; then
                        echo "🎉 $APP_NAME app is now running on device!"
                        return 0
                    else
                        echo "⚠️  App installed but failed to launch"
                        return 1
                    fi
                else
                    echo "❌ Failed to install app on device"
                    return 1
                fi
            else
                echo "❌ Swift compilation failed"
                return 1
            fi
        else
            echo "❌ No matching provisioning profile found"
            return 1
        fi
    else
        echo "❌ No development certificates found, falling back to simulator..."
        return 1
    fi
}

# Build for iOS Simulator
build_for_simulator() {
    echo "❌ Device build failed, falling back to simulator..."
    echo "📱 Building for iOS Simulator..."
    
    # Create Info.plist for simulator
    mkdir -p "$APP_NAME-Simulator.app"
    cat > "$APP_NAME-Simulator.app/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME-Simulator</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>UILaunchScreen</key>
    <dict/>
    <key>NSCalendarsUsageDescription</key>
    <string>This app needs access to your calendar to display and manage events.</string>
</dict>
</plist>
EOF
    
    echo "🔨 Compiling for simulator..."
    if swiftc -target x86_64-apple-ios17.0-simulator -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) "${SOURCE_FILES[@]}" -o "$APP_NAME-Simulator.app/$APP_NAME-Simulator" -import-objc-header PractiCal/PractiCal-Bridging-Header.h 2>/dev/null || swiftc -target x86_64-apple-ios17.0-simulator -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) "${SOURCE_FILES[@]}" -o "$APP_NAME-Simulator.app/$APP_NAME-Simulator"; then
        echo "✅ Simulator build successful!"
        
        echo "📦 Updating app bundle..."
        echo "🎨 Copying app assets..."
        cp -r PractiCal/Assets.xcassets "$APP_NAME-Simulator.app/"
        
        echo "🌐 Adding localization files..."
        find PractiCal/Localization -name "*.lproj" | while read -r lproj_dir; do
            lproj_name=$(basename "$lproj_dir")
            cp -r "$lproj_dir" "$APP_NAME-Simulator.app/"
            echo "✅ Added $lproj_name localization"
        done
        
        echo "📱 Installing on simulator..."
        xcrun simctl install "$SIMULATOR_NAME" "$APP_NAME-Simulator.app"
        
        echo "🚀 Launching app..."
        xcrun simctl launch "$SIMULATOR_NAME" $BUNDLE_ID
        
        echo "🎉 $APP_NAME app is now running in simulator!"
        return 0
    else
        echo "❌ Simulator build failed!"
        return 1
    fi
}

# Main build flow
mkdir -p "$APP_NAME.app"

# Copy assets and localization for device build
echo "🎨 Copying app assets..."
cp -r PractiCal/Assets.xcassets "$APP_NAME.app/"

echo "🌐 Adding localization files..."
find PractiCal/Localization -name "*.lproj" | while read -r lproj_dir; do
    lproj_name=$(basename "$lproj_dir")
    cp -r "$lproj_dir" "$APP_NAME.app/"
    echo "✅ Added $lproj_name localization"
done

# Try device build first, fallback to simulator
if ! build_for_device; then
    build_for_simulator
fi

# Clean up intermediate build files
echo "🧹 Cleaning up intermediate build files..."
rm -f PractiCal-Device PractiCal-Simulator
rm -f PractiCal/PractiCal PractiCal/PractiCal-Simulator PractiCal/PractiCal-iOS
rm -f *.o *.dSYM