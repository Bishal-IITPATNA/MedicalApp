# System Architecture Overview

## What is This Application?

Seevak Care is a complete healthcare management system that connects:
- **Patients** who need medical care
- **Doctors & Nurses** who provide care
- **Medical Stores** that sell medicines
- **Lab Stores** that perform medical tests
- **Admins** who oversee everything

Think of it as a digital hospital where everything happens through an app!

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOBILE APP (Flutter)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Patient  │  │  Doctor  │  │  Store   │  │  Admin   │        │
│  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
│         ↓              ↓              ↓              ↓           │
│  ┌──────────────────────────────────────────────────────┐       │
│  │          API Service (HTTP Requests)                 │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              ↓ HTTPS
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND SERVER (Flask)                        │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              API Routes (Blueprints)                 │       │
│  │  • /auth  • /patient  • /doctor  • /store  • /admin │       │
│  └──────────────────────────────────────────────────────┘       │
│         ↓              ↓              ↓              ↓           │
│  ┌──────────────────────────────────────────────────────┐       │
│  │         Business Logic (Route Handlers)              │       │
│  └──────────────────────────────────────────────────────┘       │
│         ↓              ↓              ↓              ↓           │
│  ┌──────────────────────────────────────────────────────┐       │
│  │         Database Models (SQLAlchemy ORM)             │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    DATABASE (SQLite/PostgreSQL)                  │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐   │
│  │ Users  │  │Appoint │  │Medicine│  │LabTest │  │Payment │   │
│  │        │  │  ments │  │ Orders │  │ Orders │  │        │   │
│  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Architecture Pattern: Client-Server Model

### Why This Design?

**Separation of Concerns:**
- **Frontend (Flutter)**: Handles what users see and interact with
- **Backend (Flask)**: Handles business logic and data processing
- **Database**: Stores all the data permanently

**Benefits:**
1. **Scalability**: Can handle more users by adding more servers
2. **Security**: Sensitive logic stays on the server, not in the app
3. **Maintenance**: Can update backend without changing the app
4. **Cross-Platform**: Same backend works for iOS, Android, Web

## 📱 Frontend Architecture (Flutter)

```
lib/
├── main.dart                    # App starts here
├── screens/                     # What users see
│   ├── auth/                   # Login, Register
│   ├── patient/                # Patient's screens
│   ├── doctor/                 # Doctor's screens
│   └── ...
├── services/                    # How app talks to backend
│   ├── api_service.dart        # Sends HTTP requests
│   └── auth_service.dart       # Manages login tokens
├── models/                      # Data structures
│   ├── user_model.dart         # User information
│   └── appointment_model.dart  # Appointment data
└── utils/                       # Helper functions
    └── api_constants.dart      # Server URL
```

### How Frontend Works (Simple Explanation)

1. **User opens app** → `main.dart` runs
2. **User sees login screen** → Defined in `screens/auth/login_screen.dart`
3. **User enters credentials** → Data stored in form fields
4. **User clicks "Login"** → `auth_service.dart` sends request to backend
5. **Backend responds** → `api_service.dart` receives token
6. **Token saved** → Stored securely on device
7. **User redirected** → Goes to appropriate dashboard based on role

## 🔧 Backend Architecture (Flask)

```
backend/
├── run.py                       # Server starts here
├── app/
│   ├── __init__.py             # Creates Flask app
│   ├── models/                 # Database tables
│   │   ├── user.py            # User, Patient, Doctor tables
│   │   ├── appointment.py     # Appointment table
│   │   └── medicine.py        # Medicine, Order tables
│   └── routes/                 # API endpoints
│       ├── auth.py            # Login, Register APIs
│       ├── patient.py         # Patient APIs
│       └── doctor.py          # Doctor APIs
├── config.py                   # Settings (database URL, etc.)
└── migrations/                 # Database version control
```

### How Backend Works (Simple Explanation)

