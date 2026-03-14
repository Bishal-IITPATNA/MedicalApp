# Data Flow - How Information Moves Through the System

This document explains how data travels from the user's screen to the database and back. Think of it as tracking a package through its delivery journey.

## 🚀 Quick Overview

```
User Action → Frontend → API Request → Backend → Database
                                                      ↓
User Sees Result ← Frontend ← API Response ← Backend ←
```

## 📱 Complete Data Flow Examples

### Example 1: User Logs In

**Step-by-Step Journey**:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USER ACTION                                              │
├─────────────────────────────────────────────────────────────┤
│ User opens app → Sees login screen                          │
│ Enters: email@example.com, password123                      │
│ Clicks "Login" button                                       │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. FRONTEND - LoginScreen (login_screen.dart)               │
├─────────────────────────────────────────────────────────────┤
│ Code:                                                        │
│   onPressed: () async {                                     │
│     final email = _emailController.text;                    │
│     final password = _passwordController.text;              │
│                                                             │
│     final success = await authService.login(                │
│       email,                                                │
│       password                                              │
│     );                                                      │
│   }                                                         │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. FRONTEND - AuthService (auth_service.dart)               │
├─────────────────────────────────────────────────────────────┤
│ Code:                                                        │
│   Future<bool> login(String email, String password) {       │
│     final response = await apiService.post(                 │
│       '/api/auth/login',                                    │
│       {'email': email, 'password': password}                │
│     );                                                      │
│   }                                                         │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. FRONTEND - ApiService (api_service.dart)                 │
├─────────────────────────────────────────────────────────────┤
│ Creates HTTP POST request:                                  │
│   URL: http://localhost:5000/api/auth/login                │
│   Headers: {'Content-Type': 'application/json'}            │
│   Body: {"email": "email@example.com",                      │
│          "password": "password123"}                         │
└─────────────────────────────────────────────────────────────┘
                        ↓
                   [NETWORK]
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. BACKEND - Flask Receives Request                         │
├─────────────────────────────────────────────────────────────┤
│ Request arrives at Flask server                             │
│ Flask routes to correct handler based on URL                │
│ /api/auth/login → routes/auth.py:login()                   │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. BACKEND - Route Handler (routes/auth.py)                 │
├─────────────────────────────────────────────────────────────┤
│ Code:                                                        │
│   @bp.route('/login', methods=['POST'])                     │
│   def login():                                              │
│     # Parse request                                         │
│     data = request.get_json()                               │
│     email = data.get('email')                               │
│     password = data.get('password')                         │
│                                                             │
│     # Query database                                        │
│     user = User.query.filter_by(email=email).first()        │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. BACKEND - Database Query (SQLAlchemy ORM)                │
├─────────────────────────────────────────────────────────────┤
│ SQL Generated:                                               │
│   SELECT * FROM user WHERE email = 'email@example.com'      │
│                                                             │
│ Returns User object:                                        │
│   User(id=1, email='email@example.com',                     │
│        password_hash='$2b$12$...', role='patient')          │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. BACKEND - Password Verification                          │
├─────────────────────────────────────────────────────────────┤
│ Code:                                                        │
│   if user and user.check_password(password):                │
│     # Password matches!                                     │
│     ...                                                     │
│                                                             │
│ check_password() uses bcrypt to verify:                     │
│   check_password_hash(stored_hash, entered_password)        │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 9. BACKEND - Token Generation (JWT)                         │
├─────────────────────────────────────────────────────────────┤
│ Code:                                                        │
│   access_token = create_access_token(                       │
│     identity=user.id,                                       │
│     additional_claims={                                     │
│       'email': user.email,                                  │
│       'role': user.role                                     │
│     }                                                       │
│   )                                                         │
│                                                             │
│ Token created:                                              │
│   "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."                 │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 10. BACKEND - Response Creation                             │
├─────────────────────────────────────────────────────────────┤
│ Code:                                                        │
│   return jsonify({                                          │
│     'success': True,                                        │
│     'access_token': access_token,                           │
│     'refresh_token': refresh_token,                         │
│     'user': user.to_dict()                                  │
│   }), 200                                                   │
│                                                             │
│ JSON Response:                                              │
│   {                                                         │
│     "success": true,                                        │
│     "access_token": "eyJhbGci...",                          │
│     "user": {"id": 1, "email": "...", "role": "patient"}    │
│   }                                                         │
└─────────────────────────────────────────────────────────────┘
                        ↓
                   [NETWORK]
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 11. FRONTEND - ApiService Receives Response                 │
├─────────────────────────────────────────────────────────────┤
│ Code:                                                        │
│   final response = await http.post(...);                    │
│   final data = json.decode(response.body);                  │
│   return data;                                              │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 12. FRONTEND - AuthService Stores Token                     │
├─────────────────────────────────────────────────────────────┤
│ Code:                                                        │
│   await _storage.write(                                     │
│     key: 'access_token',                                    │
│     value: response['access_token']                         │
│   );                                                        │
│   await _storage.write(                                     │
│     key: 'user_data',                                       │
│     value: json.encode(response['user'])                    │
│   );                                                        │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 13. FRONTEND - LoginScreen Handles Success                  │
├─────────────────────────────────────────────────────────────┤
│ Code:                                                        │
│   if (success) {                                            │
│     Navigator.pushReplacementNamed(                         │
│       context,                                              │
│       '/patient/dashboard'                                  │
│     );                                                      │
│   }                                                         │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 14. USER SEES RESULT                                        │
├─────────────────────────────────────────────────────────────┤
│ App navigates to Patient Dashboard                          │
│ User is now logged in!                                      │
└─────────────────────────────────────────────────────────────┘
```

### Example 2: Patient Books Appointment

**Data Transformations**:

```
┌──────────────────────────────────────────────────────────────┐
│ FRONTEND INPUT                                               │
├──────────────────────────────────────────────────────────────┤
│ User Interface:                                              │
│ - Doctor: Dr. John Smith                                     │
│ - Date: Dec 15, 2024                                         │
│ - Time: 10:00 AM                                             │
│ - Problem: Fever and headache                                │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ DART OBJECT (Frontend)                                       │
├──────────────────────────────────────────────────────────────┤
│ Map<String, dynamic> bookingData = {                         │
│   'doctor_id': 5,                                            │
│   'chamber_id': 2,                                           │
│   'appointment_date': '2024-12-15T10:00:00',                 │
│   'problem_description': 'Fever and headache'                │
│ };                                                           │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ HTTP REQUEST BODY (JSON String)                              │
├──────────────────────────────────────────────────────────────┤
│ {                                                            │
│   "doctor_id": 5,                                            │
│   "chamber_id": 2,                                           │
│   "appointment_date": "2024-12-15T10:00:00",                 │
│   "problem_description": "Fever and headache"                │
│ }                                                            │
└──────────────────────────────────────────────────────────────┘
                         ↓
                    [NETWORK]
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ PYTHON DICT (Backend)                                        │
├──────────────────────────────────────────────────────────────┤
│ data = {                                                     │
│   'doctor_id': 5,                                            │
│   'chamber_id': 2,                                           │
│   'appointment_date': '2024-12-15T10:00:00',                 │
│   'problem_description': 'Fever and headache'                │
│ }                                                            │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ PYTHON OBJECT (SQLAlchemy Model)                             │
├──────────────────────────────────────────────────────────────┤
│ appointment = Appointment(                                   │
│   patient_id=1,  # From JWT token                            │
│   doctor_id=5,                                               │
│   chamber_id=2,                                              │
│   appointment_date=datetime(2024, 12, 15, 10, 0),            │
│   problem_description='Fever and headache',                  │
│   status='pending',                                          │
│   created_at=datetime.now()                                  │
│ )                                                            │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ SQL STATEMENT                                                │
├──────────────────────────────────────────────────────────────┤
│ INSERT INTO appointment                                      │
│   (patient_id, doctor_id, chamber_id, appointment_date,      │
│    problem_description, status, created_at)                  │
│ VALUES                                                       │
│   (1, 5, 2, '2024-12-15 10:00:00',                          │
│    'Fever and headache', 'pending', '2024-12-10 14:30:00')  │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ DATABASE RECORD                                              │
├──────────────────────────────────────────────────────────────┤
│ Table: appointment                                           │
│ ┌────┬────────────┬───────────┬────────────┬─────────────┐  │
│ │ id │ patient_id │ doctor_id │ chamber_id │ app_date    │  │
│ ├────┼────────────┼───────────┼────────────┼─────────────┤  │
│ │ 15 │     1      │     5     │     2      │ 2024-12-15  │  │
│ └────┴────────────┴───────────┴────────────┴─────────────┘  │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ RESPONSE - PYTHON OBJECT TO DICT                             │
├──────────────────────────────────────────────────────────────┤
│ response_data = {                                            │
│   'success': True,                                           │
│   'message': 'Appointment booked successfully',              │
│   'appointment': {                                           │
│     'id': 15,                                                │
│     'doctor_name': 'Dr. John Smith',                         │
│     'appointment_date': '2024-12-15T10:00:00',               │
│     'status': 'pending'                                      │
│   }                                                          │
│ }                                                            │
└──────────────────────────────────────────────────────────────┘
                         ↓
                    [NETWORK]
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ DART OBJECT (Frontend)                                       │
├──────────────────────────────────────────────────────────────┤
│ Appointment appointment = Appointment.fromJson(              │
│   response['data']['appointment']                            │
│ );                                                           │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ UI UPDATE                                                    │
├──────────────────────────────────────────────────────────────┤
│ Shows success message:                                       │
│ "✓ Appointment booked with Dr. John Smith on Dec 15"        │
│                                                              │
│ Navigates to appointment details screen                      │
└──────────────────────────────────────────────────────────────┘
```

## 🔐 Authenticated Requests

**How Authentication Token Flows**:

```
┌────────────────────────────────────────────────────────────┐
│ 1. User Previously Logged In                               │
├────────────────────────────────────────────────────────────┤
│ Token stored in FlutterSecureStorage:                      │
│ access_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."    │
└────────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────────┐
│ 2. User Makes Request (e.g., Get Appointments)             │
├────────────────────────────────────────────────────────────┤
│ Code:                                                       │
│   apiService.get('/api/patient/appointments')              │
└────────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────────┐
│ 3. ApiService Adds Token to Request                        │
├────────────────────────────────────────────────────────────┤
│ Code:                                                       │
│   final token = await authService.getAccessToken();        │
│   headers = {                                              │
│     'Authorization': 'Bearer $token',                      │
│     'Content-Type': 'application/json'                     │
│   };                                                       │
└────────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────────┐
│ 4. HTTP Request with Token                                 │
├────────────────────────────────────────────────────────────┤
│ GET /api/patient/appointments                              │
│ Headers:                                                   │
│   Authorization: Bearer eyJhbGci...                        │
│   Content-Type: application/json                           │
└────────────────────────────────────────────────────────────┘
                        ↓
                   [NETWORK]
                        ↓
