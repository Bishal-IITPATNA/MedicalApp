# Frontend Module Ownership Guide

Guide for organizing frontend development by feature/screen modules.

## 📱 Module Structure

```
frontend/lib/
├── main.dart                # App entry (Team: Core)
├── models/                  # Data models (Team: All - shared)
├── services/                # API & Auth (Team: Core)
├── screens/                 # UI screens (Teams by feature)
│   ├── auth/               # Team A
│   ├── patient/            # Team B
│   ├── doctor/             # Team C
│   ├── medical_store/      # Team D
│   ├── lab_store/          # Team E
│   └── nurse/              # Team F
└── widgets/                 # Shared components (Team: All)
```

## 👥 Team Assignments

### Team A: Authentication & Onboarding

**Owns:**
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/register_screen.dart`
- `lib/services/auth_service.dart`

**Responsibilities:**
- Login/registration UI
- Form validation
- Role selection
- Session management
- Password reset (future)

**Key Files:**
```
lib/screens/auth/
├── login_screen.dart          # Login form
├── register_screen.dart       # Registration with role
└── forgot_password_screen.dart # (Future)
```

---

### Team B: Patient Experience

**Owns:**
- `lib/screens/patient/patient_dashboard.dart`
- `lib/screens/patient/find_doctor_screen.dart`
- `lib/screens/patient/book_appointment_screen.dart`
- `lib/screens/patient/buy_medicine_screen.dart`
- `lib/screens/patient/book_lab_test_screen.dart`

**Responsibilities:**
- Patient dashboard with 4 tabs
- Doctor search and booking
- Medicine ordering with prescription validation
- Lab test booking
- Appointment and order history

**Module Dependencies:**
- Uses: AuthService (Team A)
- Uses: Doctor, Medicine, LabTest models
- Calls: Patient API endpoints

---

### Team C: Doctor Portal

**Owns:**
- `lib/screens/doctor/doctor_dashboard.dart`
- `lib/screens/doctor/patient_detail_screen.dart`
- `lib/screens/doctor/doctor_profile_screen.dart`
- `lib/screens/doctor/write_prescription_screen.dart`

**Responsibilities:**
- Doctor appointment management
- Patient details view
- Prescription writing
- Chamber management
- Schedule configuration

**Complex Features:**
- Multiple chambers support (JSON handling)
- Dynamic prescription form
- Appointment status updates

---

### Team D: Medical Store Management

**Owns:**
- `lib/screens/medical_store/medical_store_dashboard.dart`
- `lib/screens/medical_store/order_medicines_screen.dart`
- `lib/screens/medical_store/analytics_screen.dart`

**Responsibilities:**
- Medicine inventory CRUD
- Order management
- Analytics dashboard
- Stock alerts

---

### Team E: Lab Store Management

**Owns:**
- `lib/screens/lab_store/lab_store_dashboard.dart`
- `lib/screens/lab_store/manage_tests_screen.dart`
- `lib/screens/lab_store/analytics_screen.dart`
- `lib/screens/lab_store/profile_screen.dart`
- `lib/screens/lab_store/settings_screen.dart`

**Responsibilities:**
- Lab test catalog management
- Test order processing
- Result entry (JSON format)
- Analytics dashboard
- Profile/settings (top-right menu)

**Special Implementation:**
- Profile response parsing: `responseData?['data']`
- Settings in menu (not bottom nav)
- Analytics accessible from app bar

---

### Team F: Nurse Portal

**Owns:**
- `lib/screens/nurse/nurse_dashboard.dart`
- `lib/screens/nurse/patient_vitals_screen.dart`

**Responsibilities:**
- Patient vitals recording
- Appointment assistance
- Doctor schedule viewing

---

## 🔄 Cross-Team Communication

### Shared Components

**Location:** `lib/widgets/`

```
lib/widgets/
├── custom_button.dart         # Reusable button
├── loading_indicator.dart     # Loading states
├── error_display.dart         # Error messages
├── appointment_card.dart      # Appointment UI
└── medicine_card.dart         # Medicine UI
```

**Usage:**
```dart
import 'package:medical_app/widgets/custom_button.dart';

CustomButton(
  text: 'Book Appointment',
  onPressed: () => _handleBooking(),
  isLoading: _isLoading,
)
```

### Shared Models

**Location:** `lib/models/`

All teams can use these models:
- `user_model.dart`
- `appointment_model.dart`
- `medicine_model.dart`
- `doctor_model.dart`
- `lab_test_model.dart`

**Modifying Models:**
1. Create issue describing change
2. Notify all teams
3. Create PR
4. Wait for approval from affected teams

---

## 🧪 Testing Your Module

### Unit Tests

**Structure:**
```
test/
├── screens/
│   ├── auth/
│   │   ├── login_screen_test.dart
│   │   └── register_screen_test.dart
│   ├── patient/
│   │   └── patient_dashboard_test.dart
│   └── ...
└── services/
    ├── api_service_test.dart
    └── auth_service_test.dart