1. **Server starts** → `run.py` runs Flask app
2. **Flask app created** → `app/__init__.py` sets up routes
3. **Request arrives** → e.g., `POST /api/auth/login`
4. **Route handler found** → `routes/auth.py` has login function
5. **Business logic runs** → Checks password, creates token
6. **Database queried** → Using SQLAlchemy models
7. **Response sent back** → JSON with token or error

## 🔐 Security Architecture

### Authentication Flow

```
┌─────────────┐                           ┌─────────────┐
│   Mobile    │                           │   Backend   │
│     App     │                           │   Server    │
└─────────────┘                           └─────────────┘
      │                                          │
      │  1. POST /api/auth/login                │
      │     {email, password}                   │
      │─────────────────────────────────────────>│
      │                                          │
      │                              2. Check credentials
      │                              3. Generate JWT token
      │                                          │
      │  4. Response: {access_token, refresh_token}
      │<─────────────────────────────────────────│
      │                                          │
      │  5. Store tokens securely               │
      │                                          │
      │  6. GET /api/patient/profile            │
      │     Header: Authorization: Bearer <token>
      │─────────────────────────────────────────>│
      │                                          │
      │                              7. Verify token
      │                              8. Get user data
      │                                          │
      │  9. Response: {user data}               │
      │<─────────────────────────────────────────│
```

### Token-Based Authentication (JWT)

**What is JWT?**
- JWT = JSON Web Token
- Like a digital ID card
- Proves you are who you say you are

**How It Works:**
1. User logs in with email/password
2. Server creates a token (like a signed ticket)
3. App stores token
4. Every request includes token
5. Server verifies token before responding

## 💾 Database Architecture

### Entity Relationship Diagram

```
┌─────────────┐
│    User     │
│─────────────│
│ id (PK)     │───┐
│ email       │   │
│ password    │   │
│ role        │   │
└─────────────┘   │
                  │
       ┌──────────┴──────────┬──────────┬─────────┐
       ↓                     ↓          ↓         ↓
┌─────────────┐      ┌─────────────┐  ┌─────────────┐
│   Patient   │      │   Doctor    │  │MedicalStore │
│─────────────│      │─────────────│  │─────────────│
│ id (PK)     │      │ id (PK)     │  │ id (PK)     │
│ user_id(FK) │      │ user_id(FK) │  │ user_id(FK) │
│ name        │      │ name        │  │ name        │
│ phone       │      │ specialty   │  │ address     │
│ blood_group │      │ fee         │  └─────────────┘
└─────────────┘      └─────────────┘         │
       │                     │                │
       │            ┌────────┘                │
       │            ↓                         │
       │     ┌─────────────┐                 │
       │     │Appointment  │                 │
       │     │─────────────│                 │
       │     │ id (PK)     │                 │
       └────>│patient_id   │                 │
             │ doctor_id   │                 │
             │ date        │                 │
             │ status      │                 │
             └─────────────┘                 │
                                             │
       ┌─────────────────────────────────────┘
       ↓
┌─────────────┐         ┌─────────────────┐
│  Medicine   │         │ MedicineOrder   │
│─────────────│         │─────────────────│
│ id (PK)     │<────────│ id (PK)         │
│ store_id    │         │ patient_id (FK) │
│ name        │         │ store_id (FK)   │
│ price       │         │ total_amount    │
│ stock       │         │ status          │
└─────────────┘         └─────────────────┘
```

**Key Concepts:**
- **PK (Primary Key)**: Unique identifier for each record
- **FK (Foreign Key)**: Links to another table
- **One-to-Many**: One user can have one patient profile
- **Many-to-Many**: One patient can have many appointments

## 🔄 Data Flow Example: Booking an Appointment

Let's trace what happens when a patient books an appointment:

