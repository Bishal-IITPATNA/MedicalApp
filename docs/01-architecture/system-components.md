# System Components - Detailed Breakdown

This document explains each component of the Medical App in simple terms. Think of each component as a Lego block that fits together to build the complete system.

## 🎯 Component Overview Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│                         (What Users See)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ Patient  │ │ Doctor   │ │ Nurse    │ │  Store   │          │
│  │Dashboard │ │Dashboard │ │Dashboard │ │Dashboard │          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │   Auth   │ │ Profile  │ │ Booking  │ │Analytics │          │
│  │ Screens  │ │ Screens  │ │ Screens  │ │ Screens  │          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        SERVICE LAYER                             │
│                    (Communication Logic)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────┐    ┌──────────────────────┐          │
│  │   API Service        │    │   Auth Service       │          │
│  │  - HTTP requests     │    │  - Token management  │          │
│  │  - Response parsing  │    │  - Login/Logout      │          │
│  └──────────────────────┘    └──────────────────────┘          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        API GATEWAY LAYER                         │
│                      (Route Management)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │
│  │  Auth  │ │Patient │ │ Doctor │ │ Store  │ │ Admin  │       │
│  │ Routes │ │ Routes │ │ Routes │ │ Routes │ │ Routes │       │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        BUSINESS LOGIC LAYER                      │
│                   (Application Rules & Logic)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  - Appointment booking logic                                    │
│  - Order processing logic                                       │
│  - Prescription validation                                      │
│  - Payment processing                                           │
│  - Notification triggering                                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        DATA ACCESS LAYER                         │
│                      (Database Operations)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │
│  │  User  │ │Appoint │ │Medicine│ │LabTest │ │Notific │       │
│  │ Models │ │ Models │ │ Models │ │ Models │ │ Models │       │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        DATABASE LAYER                            │
│                      (Data Persistence)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                        SQLite / PostgreSQL                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 📱 Frontend Components (Flutter)

### 1. Screens (Presentation Layer)

**What They Do**: Show information to users and capture user input

#### Authentication Screens
- **Location**: `frontend/lib/screens/auth/`
- **Purpose**: Handle user login, registration, and password management
- **Components**:
  - `login_screen.dart`: Email/password login form with forgot password link
  - `register_screen.dart`: New user registration with role selection
  - `forgot_password_screen.dart`: Request password reset token
  - `reset_password_screen.dart`: Reset password using token

**Example Flow**:
```dart
User enters email → User enters password → Clicks Login 
→ auth_service validates → Redirects to dashboard
```

#### Patient Screens
- **Location**: `frontend/lib/screens/patient/`
- **Purpose**: All patient-related functionality
- **Key Screens**:
  - `patient_dashboard.dart`: Home screen with appointments, medicines, lab tests
  - `find_doctor_screen.dart`: Search and browse doctors
  - `book_lab_test_screen.dart`: Browse and book lab tests
  - `buy_medicine_screen.dart`: Medicine shopping cart
  - `appointment_detail_screen.dart`: View appointment details and prescriptions

**Responsibilities**:
- Display data from backend
- Handle user interactions
- Navigate between screens
- Show loading and error states

#### Doctor Screens
- **Location**: `frontend/lib/screens/doctor/`
- **Components**:
  - `doctor_dashboard.dart`: View appointments, manage schedule
  - `doctor_profile_screen.dart`: Manage multiple chambers (practice locations)
  - `patient_detail_screen.dart`: View patient info, write prescriptions

**Special Feature**: Multiple Chambers
- Doctors can add multiple practice locations
- Each chamber has its own address, fees, schedule
- Stored as JSON and sent to backend

#### Store Screens (Medical & Lab)
- **Location**: `frontend/lib/screens/medical_store/` and `lab_store/`
- **Components**:
  - `*_dashboard.dart`: Overview with statistics
  - `order_medicines_screen.dart` / `manage_tests_screen.dart`: Inventory management
  - `analytics_screen.dart`: Sales and performance metrics

