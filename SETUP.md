# Flutter Development Environment Setup for macOS

This guide provides step-by-step instructions for setting up a Flutter development environment on macOS without using Android Studio.

## Prerequisites

- macOS with Homebrew installed
- Xcode installed from the App Store
- Terminal access

## 1. Install Flutter

```bash
brew install flutter
```

Verify the installation:

```bash
flutter doctor
```

## 2. Android Development Setup (Without Android Studio)

### Install Android SDK Command Line Tools

```bash
brew install android-commandlinetools
```

### Install Required Android Components

```bash
# Install platform tools, Android SDK, and build tools
sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Verify installed components
sdkmanager --list_installed
```

### Configure Android SDK Path

Create a symlink for Android SDK:

```bash
ln -s /opt/homebrew/share/android-commandlinetools ~/Library/Android/sdk
```

Set up environment variables in your shell profile (~/.zshrc or ~/.bash_profile):

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

### Accept Android Licenses

```bash
flutter doctor --android-licenses
```

### Install Java (Required for Android builds)

```bash
brew install openjdk@17
flutter config --jdk-dir /opt/homebrew/opt/openjdk@17
```

Verify Java installation:

```bash
flutter doctor -v | grep -A5 "Java"
```

## 3. iOS Development Setup

### Configure Xcode

```bash
# Switch to Xcode developer tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Run Xcode first launch setup
sudo xcodebuild -runFirstLaunch
```

### Install CocoaPods

```bash
brew install cocoapods
pod setup
pod --version
```

## 4. Project Setup

Navigate to the Vapi Flutter SDK directory:

```bash
# Install dependencies for the main project
flutter pub get

# Install dependencies for the example project
cd example
flutter pub get
```

## 5. Running the Project

### Check Available Devices

```bash
flutter devices
flutter emulators
```

### macOS

```bash
flutter run -d macos
# or build
flutter build macos
```

### iOS Simulator

```bash
# List available simulators
xcrun simctl list devices available

# Open iOS Simulator
open -a Simulator

# Run on specific device
flutter run -d "iPhone 16 Plus"
```

### Android Emulator

#### Create an Android Emulator

```bash
# Download Android system image
sdkmanager --install "platforms;android-36" "system-images;android-36;google_apis_playstore;arm64-v8a"

# Create emulator
avdmanager create avd -n android36_emulator -k "system-images;android-36;google_apis_playstore;arm64-v8a" -d pixel_7_pro

# List available emulators
avdmanager list avd
```

#### Run Android Emulator

```bash
# Launch emulator
flutter emulators --launch android36_emulator

# Run app on emulator
flutter devices  # Note the device ID (e.g., emulator-5554)
flutter run -d emulator-5554

# Check connected devices
adb devices
```

### Web (Note: Limited Support)

```bash
flutter run -d chrome
```

**⚠️ Important:** The Vapi SDK has limited web support because the daily_flutter dependency uses native code (FFI) that's not available in web browsers.

## 6. Building the Project

### Android APK

```bash
cd example
flutter clean
flutter build apk --debug
```

**macOS Gatekeeper Fix:** If the build fails due to macOS Gatekeeper blocking the gen_snapshot binary:

```bash
find /opt/homebrew/Caskroom/flutter/ -name gen_snapshot -exec sudo xattr -rd com.apple.quarantine {} \;
```

## 7. Useful Commands

### Git Operations

```bash
# Switch to a pull request branch
gh pr checkout <PR_NUMBER>
```

### Cleanup Commands

```bash
# Delete an emulator
avdmanager delete avd -n <emulator_name>

# Uninstall system images
sdkmanager --uninstall "system-images;android-34;google_apis_playstore;arm64-v8a"
```

## Troubleshooting

1. **Flutter Doctor Issues**: Run `flutter doctor -v` for detailed diagnostics
2. **Android License Issues**: Re-run `flutter doctor --android-licenses` and accept all
3. **Xcode Issues**: Ensure Xcode is properly installed and command line tools are configured
4. **Build Failures**: Try `flutter clean` before rebuilding

## Next Steps

After setup is complete, you can:

- Run the example app on various platforms
- Modify the code and test hot reload
- Build release versions for distribution

For more information, refer to the [Flutter documentation](https://flutter.dev/docs).
