# SeevakCare Logo Integration Guide

## Logo Usage

The SeevakCare logo has been integrated across the application. Follow these steps to complete the integration:

## Step 1: Add Logo Image

**Location:** `.flutter_app/assets/images/`

1. Save the provided SeevakCare logo as: **`logo.png`**
   - The file should be placed at: `c:\Users\abish\MedicalApp\.flutter_app\assets\images\logo.png`
   - Format: PNG (with transparency support)
   - Recommended size: 400x300px or higher

2. The assets folder is already configured in `pubspec.yaml`:
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/images/
   ```

## Step 2: Logo Placement in App

The logo is now displayed in the following screens:

### Authentication Screens
- **Login Screen** - Logo displayed at top (100x140)
- **Register Screen** - Logo displayed at top (80x110) with "Create Your Account" heading
- **Forgot Password Screen** - Logo displayed at top
- **Reset Password Screen** - Can be updated if needed

### How It Works
All screens reference the logo using:
```dart
Image.asset(
  'assets/images/logo.png',
  fit: BoxFit.contain,
)
```

## Step 3: App Icon Configuration

The app icon has been set to use `Icon-192.png` from the icons folder. For best results:

1. Generate your own app icon in multiple sizes:
   - `.flutter_app/android/app/src/main/res/` (various sizes)
   - `.flutter_app/ios/Runner/` (Info.plist configured)
   - `.flutter_app/web/icons/` (web versions)

2. Update references in:
   - `android/app/build.gradle` - AndroidManifest.xml
   - `ios/Runner/Info.plist`
   - `web/index.html` - Already configured to use `Icon-192.png`

## Step 4: Build & Test

After placing the logo image:

```bash
# Clean Flutter build
cd .flutter_app
flutter clean
flutter pub get

# Run the app
flutter run -d web-server --web-port=8080
```

## Logo Customization Options

### Change Logo Size
Edit the `Container` height/width in each screen:

**Login Screen** (`.flutter_app/lib/screens/auth/login_screen.dart`):
```dart
Container(
  height: 100,    // Adjust this
  width: 140,     // And this
  ...
)
```

### Add Logo to Dashboards
To add the logo to dashboard headers, add this to each dashboard's AppBar:

```dart
AppBar(
  leading: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Image.asset('assets/images/logo.png'),
  ),
  title: const Text('Dashboard'),
)
```

### Add Logo to Web Footer
Add to the web version's footer or header component.

## Supported Logo Formats
- PNG (recommended - supports transparency)
- JPG (works but no transparency)
- WebP (modern format)

## Troubleshooting

### Logo not showing after build
```bash
# Clear Flutter cache
flutter clean
rm -rf build/

# Rebuild
flutter pub get
flutter run
```

### AssetImage not found error
- Verify file exists at: `.flutter_app/assets/images/logo.png`
- Check pubspec.yaml has correct asset path
- Run `flutter pub get` to reload assets

### Image appears blurry
- Use higher resolution image (at least 400x300px)
- Use PNG format for better quality
- Consider adding to multiple densities for different screen sizes

## Files Modified

1. **`.flutter_app/lib/screens/auth/login_screen.dart`**
   - Updated logo reference to `logo.png`
   - Increased logo size from 80x120 to 100x140

2. **`.flutter_app/lib/screens/auth/register_screen.dart`**
   - Added logo display (80x110)
   - Added "Create Your Account" heading

3. **`.flutter_app/lib/screens/auth/forgot_password_screen.dart`**
   - Already has logo configured

4. **Web favicon references updated**
   - `.flutter_app/frontend/web_dist/index.html`
   - `._render_deploy/frontend/web/index.html`

## Next Steps

1. ✅ Place the `logo.png` file in the assets folder
2. ✅ Run `flutter clean && flutter pub get`
3. ✅ Test the app on web/mobile
4. ✅ Adjust logo sizes if needed
5. Optional: Add logo to dashboard app bars for consistency

## Support

For any issues with logo integration:
- Email: seevakcare@gmail.com
- Phone: +91 9771365160
