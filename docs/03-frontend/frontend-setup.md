# Frontend Setup Guide

Complete guide to setting up the Flutter frontend from scratch.

## 🎯 What You'll Learn

- Installing Flutter and dependencies
- Running the app on macOS
- Project structure overview
- Common development tasks

## 📋 Prerequisites

- macOS (for this project - configured for macOS target)
- Xcode Command Line Tools
- Git

## 🚀 Step 1: Install Flutter

### Download Flutter SDK

```bash
# Navigate to your home directory
cd ~

# Clone Flutter repository
git clone https://github.com/flutter/flutter.git -b stable

# Add Flutter to PATH
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

### Verify Installation

```bash
# Check Flutter version
flutter --version

# Should show:
Flutter 3.x.x • channel stable
```

### Run Flutter Doctor

```bash
flutter doctor
```

**Expected output:**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x)
[✓] Xcode - develop for iOS and macOS
[!] Chrome - develop for the web (optional)
[✓] VS Code (version x.x)
```

**Fix any issues:**
```bash
# If Xcode Command Line Tools missing:
xcode-select --install

# Accept Xcode license
sudo xcodebuild -license accept

# Install CocoaPods (for iOS dependencies)
sudo gem install cocoapods
```

## 📦 Step 2: Install Project Dependencies

### Navigate to Frontend Folder

```bash
cd /path/to/medical_app_v1/frontend
```

### Get Dependencies

```bash
# Download all packages from pubspec.yaml
flutter pub get
```

**What this does:**
- Reads `pubspec.yaml`
- Downloads packages to `.pub-cache/`
- Generates `.dart_tool/` and `.packages`
- Takes 1-2 minutes

### Verify Dependencies

```bash
# List installed packages
flutter pub deps

# Should show:
http 1.1.0
flutter_secure_storage 9.0.0
intl 0.18.1
# ... and more
```

## 🔧 Step 3: Project Configuration

### pubspec.yaml Overview

```yaml
name: medical_app
description: Medical appointment and pharmacy app
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # HTTP requests
  http: ^1.1.0
  
  # Secure token storage
  flutter_secure_storage: ^9.0.0
  
  # Date formatting
  intl: ^0.18.1
  
  # UI components
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

**Key Dependencies:**

| Package | Purpose | Used In |
|---------|---------|---------|
| `http` | API requests | ApiService |
| `flutter_secure_storage` | Encrypted token storage | AuthService |
| `intl` | Date/time formatting | All screens |

### API Configuration

**File:** `frontend/lib/services/api_service.dart`

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:5000';
  
  // For running on physical device, use computer's IP:
  // static const String baseUrl = 'http://192.168.1.x:5000';
}
```

**Change this if:**
- Backend runs on different port
- Testing on physical device (use IP address)
- Deploying to production (use production URL)

## 🏃 Step 4: Run the App

### Start Backend First

```bash
# In backend folder
cd backend
source venv/bin/activate
flask run
```

**Verify backend is running:**
```
 * Running on http://127.0.0.1:5000
```

### Start Frontend

```bash
# In frontend folder
cd frontend

# Run on macOS
flutter run -d macos
```

**What happens:**
1. Flutter compiles Dart code
2. Builds macOS app bundle
3. Launches app window
4. Enables hot reload

**First run takes 3-5 minutes** (subsequent runs are faster)

### App Running

You'll see:
```
Launching lib/main.dart on macOS in debug mode...
Building macOS application...
Syncing files to macOS...
Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

## 🔥 Step 5: Development Workflow

### Hot Reload

**Make a code change:**
```dart
// Change text in any screen
Text('Hello')  →  Text('Hello World')
```

**Press 'r' in terminal:**
```
r
Performing hot reload...
Reloaded 1 of 500 libraries in 150ms.
```

**Changes appear instantly!** (no rebuild needed)

### Hot Restart

**For bigger changes** (state reset, new files):
```
R
Performing hot restart...
Restarted application in 500ms.
```

### Debug Console

**Add print statements:**
```dart
void _loadData() async {
  print('Loading data...');
  final data = await apiService.get('/api/patient/profile');
  print('Data loaded: $data');
}
```

**See output in terminal:**
```
flutter: Loading data...
flutter: Data loaded: {success: true, data: {...}}
```

## 📁 Project Structure

```
frontend/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   │   ├── user_model.dart
│   │   ├── appointment_model.dart
│   │   └── medicine_model.dart
│   ├── screens/               # UI screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── patient/
│   │   │   ├── patient_dashboard.dart
│   │   │   ├── find_doctor_screen.dart
│   │   │   └── buy_medicine_screen.dart
│   │   ├── doctor/
│   │   ├── medical_store/
│   │   └── lab_store/
│   └── services/              # Business logic
│       ├── api_service.dart
│       └── auth_service.dart
├── assets/                    # Images, fonts
├── test/                      # Unit tests
├── pubspec.yaml               # Dependencies
└── macos/                     # macOS-specific config
```

## 🎨 Step 6: Running on Different Platforms

### macOS (Default)

```bash
flutter run -d macos
```

### Web (if needed)

```bash
# Enable web
flutter config --enable-web