┌────────────────────────────────────────────────────────────┐
│ 5. Backend Receives Request                                │
├────────────────────────────────────────────────────────────┤
│ Route decorator:                                           │
│   @bp.route('/appointments')                               │
│   @jwt_required()  # <-- Checks token                      │
│   def get_appointments():                                  │
│     ...                                                    │
└────────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────────┐
│ 6. Token Validation (Flask-JWT-Extended)                   │
├────────────────────────────────────────────────────────────┤
│ Steps:                                                     │
│ 1. Extract token from Authorization header                │
│ 2. Decode JWT using secret key                            │
│ 3. Check expiration time                                  │
│ 4. Verify signature                                       │
│ 5. Extract user ID from token payload                     │
│                                                            │
│ Token payload:                                             │
│ {                                                          │
│   "sub": 1,        # user_id                              │
│   "email": "user@example.com",                            │
│   "role": "patient",                                      │
│   "exp": 1702500000  # expiration timestamp               │
│ }                                                          │
└────────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────────┐
│ 7. Get User ID from Token                                  │
├────────────────────────────────────────────────────────────┤
│ Code:                                                       │
│   user_id = get_jwt_identity()  # Returns 1                │
│   patient = Patient.query.filter_by(user_id=user_id).first│
└────────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────────┐
│ 8. Fetch User-Specific Data                                │
├────────────────────────────────────────────────────────────┤
│ SQL:                                                        │
│   SELECT * FROM appointment                                 │
│   WHERE patient_id = 1                                      │
│   ORDER BY appointment_date DESC                            │
└────────────────────────────────────────────────────────────┘
```

## 📊 Complex Data Flow: Medicine Purchase with Prescription

**Multi-Step Process**:

```
Step 1: View Prescribed Medicines
──────────────────────────────────
User → PatientDashboard → View Prescriptions
     → Shows medicines with "Buy" button

