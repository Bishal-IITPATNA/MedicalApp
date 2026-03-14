# Frontend Screens Guide

Comprehensive guide to all UI screens in the Medical App.

## 📱 Screen Architecture

```
App Entry
    ↓
┌─────────────┐
│ main.dart   │ → MaterialApp with routes
└─────────────┘
    ↓
┌──────────────────────────────────────────────────┐
│          Role-Based Dashboard Routing            │
├──────────────────────────────────────────────────┤
│  Patient → PatientDashboard                      │
│  Doctor  → DoctorDashboard                       │
│  Nurse   → NurseDashboard                        │
│  Store   → MedicalStoreDashboard / LabStoreDashboard │
│  Admin   → AdminDashboard                        │
└──────────────────────────────────────────────────┘
```

## 🔐 Authentication Screens

### LoginScreen

**Location:** `lib/screens/auth/login_screen.dart`

**Purpose:** User authentication entry point

**UI Components:**
- Email TextField
- Password TextField (obscured)
- "Forgot Password?" link → ForgotPasswordScreen
- Login Button
- "Don't have account?" → Register link

**Code Structure:**
```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    final success = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (success) {
      // Get user role and navigate to appropriate dashboard
      final userData = await _authService.getUserData();
      _navigateByRole(userData['role']);
    } else {
      _showError('Invalid credentials');
    }
  }
}
```

**Navigation Flow:**
```
LoginScreen
    ↓ (successful login)
    ├─> PatientDashboard (if role='patient')
    ├─> DoctorDashboard (if role='doctor')
    ├─> MedicalStoreDashboard (if role='medical_store')
    └─> ... (other roles)
```

### RegisterScreen

**Location:** `lib/screens/auth/register_screen.dart`

**Purpose:** New user registration

**Form Fields:**
- Email
- Password
- Confirm Password
- Role Selection (Dropdown)
- Name
- Phone
- Date of Birth (DatePicker)
- Gender (Radio buttons)
- Blood Group (Dropdown)

**Validation:**
```dart
String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Invalid email format';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
}
```

### ForgotPasswordScreen

**Location:** `lib/screens/auth/forgot_password_screen.dart`

**Purpose:** Request password reset token

**UI Components:**
- Email TextField
- "Send Reset Token" Button
- Back to Login link

**Flow:**
```dart
Future<void> _requestPasswordReset() async {
  final response = await _authService.forgotPassword(
    _emailController.text.trim(),
  );

  if (response['success']) {
    // Show token in dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Password Reset Token'),
        content: Column(
          children: [
            Text('Your reset token:'),
            SelectableText(response['data']['token']),
            Text('Copy this token and use it to reset your password.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(
                context,
                '/reset-password',
                arguments: _emailController.text.trim(),
              );
            },
            child: Text('Continue to Reset Password'),
          ),
        ],
      ),
    );
  }
}
```

### ResetPasswordScreen

**Location:** `lib/screens/auth/reset_password_screen.dart`

**Purpose:** Reset password using token

**UI Components:**
- Email TextField (pre-filled from navigation args)
- Reset Token TextField
- New Password TextField (obscured)
- Confirm Password TextField (obscured)
- "Reset Password" Button
- Back to Login link

**Validation:**
```dart
Future<void> _resetPassword() async {
  if (_passwordController.text != _confirmPasswordController.text) {
    _showError('Passwords do not match');
    return;
  }

  final response = await _authService.resetPassword(
    _emailController.text.trim(),
    _tokenController.text.trim(),
    _passwordController.text,
  );

  if (response['success']) {
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(
          'Your password has been reset successfully. '
          'You can now login with your new password.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: Text('Go to Login'),
          ),
        ],
      ),
    );
  }
}
```

## 👤 Patient Screens

### PatientDashboard

**Location:** `lib/screens/patient/patient_dashboard.dart`

**Layout:** BottomNavigationBar with 4 tabs

**Tabs:**
1. **Home** - Quick actions and stats
2. **Appointments** - Upcoming/past appointments
3. **Medicines** - Medicine orders history
4. **Lab Tests** - Lab test results

**Home Tab Components:**
```dart
Widget _buildHomeTab() {
  return SingleChildScrollView(
    child: Column(
      children: [
        _buildWelcomeCard(),        // "Welcome, John Doe"
        _buildQuickActions(),       // Find Doctor, Buy Medicine, etc.
        _buildUpcomingAppointments(), // Next 3 appointments
        _buildNotifications(),      // Recent notifications
      ],
    ),
  );
}
```