# Run on Chrome
flutter run -d chrome
```

### iOS Simulator (if needed)

```bash
# List devices
flutter devices

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"
```

## 🔍 Step 7: Testing

### Run Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/auth_service_test.dart

# Run with coverage
flutter test --coverage
```

### Example Test

**File:** `test/services/auth_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_app/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    test('Login with valid credentials', () async {
      final authService = AuthService();
      final result = await authService.login(
        'patient@test.com',
        'password123',
      );
      expect(result, true);
    });

    test('Login with invalid credentials', () async {
      final authService = AuthService();
      final result = await authService.login(
        'wrong@email.com',
        'wrongpass',
      );
      expect(result, false);
    });
  });
}
```

## 🛠️ Common Development Tasks

### Add a New Package

```bash
# Add to pubspec.yaml
flutter pub add package_name

# Example: Add provider for state management
flutter pub add provider
```

### Update Packages

```bash
# Update all packages
flutter pub upgrade

# Update specific package
flutter pub upgrade http
```

### Clean Build

```bash
# If app behaves strangely
flutter clean
flutter pub get
flutter run -d macos
```

### Generate Icons

```bash
# If you have app icons in assets/
flutter pub add flutter_launcher_icons
flutter pub run flutter_launcher_icons
```

## 🐛 Troubleshooting

### Issue 1: "Unable to load asset"

```
Error: Unable to load asset: assets/images/logo.png
```

**Solution:**
```yaml
# Add to pubspec.yaml
flutter:
  assets:
    - assets/images/
```

Then run:
```bash
flutter pub get
flutter run
```

### Issue 2: "Connection refused"

```
SocketException: Connection refused (OS Error: Connection refused, errno = 61)
```

**Solution:**
1. Check backend is running (`flask run`)
2. Verify `baseUrl` in `api_service.dart`
3. Check firewall settings

### Issue 3: "No devices found"

```
No supported devices connected.
```

**Solution:**
```bash
# macOS target
flutter config --enable-macos-desktop
flutter create --platforms=macos .

# Check devices
flutter devices
```

### Issue 4: "CocoaPods not installed"

```
Error: CocoaPods not installed or not in valid state.
```

**Solution:**
```bash
sudo gem install cocoapods
pod setup
```

### Issue 5: "Build failed"

```
Error: Build failed with an exception.
```

**Solution:**
```bash
# Clean and rebuild
flutter clean
cd macos
pod install
cd ..
flutter run -d macos
```

## ✅ Verification Checklist

After setup, verify:

- [ ] `flutter doctor` shows no critical errors
- [ ] `flutter pub get` completes successfully
- [ ] Backend running on http://localhost:5000
- [ ] `flutter run -d macos` launches app
- [ ] Login screen appears
- [ ] Can login with test credentials
- [ ] Hot reload works (press 'r')
- [ ] Debug console shows print statements

## 🎯 Next Steps

Now that frontend is running:

1. Read [Frontend Screens Guide](./frontend-screens.md) to understand UI structure
2. Read [State Management Guide](./state-management.md) for data handling
3. Read [API Integration Guide](./api-integration.md) for backend communication

## 📚 Useful Commands Reference

```bash
# Development
flutter run -d macos          # Run app
flutter run --release          # Release mode (faster)
r                             # Hot reload
R                             # Hot restart
q                             # Quit

# Dependencies
flutter pub get               # Install dependencies
flutter pub upgrade           # Update packages
flutter pub outdated          # Check for updates

# Building
flutter build macos           # Build macOS app
flutter build web             # Build web app

# Cleaning
flutter clean                 # Clean build files
flutter pub cache repair      # Fix package cache

# Analysis
flutter analyze               # Check for issues
flutter test                  # Run tests
flutter doctor                # Check setup

# Debugging
flutter logs                  # Show logs
flutter devices               # List devices
```

---

**Need Help?**
- Check [Common Issues](../06-maintenance/common-issues.md)
- Review [Frontend Module Guide](./frontend-module-guide.md)