```

**Example Test:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen()),
    );

    // Verify email field exists
    expect(find.byType(TextField), findsNWidgets(2));
    
    // Verify login button exists
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Login button disabled when loading', (WidgetTester tester) async {
    // ... test implementation
  });
}
```

---

## 📋 Development Workflow

### 1. Feature Development

```bash
# Create feature branch
git checkout -b feature/patient-medicine-cart

# Work on your screens
# ... edit files in lib/screens/patient/ ...

# Run app to test
flutter run -d macos

# Hot reload to see changes instantly
# (press 'r' in terminal)

# Commit when done
git add lib/screens/patient/
git commit -m "Add medicine cart with prescription validation"
```

### 2. Adding New Screen

**Steps:**
1. Create screen file in your module folder
2. Add route in `main.dart`
3. Update navigation from other screens
4. Test navigation flow
5. Add any required models
6. Document in this guide

**Example:**
```dart
// 1. Create file: lib/screens/patient/prescriptions_screen.dart
class PrescriptionsScreen extends StatefulWidget {
  @override
  _PrescriptionsScreenState createState() => _PrescriptionsScreenState();
}

// 2. Add route in main.dart
MaterialApp(
  routes: {
    '/patient/prescriptions': (context) => PrescriptionsScreen(),
    // ... other routes
  },
)

// 3. Navigate from dashboard
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/patient/prescriptions');
  },
  child: Text('View Prescriptions'),
)
```

### 3. Updating UI

```dart
// Make changes
Widget _buildOldUI() {
  return Text('Old design');
}

// ↓ Change to ↓

Widget _buildNewUI() {
  return Card(
    child: Text('New design'),
  );
}

// Press 'r' for hot reload - see changes instantly!
```

---

## 🎨 UI/UX Guidelines

### Material Design 3

```dart
// Use Material 3 components
import 'package:flutter/material.dart';

// Theme
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
)

// Components
FilledButton(...)        // Primary actions
OutlinedButton(...)      // Secondary actions
Card(...)                // Content containers
ListTile(...)            // List items
```

### Consistent Spacing

```dart
// Use SizedBox for spacing
Column(
  children: [
    Text('Title'),
    SizedBox(height: 16),  // Consistent spacing
    Text('Subtitle'),
    SizedBox(height: 8),
    Text('Details'),
  ],
)

// Standard spacing values
const kSpacingSmall = 8.0;
const kSpacingMedium = 16.0;
const kSpacingLarge = 24.0;
```

### Loading States

```dart
if (_isLoading) {
  return Center(
    child: CircularProgressIndicator(),
  );
}

// Or inline
_isLoading
  ? CircularProgressIndicator()
  : ElevatedButton(...)
```

### Error Display

```dart
if (_error != null) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red),
        SizedBox(height: 16),
        Text(_error!),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _retry,
          child: Text('Retry'),
        ),
      ],
    ),
  );
}
```

---

## 🔍 Code Review Checklist

Before submitting PR:

**Functionality:**
- [ ] Feature works as expected
- [ ] No console errors
- [ ] Handles loading states
- [ ] Handles error states
- [ ] Forms validate correctly

**Code Quality:**
- [ ] No hardcoded strings (use const)
- [ ] Proper null safety
- [ ] Dispose controllers in dispose()
- [ ] Meaningful variable names
- [ ] Comments for complex logic

**UI/UX:**
- [ ] Follows Material Design guidelines
- [ ] Responsive layout
- [ ] Loading indicators shown
- [ ] Error messages user-friendly
- [ ] Navigation flows correctly

**Testing:**
- [ ] Tested on macOS
- [ ] Hot reload works
- [ ] No breaking changes to other modules

---

## 📚 Resources

### Flutter Widgets Catalog
https://docs.flutter.dev/ui/widgets

### Material Design 3
https://m3.material.io/

### Dart Documentation
https://dart.dev/guides

---

## 🤝 Getting Help

**Before asking:**
1. Check this documentation
2. Search Flutter docs
3. Check existing similar screens

**When asking:**
1. Describe what you're trying to do
2. Show your code
3. Explain what's not working
4. Include error messages

**Team Communication:**
- Daily standup: Blockers, progress
- Code review: Tag relevant team
- Slack: Quick questions
- GitHub Issues: Bugs, features

---

**Next:** See [Team Workflow](../05-team/team-workflow.md) for collaboration practices.
