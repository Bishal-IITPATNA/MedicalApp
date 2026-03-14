# Module Ownership & Responsibilities

This document defines clear ownership boundaries for different parts of the codebase, enabling teams to work independently.

## 🎯 Ownership Principles

1. **Clear Boundaries:** Each team owns specific files/folders
2. **Minimal Overlap:** Reduce conflicts between teams
3. **Shared Resources:** Common code accessible to all
4. **Communication:** Changes to shared code require team consensus

## 📦 Backend Module Ownership

### Team A: Authentication & User Management

**Primary Owner:** Backend authentication specialist

**Owns:**
```
backend/app/
├── routes/auth.py
├── models/user.py
└── utils/auth_decorators.py
```

**Endpoints:**
- POST `/api/auth/register`
- POST `/api/auth/login`
- POST `/api/auth/refresh`
- POST `/api/auth/logout`
- POST `/api/auth/change-password`
- POST `/api/auth/forgot-password`
- POST `/api/auth/reset-password`

**Responsibilities:**
- User registration with role-based profiles
- Login with JWT token generation
- Token refresh mechanism
- Password hashing and verification
- Password change for authenticated users
- Password reset via secure tokens (1-hour expiry)
- Security notifications for password changes
- Role-based access control decorators

**Can Modify:**
- User, Patient, Doctor, Nurse, Store models
- Authentication routes
- JWT configuration
- Auth-related utilities

**Must Coordinate On:**
- Changes to User model (affects all teams)
- JWT token structure changes
- Auth middleware changes

---

### Team B: Appointment System

**Primary Owner:** Healthcare workflow specialist

**Owns:**
```
backend/app/
├── routes/appointments.py
├── routes/doctor.py (scheduling parts)
├── models/appointment.py
└── utils/schedule_helpers.py
```

**Endpoints:**
- GET/POST `/api/patient/appointments`
- PUT `/api/patient/appointments/<id>`
- GET/POST `/api/doctor/appointments`
- POST `/api/doctor/chambers`
- POST `/api/doctor/schedules`

**Responsibilities:**
- Appointment booking logic
- Doctor schedule management
- Chamber (practice location) management
- Availability checking
- Appointment status updates
- Appointment notifications

**Can Modify:**
- Appointment, Chamber, DoctorSchedule models
- Appointment-related routes
- Schedule utilities

**Must Coordinate On:**
- Changes affecting prescriptions (Team C dependency)
- Notification triggers (shared utility)

---

### Team C: Medicine & Prescription Management

**Primary Owner:** Pharmacy system specialist

**Owns:**
```
backend/app/
├── routes/patient.py (medicine order endpoints)
├── routes/medical_store.py
├── routes/prescriptions.py
├── models/medicine.py
└── utils/prescription_validators.py
```

**Endpoints:**
- GET/POST `/api/patient/medicine-orders`
- GET/POST `/api/doctor/prescriptions`
- GET/POST/PUT `/api/medical-store/medicines`
- GET/PUT `/api/medical-store/orders`
- GET `/api/medical-store/dashboard`

**Responsibilities:**
- Medicine inventory management
- Medicine order processing
- Prescription creation and validation
- Order routing to admin (home delivery)
- Stock management
- Store analytics

**Can Modify:**
- Medicine, MedicineOrder, OrderItem, Prescription models
- Medicine-related routes
- Prescription validation logic

**Must Coordinate On:**
- Prescription model changes (Team B creates prescriptions)
- Order routing logic (Team E admin)

---

### Team D: Lab Test Management

**Primary Owner:** Laboratory system specialist

**Owns:**
```
backend/app/
├── routes/lab_store.py
├── routes/doctor_lab_tests.py
├── models/lab.py
└── utils/lab_result_formatters.py
```

**Endpoints:**
- GET/POST/PUT `/api/lab-store/tests`
- GET/PUT `/api/lab-store/orders`
- GET `/api/lab-store/dashboard`
- POST `/api/doctor/lab-tests` (order tests)

**Responsibilities:**
- Lab test catalog management
- Test order processing
- Result entry (JSON format)
- Lab analytics
- Profile management (direct response, no wrapper)

**Can Modify:**
- LabTest, DoctorLabTest, LabStore models
- Lab-related routes
- Result formatting utilities

**Must Coordinate On:**
- Test ordering by doctors (Team B integration)
- Result format changes (affects frontend Team E)

---

### Team E: Admin & Analytics

**Primary Owner:** System administration specialist

**Owns:**
```
backend/app/
├── routes/admin.py
├── utils/analytics.py
└── utils/report_generators.py
```

**Endpoints:**
- GET `/api/admin/home-delivery-orders`
- PUT `/api/admin/orders/<id>`
- GET `/api/admin/dashboard`
- GET `/api/admin/reports` (future)

**Responsibilities:**
- Home delivery order management
- System-wide analytics
- User management (future)
- Report generation
- System health monitoring

**Can Modify:**
- Admin routes
- Analytics utilities
- Reporting logic

**Must Coordinate On:**
- Order status changes (Team C dependency)
- Analytics queries (may affect all models)

---

## 📱 Frontend Module Ownership

### Team A: Authentication UI

**Primary Owner:** Frontend auth specialist

**Owns:**
```
frontend/lib/
├── screens/auth/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   └── reset_password_screen.dart
└── services/auth_service.dart
```

**Responsibilities:**
- Login form with validation and forgot password link
- Registration with role selection
- Forgot password flow (request reset token)
- Reset password flow (verify token and set new password)
- Change password screen (for authenticated users)
- Auth service (token management)
- Password management API integration
- Session handling

**Can Modify:**
- Auth screens
- AuthService
- Auth-related models