**Key Features**:
- Real-time order management
- Inventory tracking
- Analytics dashboards with charts

### 2. Services (Communication Layer)

**What They Do**: Connect the app to the backend server

#### API Service
- **File**: `frontend/lib/services/api_service.dart`
- **Purpose**: Send HTTP requests to backend

**Key Methods**:
```dart
class ApiService {
  Future<Map<String, dynamic>> get(String url)     // Fetch data
  Future<Map<String, dynamic>> post(String url, Map data)  // Send data
  Future<Map<String, dynamic>> put(String url, Map data)   // Update data
  Future<Map<String, dynamic>> delete(String url)  // Delete data
}
```

**How It Works**:
1. Screen needs data (e.g., list of doctors)
2. Calls `apiService.get('/api/doctor/search')`
3. API service adds authentication token
4. Sends HTTP request to backend
5. Receives JSON response
6. Returns data to screen

**Error Handling**:
- Catches network errors
- Handles 401 (unauthorized) by refreshing token
- Returns error messages to screen

#### Auth Service
- **File**: `frontend/lib/services/auth_service.dart`
- **Purpose**: Manage user authentication

**Key Methods**:
```dart
class AuthService {
  Future<bool> login(email, password)      // Login user
  Future<bool> register(userData)          // Register new user
  Future<String> getAccessToken()          // Get stored token
  Future<bool> refreshAccessToken()        // Renew expired token
  Future<void> logout()                    // Clear stored data
}
```

**Token Management**:
- Stores tokens securely using FlutterSecureStorage
- Automatically refreshes expired tokens
- Clears tokens on logout

### 3. Models (Data Structures)

**What They Do**: Define the shape of data

- **Location**: `frontend/lib/models/`
- **Purpose**: Convert JSON to Dart objects

**Example**:
```dart
class User {
  final int id;
  final String email;
  final String role;
  
  User({this.id, this.email, this.role});
  
  // Convert JSON to User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
    );
  }
}
```

**Why Models?**
- Type safety (catch errors at compile time)
- Auto-completion in IDE
- Easy to work with structured data

## 🔧 Backend Components (Flask)

### 1. Routes (API Gateway)

**What They Do**: Define API endpoints and handle HTTP requests

#### Structure
```
backend/app/routes/
├── auth.py              # Login, register, token refresh
├── patient.py           # Patient-specific endpoints
├── doctor.py            # Doctor-specific endpoints
├── nurse.py             # Nurse-specific endpoints
├── medical_store.py     # Medical store endpoints
├── lab_store.py         # Lab store endpoints
├── admin.py             # Admin endpoints
├── appointments.py      # Appointment booking
├── notifications.py     # Notification management
├── payments.py          # Payment processing
├── prescriptions.py     # Prescription management
├── patient_history.py   # Medical history
└── doctor_lab_tests.py  # Lab test ordering
```

#### How Routes Work

**Example**: `auth.py`
```python
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token

# Create blueprint (like a mini-app)
bp = Blueprint('auth', __name__, url_prefix='/api/auth')

# Define endpoint
@bp.route('/login', methods=['POST'])
def login():
    # 1. Get data from request
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    # 2. Find user in database
    user = User.query.filter_by(email=email).first()
    
    # 3. Check password
    if user and user.check_password(password):
        # 4. Create token
        token = create_access_token(identity=user.id)
        
        # 5. Return response
        return jsonify({
            'access_token': token,
            'user': user.to_dict()
        }), 200
    
    # 6. Return error if failed
    return jsonify({'error': 'Invalid credentials'}), 401

# Password management endpoints
@bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """Change password while logged in"""
    user_id = get_jwt_identity()
    data = request.get_json()
    # Verify current password, update to new password
    # Send security notification
    return jsonify({'success': True})

@bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    """Request password reset token"""
    data = request.get_json()
    # Generate reset token, send to user notifications
    return jsonify({'success': True, 'token': reset_token})

@bp.route('/reset-password', methods=['POST'])
def reset_password():
    """Reset password with token"""
    data = request.get_json()
    # Verify token, update password
    return jsonify({'success': True})
```

