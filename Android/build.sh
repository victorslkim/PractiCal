#!/bin/bash

# Android Build Script for PractiCal
echo "Building PractiCal Android App..."

# Set up Android development environment
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@17/17.0.16/libexec/openjdk.jdk/Contents/Home
export PATH=/opt/homebrew/Cellar/openjdk@17/17.0.16/libexec/openjdk.jdk/Contents/Home/bin:$PATH
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH=$PATH:/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin:/opt/homebrew/share/android-commandlinetools/platform-tools

# Check for --device flag
LAUNCH_APP=false
if [ "$1" = "--device" ]; then
    LAUNCH_APP=true
fi

# Check if Android SDK is available
if [ -z "$ANDROID_HOME" ]; then
    echo "Error: ANDROID_HOME is not set. Please set it to your Android SDK location."
    exit 1
fi

# Clean previous build
echo "Cleaning previous build..."
./gradlew clean

# Build debug APK
echo "Building debug APK..."
./gradlew assembleDebug

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "APK location: app/build/outputs/apk/debug/app-debug.apk"
    
    # Install to connected device if --device flag is used or device is connected
    if [ "$LAUNCH_APP" = true ] || (command -v adb &> /dev/null && adb devices | grep -q "device$"); then
        if command -v adb &> /dev/null && adb devices | grep -q "device$"; then
            echo "Installing on connected device..."
            adb install -r app/build/outputs/apk/debug/app-debug.apk
            
            if [ $? -eq 0 ]; then
                echo "🚀 Launching app..."
                adb shell am start -n com.practical.calendar/.MainActivity
                
                if [ $? -eq 0 ]; then
                    echo "✅ App launched successfully!"
                else
                    echo "⚠️  App installed but failed to launch. You can manually open PractiCal on your device."
                fi
            else
                echo "❌ Failed to install app"
            fi
        else
            echo "⚠️  No Android device connected or ADB not available"
        fi
    fi
else
    echo "❌ Build failed!"
    exit 1
fi