**Must Coordinate On:**
- AuthService changes (all teams use it)
- Token storage format

---

### Team B: Patient Experience UI

**Primary Owner:** Patient interface specialist

**Owns:**
```
frontend/lib/screens/patient/
├── patient_dashboard.dart
├── find_doctor_screen.dart
├── book_appointment_screen.dart
├── appointment_detail_screen.dart
├── buy_medicine_screen.dart
├── cart_screen.dart
├── book_lab_test_screen.dart
└── prescriptions_screen.dart
```

**Responsibilities:**
- Patient dashboard (4 tabs)
- Doctor search and filtering
- Appointment booking flow
- Medicine shopping with cart
- Prescription viewing
- Lab test booking
- Order history

**Can Modify:**
- Patient screens
- Patient-related widgets
- Shopping cart logic

**Must Coordinate On:**
- Shared widgets (AppointmentCard, etc.)
- Navigation changes

---

### Team C: Doctor Portal UI

**Primary Owner:** Doctor interface specialist

**Owns:**
```
frontend/lib/screens/doctor/
├── doctor_dashboard.dart
├── patient_detail_screen.dart
├── write_prescription_screen.dart
└── doctor_profile_screen.dart
```

**Responsibilities:**
- Doctor appointment management
- Patient details view
- Prescription writing UI
- Chamber management
- Schedule configuration
- Multiple chambers support

**Can Modify:**
- Doctor screens
- Prescription form widgets
- Chamber management UI

**Must Coordinate On:**
- Prescription format (affects Patient Team B)
- Shared appointment widgets

---

### Team D: Medical Store UI

**Primary Owner:** Pharmacy interface specialist

**Owns:**
```
frontend/lib/screens/medical_store/
├── medical_store_dashboard.dart
├── order_medicines_screen.dart
└── analytics_screen.dart
```

**Responsibilities:**
- Medicine inventory management
- Order processing interface
- Analytics dashboard
- Stock alerts UI

**Can Modify:**
- Medical store screens
- Inventory widgets
- Analytics visualizations

**Must Coordinate On:**
- Shared analytics components

---

### Team E: Lab Store UI

**Primary Owner:** Lab interface specialist

**Owns:**
```
frontend/lib/screens/lab_store/
├── lab_store_dashboard.dart
├── manage_tests_screen.dart
├── analytics_screen.dart
├── profile_screen.dart
└── settings_screen.dart
```

**Responsibilities:**
- Lab test catalog UI
- Test order processing
- Result entry form
- Lab analytics
- Profile/settings (top-right menu)
- Special: Profile parsing `responseData?['data']`

**Can Modify:**
- Lab store screens
- Test management widgets
- Result entry forms

**Must Coordinate On:**
- Analytics dashboard patterns (similar to Team D)

---

## 🔄 Shared Resources

### Backend Shared

**Everyone Can Use (Read-Only):**
```
backend/app/
├── models/__init__.py
├── utils/validators.py
├── utils/decorators.py
└── config.py
```

**Modification Process:**
1. Create GitHub issue
2. Discuss with all teams
3. Get approvals
4. Create PR
5. Merge after review

### Frontend Shared

**Everyone Can Use:**
```
frontend/lib/
├── models/           # All data models
├── services/
│   └── api_service.dart
└── widgets/          # Reusable components
```

**Adding Shared Widget:**
1. Create in `lib/widgets/`
2. Document usage
3. Notify teams
4. Review by UI lead

---

## 📋 Ownership Matrix

| Module | Backend Owner | Frontend Owner | Dependencies |
|--------|---------------|----------------|--------------|
| Authentication | Team A | Team A | None |
| Appointments | Team B | Team B, C | Team A (users) |
| Medicines | Team C | Team B (patient), D (store) | Team A, B (prescriptions) |
| Lab Tests | Team D | Team B (patient), E (store) | Team A, B (orders) |
| Admin | Team E | - | Teams C, D (orders) |

---

## 🚀 Development Workflow

### Starting New Feature

1. **Check ownership**: Am I the owner?
2. **Check dependencies**: Do I need other teams?
3. **Create branch**: `feature/team-x-feature-name`
4. **Develop**: Work in your module
5. **Test**: Unit and integration tests
6. **PR**: Request review from relevant teams
7. **Merge**: After approval

### Modifying Shared Code

1. **Create issue**: Describe change and reason
2. **Discussion**: All teams weigh in
3. **Approval**: Need consensus
4. **Implementation**: Create PR
5. **Migration plan**: If breaking change
6. **Documentation**: Update this guide

### Emergency Fixes

1. **Hotfix branch**: `hotfix/critical-issue`
2. **Minimal changes**: Only what's needed
3. **Notify teams**: Immediately
4. **Fast review**: Priority review
5. **Merge**: After testing

---

## 📞 Communication Channels

### Daily Sync
- **When:** Every morning
- **Duration:** 15 minutes
- **Format:** 
  - What I did yesterday
  - What I'm doing today
  - Any blockers

### Code Reviews
- **Response time:** Within 24 hours
- **Format:**
  - Functionality check
  - Code quality review
  - Suggest improvements

### Team Meetings
- **When:** Weekly
- **Topics:**
  - Architecture decisions
  - Shared code changes
  - Integration issues

---

## 🎯 Best Practices

1. **Stay in Your Lane:** Modify only your owned files
2. **Ask Before Changing Shared Code:** Get team consensus
3. **Document Changes:** Update this guide when ownership changes
4. **Test Integrations:** Test with dependent modules
5. **Communicate Early:** Don't surprise other teams

---

**Next:** See [Team Workflow](./team-workflow.md) for collaboration details.