Step 2: Add to Cart (Automatic)
────────────────────────────────
User clicks "Buy Prescribed Medicine"
  ↓
Frontend checks: medicine.requires_prescription == true
  ↓
Frontend verifies: user has valid prescription
  ↓
Auto-add to cart (no manual add needed)
  ↓
Navigate to cart

Step 3: Checkout
─────────────────
User reviews cart
  ↓
Enters delivery address
  ↓
Clicks "Place Order"
  ↓
POST /api/patient/medicine-orders
  ↓
Backend validation:
  - Check prescription exists
  - Check medicine availability
  - Calculate total price
  ↓
Create MedicineOrder record
Create OrderItem records for each medicine
  ↓
Route order to admin (not store)
  ↓
Create notification for admin
  ↓
Return order confirmation

Step 4: Order Tracking
──────────────────────
User → Medicine Tab → View Orders
  ↓
GET /api/patient/medicine-orders
  ↓
Backend fetches orders with items
  ↓
Shows order status: pending/confirmed/delivered
```

**Data Structures at Each Step**:

```python
# Prescription
{
  'id': 10,
  'patient_id': 1,
  'doctor_id': 5,
  'medicines': [
    {
      'medicine_id': 20,
      'medicine_name': 'Amoxicillin 500mg',
      'dosage': '1 tablet twice daily',
      'duration': '7 days'
    }
  ]
}