```
1. USER ACTION
   Patient opens "Find Doctor" screen
   
2. FRONTEND
   - FindDoctorScreen displays
   - Calls api_service.get('/api/doctor/search')
   
3. HTTP REQUEST
   GET https://localhost:5001/api/doctor/search?city=Mumbai
   Headers: Authorization: Bearer <token>
   
4. BACKEND RECEIVES
   - Flask routes request to routes/doctor.py
   - search_doctors() function executes
   
5. DATABASE QUERY
   - SQLAlchemy queries Doctor table
   - Filters by city = 'Mumbai'
   - Joins with User table for details
   
6. BACKEND RESPONDS
   {
     "success": true,
     "doctors": [
       {id: 1, name: "Dr. Smith", specialty: "Cardiology"},
       {id: 2, name: "Dr. Jones", specialty: "Neurology"}
     ]
   }
   
7. FRONTEND RECEIVES
   - api_service parses JSON
   - Converts to Doctor model objects
   - Updates UI with list
   
8. USER SELECTS DOCTOR
   Patient clicks "Book Appointment"
   
9. FRONTEND
   - Shows date/time picker
   - User selects slot
   - Calls api_service.post('/api/patient/appointments')
   
10. HTTP REQUEST
    POST https://localhost:5001/api/patient/appointments
    Body: {
      doctor_id: 1,
      date: "2025-11-25T10:00:00",
      type: "doctor"
    }
    
11. BACKEND
    - Routes to routes/appointments.py
    - Validates data
    - Creates Appointment record
    - Sends notification
    
12. DATABASE
    - INSERT INTO appointments (...)
    - Returns new appointment ID
    
13. BACKEND RESPONDS
    {
      "success": true,
      "appointment": {id: 123, status: "pending"}
    }
    
14. FRONTEND
    - Shows success message
    - Navigates to appointment details
```

## 🎨 Design Patterns Used

### 1. **MVC Pattern (Backend)**
- **Model**: Database models (`app/models/`)
- **View**: JSON responses
- **Controller**: Route handlers (`app/routes/`)

### 2. **Repository Pattern (Backend)**
- Models handle database operations
- Routes handle HTTP requests
- Clear separation of concerns

### 3. **Service Layer Pattern (Frontend)**
- `api_service.dart`: HTTP communication
- `auth_service.dart`: Authentication logic
- Screens just display data

### 4. **Blueprint Pattern (Backend)**
- Routes organized by feature
- Each blueprint is independent
- Easy to maintain and test

## 🚀 Scalability Considerations

### Current Setup (Development)
- Single server
- SQLite database
- Suitable for testing

### Production Setup (Future)
- Multiple servers behind load balancer
- PostgreSQL database (more robust)
- Redis for caching
- CDN for static files
- Separate database server

## 📊 Performance Optimization

### Backend
- Database indexing on frequently queried fields
- Query optimization with SQLAlchemy
- Lazy loading for relationships
- API response pagination

### Frontend
- Image caching
- Lazy loading of screens
- Efficient state management
- Minimal API calls

## 🔒 Security Measures

1. **Authentication**: JWT tokens with expiration
2. **Authorization**: Role-based access control
3. **Data Validation**: Input sanitization
4. **SQL Injection Protection**: ORM prevents direct SQL
5. **Password Security**: Hashed with Werkzeug
6. **HTTPS**: Encrypted communication (production)
7. **CORS**: Controlled cross-origin requests

## 📝 Technology Choices Explained

### Why Flask?
- Lightweight and flexible
- Easy to learn and use
- Great for REST APIs
- Large ecosystem

### Why Flutter?
- Single codebase for iOS, Android, Web, Desktop
- Beautiful Material Design UI
- Fast development
- Native performance

### Why SQLite (Dev)?
- No setup required
- File-based, portable
- Perfect for development

### Why PostgreSQL (Prod)?
- Production-ready
- Better performance
- Advanced features
- Reliable

## 🎯 Next Steps for New Developers

1. Read [System Components](./system-components.md) for detailed breakdown
2. Review [Data Flow](./data-flow.md) for common operations
3. Set up [Backend](../02-backend/setup-guide.md) locally
4. Set up [Frontend](../03-frontend/setup-guide.md) locally
5. Check [Module Ownership](../05-team/module-ownership.md) for your area

---

**Remember**: Architecture is like a blueprint for a building. Understanding it helps you know where everything is and how it all connects!