**Blueprint Pattern Benefits**:
- Organize routes by feature
- Easy to test independently
- Clear separation of concerns

### 2. Models (Data Access Layer)

**What They Do**: Define database tables and handle data operations

#### User Models (`app/models/user.py`)

```python
class User(db.Model):
    """Main user table - stores credentials"""
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True)
    password_hash = db.Column(db.String(255))
    role = db.Column(db.Enum('patient', 'doctor', ...))
    reset_token = db.Column(db.String(100), nullable=True)
    reset_token_expiry = db.Column(db.DateTime, nullable=True)
    
    def check_password(self, password):
        """Verify password against hash"""
        return check_password_hash(self.password_hash, password)
    
    def generate_reset_token(self):
        """Generate secure password reset token"""
        self.reset_token = secrets.token_urlsafe(32)
        self.reset_token_expiry = datetime.utcnow() + timedelta(hours=1)
        return self.reset_token
    
    def verify_reset_token(self, token):
        """Verify reset token is valid and not expired"""
        return (self.reset_token == token and 
                datetime.utcnow() < self.reset_token_expiry)

class Patient(db.Model):
    """Patient profile - extends User"""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    name = db.Column(db.String(100))
    phone = db.Column(db.String(15))
    blood_group = db.Column(db.String(5))
    
    # Relationship
    user = db.relationship('User', backref='patient')
```

**Key Concepts**:
- **Column**: Database field
- **ForeignKey**: Links to another table
- **relationship**: Easy access to related data
- **backref**: Reverse relationship

#### Appointment Models (`app/models/appointment.py`)

```python
class Appointment(db.Model):
    """Stores appointment bookings"""
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patient.id'))
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctor.id'))
    appointment_date = db.Column(db.DateTime)
    status = db.Column(db.Enum('pending', 'confirmed', 'completed'))
    
    # Relationships
    patient = db.relationship('Patient', backref='appointments')
    doctor = db.relationship('Doctor', backref='appointments')
```

**CRUD Operations**:
```python
# Create
new_appointment = Appointment(
    patient_id=1,
    doctor_id=2,
    appointment_date=datetime.now()
)
db.session.add(new_appointment)
db.session.commit()

# Read
appointments = Appointment.query.filter_by(patient_id=1).all()

# Update
appointment.status = 'confirmed'
db.session.commit()

# Delete
db.session.delete(appointment)
db.session.commit()
```

### 3. Configuration (`config.py`)

**What It Does**: Stores application settings

```python
class Config:
    # Database connection
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL')
    
    # JWT settings
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    
    # Flask settings
    SECRET_KEY = os.getenv('SECRET_KEY')
```

**Environment Variables** (`.env` file):
```
DATABASE_URL=sqlite:///medical_app.db
JWT_SECRET_KEY=your-secret-key-here
SECRET_KEY=your-flask-secret-here
FLASK_ENV=development
```

### 4. Application Factory (`app/__init__.py`)

**What It Does**: Creates and configures the Flask application

```python
def create_app(config_class=Config):
    # 1. Create Flask app
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    # 2. Initialize extensions
    db.init_app(app)           # Database
    migrate.init_app(app, db)  # Migrations
    jwt.init_app(app)          # Authentication
    CORS(app)                  # Cross-origin requests
    
    # 3. Register blueprints
    app.register_blueprint(auth.bp)
    app.register_blueprint(patient.bp)
    app.register_blueprint(doctor.bp)
    # ... more blueprints
    
    return app
```

**Why Factory Pattern?**
- Can create multiple app instances for testing
- Clean initialization
- Easy to configure

## 🔄 Component Interactions

### Example: Patient Books Appointment