# Cart Item
{
  'medicine_id': 20,
  'medicine_name': 'Amoxicillin 500mg',
  'quantity': 14,  # 2 per day * 7 days
  'price': 10.50,
  'has_prescription': True,
  'prescription_id': 10
}

# Medicine Order
{
  'id': 55,
  'patient_id': 1,
  'order_date': '2024-12-10',
  'total_amount': 147.00,
  'delivery_address': '123 Main St',
  'status': 'pending',
  'routed_to': 'admin',  # Not store
  'items': [
    {
      'medicine_id': 20,
      'quantity': 14,
      'price': 10.50,
      'subtotal': 147.00
    }
  ]
}
```

## 🔄 Real-time Data Updates

**Polling Pattern (Current Implementation)**:

```
Frontend Screen (e.g., Doctor Dashboard)
   ↓
initState() or timer
   ↓
Every 30 seconds:
   GET /api/doctor/appointments?status=pending
   ↓
Backend returns latest data
   ↓
Frontend updates UI
   ↓
User sees new appointments without refresh
```

**Example Code**:

```dart
// Frontend
@override
void initState() {
  super.initState();
  _loadAppointments();
  
  // Poll every 30 seconds
  Timer.periodic(Duration(seconds: 30), (timer) {
    _loadAppointments();
  });
}

Future<void> _loadAppointments() async {
  final response = await apiService.get('/api/doctor/appointments');
  setState(() {
    appointments = response['data'];
  });
}
```

## 🎯 Error Handling Flow

**What Happens When Things Go Wrong**:

```
┌────────────────────────────────────────────────────────────┐
│ ERROR SCENARIO 1: Network Failure                          │
├────────────────────────────────────────────────────────────┤
│ User makes request → Network unavailable                   │
│                                                            │
│ ApiService catches exception:                              │
│   try {                                                    │
│     final response = await http.post(...);                 │
│   } catch (e) {                                            │
│     return {'success': false, 'error': 'Network error'};   │
│   }                                                        │
│                                                            │
│ Screen shows error message:                                │
│   "Unable to connect. Please check internet connection."   │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ ERROR SCENARIO 2: Invalid Token (401)                      │
├────────────────────────────────────────────────────────────┤
│ User makes request → Token expired                         │
│                                                            │
│ Backend returns 401 Unauthorized                           │
│                                                            │
│ ApiService detects 401:                                    │
│   if (response.statusCode == 401) {                        │
│     await authService.refreshAccessToken();                │
│     // Retry original request                             │
│   }                                                        │
│                                                            │
│ If refresh fails → Logout user                             │
│   Navigator.pushReplacementNamed('/login');                │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ ERROR SCENARIO 3: Validation Error (400)                   │
├────────────────────────────────────────────────────────────┤
│ User submits form with invalid data                        │
│                                                            │
│ Backend validates:                                         │
│   if not data.get('email'):                                │
│     return jsonify({'error': 'Email required'}), 400       │
│                                                            │
│ Frontend receives error:                                   │
│   response = {'success': false, 'error': 'Email required'} │
│                                                            │
│ Screen shows error:                                        │
│   ScaffoldMessenger.of(context).showSnackBar(              │
│     SnackBar(content: Text(response['error']))             │
│   );                                                       │
└────────────────────────────────────────────────────────────┘
```

## 📝 Summary

Key Takeaways:

1. **Data flows in a loop**: User → Frontend → Backend → Database → Backend → Frontend → User

2. **Data transforms at each layer**:
   - Frontend: Dart objects
   - HTTP: JSON strings
   - Backend: Python dicts → SQLAlchemy models
   - Database: SQL records

3. **Authentication adds an extra layer**:
   - Token stored after login
   - Token sent with every request
   - Backend validates token
   - User ID extracted from token

4. **Errors are handled at each layer**:
   - Network errors caught in ApiService
   - Auth errors trigger re-login
   - Validation errors shown to user

5. **Some flows are complex**:
   - Multi-step processes (prescription → cart → order)
   - Real-time updates (polling)
   - Data aggregation (dashboard stats)

Understanding these flows helps you:
- Debug issues faster (know where data breaks)
- Add new features (follow existing patterns)
- Optimize performance (identify bottlenecks)

---

Next: Explore [Backend Development Guide](../02-backend/backend-setup.md)!