**Quick Actions:**
- Find Doctor → FindDoctorScreen
- Book Lab Test → BookLabTestScreen
- Buy Medicine → BuyMedicineScreen
- View Prescriptions → PrescriptionsScreen

### FindDoctorScreen

**Location:** `lib/screens/patient/find_doctor_screen.dart`

**Features:**
- Search bar (name, specialization)
- Filters (specialization, city, fee range)
- Doctor cards with:
  - Name, photo
  - Specialization
  - Experience
  - Consultation fee
  - "Book Appointment" button

**Code:**
```dart
class FindDoctorScreen extends StatefulWidget {
  @override
  _FindDoctorScreenState createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  List<Doctor> _doctors = [];
  String _searchQuery = '';
  String? _selectedSpecialization;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final response = await apiService.get('/api/doctor/search');
    setState(() {
      _doctors = (response['data'] as List)
          .map((json) => Doctor.fromJson(json))
          .toList();
    });
  }

  List<Doctor> get _filteredDoctors {
    return _doctors.where((doctor) {
      final matchesSearch = doctor.name
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesSpecialization = _selectedSpecialization == null ||
          doctor.specialization == _selectedSpecialization;
      return matchesSearch && matchesSpecialization;
    }).toList();
  }
}
```

### BookAppointmentScreen

**Location:** `lib/screens/patient/book_appointment_screen.dart`

**Purpose:** Book appointment with selected doctor