```
1. PATIENT SCREEN
   ├─> User clicks "Book Appointment"
   └─> Calls BookingScreen
   
2. BOOKING SCREEN
   ├─> Shows date picker
   ├─> User selects date/time
   └─> Calls apiService.post('/api/patient/appointments', data)
   
3. API SERVICE
   ├─> Adds authentication header
   ├─> Sends POST request to backend
   └─> Waits for response
   
4. BACKEND - Route Handler (appointments.py)
   ├─> Receives request
   ├─> Validates JWT token
   ├─> Checks if doctor is available
   └─> Calls Appointment.create(data)
   
5. BACKEND - Model (appointment.py)
   ├─> Creates Appointment object
   ├─> Saves to database
   ├─> Creates Notification
   └─> Returns appointment ID
   
6. DATABASE
   ├─> INSERT INTO appointments ...
   └─> Returns success
   
7. BACKEND - Response
   ├─> Formats JSON response
   └─> Sends back to frontend
   
8. API SERVICE
   ├─> Receives response
   └─> Returns to BookingScreen
   
9. BOOKING SCREEN
   ├─> Shows success message
   └─> Navigates to AppointmentDetailScreen
```

## 📊 Component Dependency Graph

```
Frontend:
  Screens ──> Services ──> Backend API
     │           │
     └───> Models

Backend:
  Routes ──> Models ──> Database
     │
     └─> Business Logic
```

## 🎯 Component Ownership (for Teams)

### Team Assignment Example:

**Team A - Authentication & User Management**
- Frontend: `auth/` screens, `auth_service.dart`
- Backend: `routes/auth.py`, `models/user.py`

**Team B - Appointment System**
- Frontend: Booking screens, appointment list
- Backend: `routes/appointments.py`, `models/appointment.py`

**Team C - Medicine Ordering**
- Frontend: Medicine screens, cart, checkout
- Backend: `routes/patient.py` (orders), `models/medicine.py`

**Team D - Store Management**
- Frontend: Store dashboards, analytics
- Backend: `routes/medical_store.py`, `routes/lab_store.py`

See [Module Ownership](../05-team/module-ownership.md) for detailed assignments.

## 🔧 Adding a New Component

### Example: Add a "Favorites" Feature

**1. Frontend - Model**
```dart
// lib/models/favorite_model.dart
class Favorite {
  final int id;
  final int userId;
  final int doctorId;
  
  Favorite({this.id, this.userId, this.doctorId});
  
  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      userId: json['user_id'],
      doctorId: json['doctor_id'],
    );
  }
}
```

**2. Frontend - Service**
```dart
// Add to api_service.dart
Future<List<Favorite>> getFavorites() async {
  final response = await get('/api/patient/favorites');
  return (response['data'] as List)
      .map((json) => Favorite.fromJson(json))
      .toList();
}
```

**3. Frontend - Screen**
```dart
// lib/screens/patient/favorites_screen.dart
class FavoritesScreen extends StatefulWidget { ... }
```

**4. Backend - Model**
```python
# app/models/favorite.py
class Favorite(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctor.id'))
```

**5. Backend - Route**
```python
# app/routes/patient.py
@bp.route('/favorites', methods=['GET'])
@jwt_required()
def get_favorites():
    user_id = get_jwt_identity()
    favorites = Favorite.query.filter_by(user_id=user_id).all()
    return jsonify([f.to_dict() for f in favorites])
```

**6. Database Migration**
```bash
flask db migrate -m "Add favorites table"
flask db upgrade
```

## 📚 Summary

Each component has a specific job:
- **Screens**: Show UI, capture input
- **Services**: Communicate with backend
- **Models**: Structure data
- **Routes**: Handle API requests
- **Database Models**: Store data
- **Configuration**: Settings

Understanding these components helps you:
- Know where to add new features
- Debug issues faster
- Work independently on your assigned module
- Collaborate effectively with team

---

Next: Read [Data Flow](./data-flow.md) to see how these components work together!
