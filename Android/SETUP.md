# PractiCal Android - Setup Guide

This document provides complete setup instructions for building and deploying the PractiCal Android app.

## Prerequisites

### 1. Install Development Tools

#### Using Homebrew (Recommended)
```bash
# Install Android SDK command line tools
brew install --cask android-commandlinetools
brew install --cask android-platform-tools

# Install Java using SDKMAN (required for Android development)
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 17.0.13-tem
sdk install gradle 8.0
```

#### Alternative: Android Studio
1. Download Android Studio from https://developer.android.com/studio
2. Install and follow the setup wizard
3. Install Android SDK API 34 and build tools

### 2. Set Environment Variables

Add these to your `~/.zshrc` or `~/.bash_profile`:

```bash
# Android SDK
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# SDKMAN (for Java/Gradle)
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

Reload your shell:
```bash
source ~/.zshrc  # or ~/.bash_profile
```

### 3. Install Android SDK Components

```bash
# Accept licenses and install required components
echo y | sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

## Building the App

### 1. Navigate to Android Directory
```bash
cd /path/to/PractiCal/Android
```

### 2. Build Debug APK
```bash
# Using the build script
./build.sh

# Or directly with Gradle
./gradlew assembleDebug
```

### 3. Build Output
The APK will be generated at:
```
app/build/outputs/apk/debug/app-debug.apk
```

## Device Setup

### 1. Enable Developer Options
On your Android device:
1. Go to **Settings > About Phone**
2. Tap **Build Number** 7 times
3. Go back to **Settings > Developer Options**
4. Enable **USB Debugging**

### 2. Connect Device
```bash
# Check if device is connected
adb devices

# Should show your device listed
```

### 3. Install APK
```bash
# Install to connected device
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Troubleshooting

### Java Version Issues
```bash
# Check Java version
java -version

# Should show OpenJDK 17.x.x
# If not, run:
sdk use java 17.0.13-tem
```

### Android SDK Issues
```bash
# Check SDK installation
sdkmanager --list_installed

# Re-install if needed
sdkmanager --install "platforms;android-34"
```

### Build Failures
```bash
# Clean and rebuild
./gradlew clean
./gradlew assembleDebug
```

### Permission Issues
If the app crashes on startup:
1. Go to device Settings > Apps > PractiCal
2. Grant Calendar permissions manually

## Project Structure

```
Android/
├── app/
│   ├── src/main/
│   │   ├── kotlin/com/practical/calendar/
│   │   │   ├── data/          # Data models and repositories
│   │   │   ├── di/            # Dependency injection
│   │   │   ├── ui/            # UI components and screens
│   │   │   └── MainActivity.kt
│   │   ├── res/               # Resources (layouts, strings, etc.)
│   │   └── AndroidManifest.xml
│   └── build.gradle           # App-level build config
├── gradle/                    # Gradle wrapper
├── build.gradle              # Project-level build config
├── settings.gradle           # Project settings
└── build.sh                 # Build script
```

## Features Implemented

- ✅ Complete Jetpack Compose UI
- ✅ Month/Week/Day calendar views  
- ✅ Calendar integration (Android Calendar Provider)
- ✅ Material 3 design system
- ✅ Multi-language support (40+ languages)
- ✅ Settings and preferences
- ✅ Event management interface
- ✅ Proper Android architecture (MVVM + Hilt)

## Next Steps

After successful build and installation:

1. **Grant Calendar Permissions**: The app will request calendar access on first launch
2. **Test Core Features**: Navigate between Month/Week/Day views
3. **Verify Calendar Integration**: Check if your device's calendar events appear
4. **Test Localization**: Change device language to verify translations

## Support

For build issues:
1. Ensure all prerequisites are correctly installed
2. Check environment variables are set
3. Verify Android device is properly connected
4. Review build logs for specific error messages

The Android app now mirrors the iOS functionality with native Android UX patterns.