**Steps:**
1. Select chamber (if doctor has multiple)
2. Select date (DatePicker)
3. Select time slot (based on doctor's schedule)
4. Enter problem description
5. Confirm booking

**Time Slot Selection:**
```dart
Widget _buildTimeSlots() {
  return FutureBuilder<List<String>>(
    future: _getAvailableSlots(_selectedDate, _selectedChamber),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return CircularProgressIndicator();
      
      return Wrap(
        spacing: 10,
        children: snapshot.data!.map((time) {
          final isSelected = time == _selectedTime;
          return ChoiceChip(
            label: Text(time),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _selectedTime = time);
            },
          );
        }).toList(),
      );
    },
  );
}
```

### BuyMedicineScreen

**Location:** `lib/screens/patient/buy_medicine_screen.dart`

**Features:**
- Medicine search
- Medicine catalog with filters
- Shopping cart
- Prescription validation
- Checkout

**Special Logic - Prescription Required:**
```dart
void _addToCart(Medicine medicine) {
  if (medicine.requiresPrescription) {
    // Check if patient has valid prescription
    final hasPrescription = _checkPrescription(medicine.id);
    
    if (!hasPrescription) {
      _showDialog(
        'Prescription Required',
        'This medicine requires a prescription. '
        'Please consult a doctor first.',
      );
      return;
    }
  }
  
  setState(() {
    _cart.add(CartItem(
      medicine: medicine,
      quantity: 1,
      prescriptionId: hasPrescription ? _prescriptionId : null,
    ));
  });
}
```

**Auto-Add Prescribed Medicine:**
```dart
// From prescription screen
void _buyPrescribedMedicine(Prescription prescription) {
  final cart = <CartItem>[];
  
  for (var medicine in prescription.medicines) {
    cart.add(CartItem(
      medicineId: medicine.medicineId,
      medicineName: medicine.medicineName,
      quantity: _calculateQuantity(
        medicine.frequency,
        medicine.duration,
      ),
      prescriptionId: prescription.id,
      hasValidPrescription: true,
    ));
  }
  
  // Navigate to cart
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CartScreen(items: cart),
    ),
  );
}
```

## 👨‍⚕️ Doctor Screens

### DoctorDashboard

**Location:** `lib/screens/doctor/doctor_dashboard.dart`

**Layout:** BottomNavigationBar with 3 tabs

**Tabs:**
1. **Appointments** - Today's and upcoming appointments
2. **Patients** - Patient list and history
3. **Profile** - Doctor profile and chambers

**Appointments Tab:**
```dart
Widget _buildAppointmentsTab() {
  return Column(
    children: [
      _buildDateSelector(),      // Switch between dates
      _buildStatusFilter(),      // Pending/Confirmed/Completed
      Expanded(
        child: ListView.builder(
          itemCount: _appointments.length,
          itemBuilder: (context, index) {
            return _buildAppointmentCard(_appointments[index]);
          },
        ),
      ),
    ],
  );
}

Widget _buildAppointmentCard(Appointment appointment) {
  return Card(
    child: ListTile(
      leading: CircleAvatar(
        child: Text(appointment.patientName[0]),
      ),
      title: Text(appointment.patientName),
      subtitle: Text(appointment.problemDescription),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatTime(appointment.appointmentDate)),
          _buildStatusBadge(appointment.status),
        ],
      ),
      onTap: () => _viewAppointmentDetails(appointment),
    ),
  );
}
```

### PatientDetailScreen

**Location:** `lib/screens/doctor/patient_detail_screen.dart`

**Purpose:** View patient details and write prescription

**Sections:**
- Patient Info (name, age, blood group)
- Appointment Details
- Medical History
- Write Prescription Form
- Previous Prescriptions

**Prescription Form:**
```dart
class PrescriptionForm extends StatefulWidget {
  final Appointment appointment;
  
  @override
  _PrescriptionFormState createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends State<PrescriptionForm> {
  final _diagnosisController = TextEditingController();
  final _instructionsController = TextEditingController();
  List<PrescribedMedicine> _medicines = [];

  void _addMedicine() {
    setState(() {
      _medicines.add(PrescribedMedicine(
        medicineId: null,
        medicineName: '',
        dosage: '',
        frequency: '',
        duration: '',
        instructions: '',
      ));
    });
  }

  Widget _buildMedicineField(int index) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Medicine search/select
            _buildMedicineSearch(index),
            // Dosage, frequency, duration
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Dosage'),
                    onChanged: (value) => 
                        _medicines[index].dosage = value,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Frequency'),
                    onChanged: (value) => 
                        _medicines[index].frequency = value,
                  ),
                ),
              ],
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Duration'),
              onChanged: (value) => _medicines[index].duration = value,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPrescription() async {
    final response = await apiService.post(
      '/api/doctor/prescriptions',
      {
        'appointment_id': widget.appointment.id,
        'diagnosis': _diagnosisController.text,
        'medicines': _medicines.map((m) => m.toJson()).toList(),
        'instructions': _instructionsController.text,
      },
    );

    if (response['success']) {
      Navigator.pop(context);
      _showSuccess('Prescription created successfully');
    }
  }
}
```

### DoctorProfileScreen

**Location:** `lib/screens/doctor/doctor_profile_screen.dart`

**Features:**
- Edit profile
- Manage chambers (add/edit/delete)
- Set schedules for each chamber
- View statistics

**Chambers Management:**
```dart
class ChambersSection extends StatelessWidget {
  final List<Chamber> chambers;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...chambers.map((chamber) => ChamberCard(chamber)),
        ElevatedButton.icon(
          icon: Icon(Icons.add),
          label: Text('Add Chamber'),
          onPressed: () => _showAddChamberDialog(context),
        ),
      ],
    );
  }
}

Future<void> _showAddChamberDialog(BuildContext context) async {
  // Show dialog with form to add chamber
  final result = await showDialog<Chamber>(
    context: context,
    builder: (context) => AddChamberDialog(),
  );
  
  if (result != null) {
    await apiService.post('/api/doctor/chambers', result.toJson());
    _refreshChambers();
  }
}
```

## 🏪 Store Screens

### MedicalStoreDashboard

**Location:** `lib/screens/medical_store/medical_store_dashboard.dart`

**Tabs:**
1. **Dashboard** - Stats and overview
2. **Medicines** - Inventory management
3. **Orders** - Order processing

**Dashboard Tab:**
```dart
Widget _buildDashboardTab() {
  return FutureBuilder<Map<String, dynamic>>(
    future: apiService.get('/api/medical-store/dashboard'),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return CircularProgressIndicator();
      
      final stats = snapshot.data!['data'];
      
      return GridView.count(
        crossAxisCount: 2,
        children: [
          _buildStatCard(
            'Total Medicines',
            stats['total_medicines'].toString(),
            Icons.medication,
            Colors.blue,
          ),
          _buildStatCard(
            'Total Orders',
            stats['total_orders'].toString(),
            Icons.shopping_cart,
            Colors.green,
          ),
          _buildStatCard(
            'Revenue',
            '\$${stats['total_revenue']}',
            Icons.attach_money,
            Colors.purple,
          ),
          _buildStatCard(
            'Low Stock',
            stats['low_stock_items'].toString(),
            Icons.warning,
            Colors.red,
          ),
        ],
      );
    },
  );
}
```

### LabStoreDashboard

**Location:** `lib/screens/lab_store/lab_store_dashboard.dart`

**Similar structure to Medical Store:**
- Dashboard with test statistics
- Tests management
- Orders processing
- Profile/Settings in top-right menu

**Top-Right Menu:**
```dart
AppBar(
  title: Text('Lab Dashboard'),
  actions: [
    if (_currentIndex == 0) // Dashboard tab
      IconButton(
        icon: Icon(Icons.analytics),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LabStoreAnalyticsScreen(),
          ),
        ),
      ),
    PopupMenuButton<String>(
      icon: Icon(Icons.account_circle),
      onSelected: (value) {
        if (value == 'profile') {
          setState(() => _showProfile = true);
        } else if (value == 'settings') {
          setState(() => _showSettings = true);
        } else if (value == 'logout') {
          _handleLogout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'profile', child: Text('Profile')),
        PopupMenuItem(value: 'settings', child: Text('Settings')),
        PopupMenuItem(value: 'logout', child: Text('Logout')),
      ],
    ),
  ],
)
```

## 📊 Analytics Screens

### MedicalStoreAnalyticsScreen

**Location:** `lib/screens/medical_store/analytics_screen.dart`

**Sections:**
- Store Overview (total sales, orders, revenue)
- Inventory Analysis (stock levels, categories)
- Sales Trends (daily/weekly/monthly)
- Top Selling Medicines

### LabStoreAnalyticsScreen

**Location:** `lib/screens/lab_store/analytics_screen.dart`

**Sections:**
- Lab Overview (tests conducted, patients, revenue)
- Test Catalog Analysis
- Order Analysis by status
- Category Distribution

**Data Visualization:**
```dart
Widget _buildRevenueCard(Map<String, dynamic> stats) {
  return Card(
    child: Container,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Total Revenue',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '\$${stats['total_revenue'].toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
```

## 👨‍⚕️ Nurse Screens

### NurseDashboard

**Location:** `lib/screens/nurse/nurse_dashboard.dart`

**Layout:** BottomNavigationBar with 2 tabs

**Tabs:**
1. **Dashboard** - Overview and stats
2. **Appointments** - Assist doctors with appointments

**Dashboard Tab Features:**
- Welcome card with nurse name
- Quick stats (appointments today, patients seen)
- Upcoming appointments list
- Quick actions (View Appointments, Profile)

**Code Structure:**
```dart
class NurseDashboard extends StatefulWidget {
  @override
  _NurseDashboardState createState() => _NurseDashboardState();
}

class _NurseDashboardState extends State<NurseDashboard> {
  int _selectedIndex = 0;
  String _nurseName = '';

  Future<void> _loadUserData() async {
    final response = await _apiService.get('/api/auth/me');
    if (response['success']) {
      setState(() {
        _nurseName = response['data']['profile']['name'] ?? 'Nurse';
      });
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildWelcomeCard(),
          _buildQuickStats(),
          _buildUpcomingAppointments(),
        ],
      ),
    );
  }
}
```

**Appointments Tab:**
- View all appointments
- Filter by date, status, doctor
- Assist with patient check-in
- View appointment details
- Help with basic patient information

### NurseProfileScreen

**Location:** `lib/screens/nurse/nurse_profile_screen.dart`

**Features:**
- View and edit nurse profile
- Specialization/Department
- Contact information
- Shift schedule
- Performance metrics

## 👨‍💼 Admin Screens

### AdminDashboard

**Location:** `lib/screens/admin/admin_dashboard.dart`

**Layout:** TabController with 5 tabs

**Tabs:**
1. **Dashboard** - System overview
2. **Home Delivery Orders** - Medicine delivery management
3. **Store Orders** - Pharmacy orders routing
4. **Users Management** - User accounts
5. **Reports** - Analytics and reports

**Dashboard Tab:**
```dart
Widget _buildDashboardTab() {
  return FutureBuilder<Map<String, dynamic>>(
    future: _apiService.get('/api/admin/dashboard'),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return CircularProgressIndicator();
      
      final stats = snapshot.data!['data'];
      
      return GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          _buildStatCard(
            'Total Users',
            stats['total_users'].toString(),
            Icons.people,
            Colors.blue,
          ),
          _buildStatCard(
            'Active Doctors',
            stats['total_doctors'].toString(),
            Icons.medical_services,
            Colors.green,
          ),
          _buildStatCard(
            'Pending Orders',
            stats['pending_home_delivery_orders'].toString(),
            Icons.shopping_cart,
            Colors.orange,
          ),
          _buildStatCard(
            'Total Revenue',
            '\$${stats['total_revenue']}',
            Icons.attach_money,
            Colors.purple,
          ),
        ],
      );
    },
  );
}
```

**Home Delivery Orders Tab:**
- View all home delivery orders
- Filter by status (pending, assigned, delivered)
- Assign orders to delivery personnel
- Track order status
- View order details

**Store Orders Tab:**
- Medicine orders pending routing
- Assign orders to medical stores
- Track fulfillment status
- View order history

**Users Management Tab:**
- View all users by role
- Search and filter users
- View user details
- Activate/deactivate accounts
- Edit user information

**Reports Tab:**
- System-wide analytics
- Revenue reports
- User activity metrics
- Order statistics
- Export data functionality

### AdminProfileScreen

**Location:** `lib/screens/admin/admin_profile_screen.dart`

**Features:**
- Admin account details
- Change password
- System preferences
- Notification settings

### AdminSettingsScreen

**Location:** `lib/screens/admin/admin_settings_screen.dart`

**Features:**
- System configuration
- Email/SMS settings
- Payment gateway config
- Database backup/restore
- Application logs

## 📱 Profile Completion Screens

### PatientProfileCompletion

**Location:** `lib/screens/profile_completion/patient_profile_completion.dart`

**Purpose:** Complete patient profile after registration

**Form Fields:**
- Date of Birth (DatePicker)
- Gender (Radio buttons)
- Blood Group (Dropdown)
- Address, City, State, Pincode
- Emergency Contact

### DoctorProfileCompletion

**Location:** `lib/screens/profile_completion/doctor_profile_completion.dart`

**Purpose:** Complete doctor profile after registration

**Form Fields:**
- Specialization
- Qualification
- Experience (years)
- Registration Number
- Bio/About
- Consultation Fee
- City, State, Pincode

### NurseProfileCompletion

**Location:** `lib/screens/profile_completion/nurse_profile_completion.dart`

**Purpose:** Complete nurse profile after registration

**Form Fields:**
- Specialization/Department
- Qualification
- Experience (years)
- Registration Number
- City, State

### MedicalStoreProfileCompletion

**Location:** `lib/screens/profile_completion/medical_store_profile_completion.dart`

**Purpose:** Complete medical store profile after registration

**Form Fields:**
- Store Name
- License Number
- Address, City, State, Pincode
- Operating Hours
- Services Offered

### LabStoreProfileCompletion

**Location:** `lib/screens/profile_completion/lab_store_profile_completion.dart`

**Purpose:** Complete lab store profile after registration

**Form Fields:**
- Lab Name
- License Number
- Accreditation Details
- Address, City, State, Pincode
- Operating Hours
- Specializations (types of tests)

## 📊 Analytics Screens

### MedicalStoreAnalyticsScreen

**Location:** `lib/screens/medical_store/analytics_screen.dart`

**Sections:**
- Store Overview (total sales, orders, revenue)
- Inventory Analysis (stock levels, categories)
- Sales Trends (daily/weekly/monthly)
- Top Selling Medicines

### LabStoreAnalyticsScreen

**Location:** `lib/screens/lab_store/analytics_screen.dart`

**Sections:**
- Lab Overview (tests conducted, patients, revenue)
- Test Catalog Analysis
- Order Analysis by status
- Category Distribution

**Data Visualization:**
```dart
Widget _buildRevenueCard(Map<String, dynamic> stats) {
  return Card(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Total Revenue',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '\$${stats['total_revenue'].toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
```

## 🎯 Common UI Patterns

### Loading State

```dart
bool _isLoading = false;

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Center(child: CircularProgressIndicator());
  }
  
  return _buildContent();
}
```

### Error Handling

```dart
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: 'Dismiss',
        onPressed: () {},
      ),
    ),
  );
}
```

### Pull to Refresh

```dart
RefreshIndicator(
  onRefresh: _loadData,
  child: ListView.builder(...),
)
```

### Navigation

```dart
// Push new screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DetailScreen(data: data),
  ),
);

// Replace current screen
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => NewScreen()),
);

// Pop back
Navigator.pop(context);

// Named routes
Navigator.pushNamed(context, '/profile');
```

---

**Next:** Read [State Management Guide](./state-management.md) for data handling patterns.
