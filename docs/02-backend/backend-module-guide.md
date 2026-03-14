# Backend Module Ownership Guide

This guide helps team members understand which backend modules they own and how to work with them independently.

## 📦 Module Structure

```
backend/
├── app/
│   ├── __init__.py          # App factory
│   ├── models/              # Database models (Team: Data)
│   │   ├── __init__.py
│   │   ├── user.py          # User, Patient, Doctor, Nurse
│   │   ├── appointment.py   # Appointment, Chamber, Schedule
│   │   ├── medicine.py      # Medicine, Order, OrderItem
│   │   ├── lab.py           # LabTest, LabStore
│   │   └── notification.py  # Notifications
│   │
│   ├── routes/              # API endpoints (Team: API)
│   │   ├── __init__.py
│   │   ├── auth.py          # Authentication
│   │   ├── patient.py       # Patient endpoints
│   │   ├── doctor.py        # Doctor endpoints
│   │   ├── medical_store.py # Medical store endpoints
│   │   ├── lab_store.py     # Lab store endpoints
│   │   └── admin.py         # Admin endpoints
│   │
│   └── utils/               # Helper functions (Team: Core)
│       ├── __init__.py
│       ├── validators.py    # Input validation
│       └── decorators.py    # Custom decorators
│
├── migrations/              # Database migrations (Team: Data)
├── config.py                # Configuration (Team: Core)
├── run.py                   # Entry point (Team: Core)
└── requirements.txt         # Dependencies (Team: Core)
```

## 👥 Team Module Assignments

### Team A: Authentication & User Management

**Owns:**
- `app/routes/auth.py`
- `app/models/user.py`
- User registration/login logic
- JWT token management
- Password reset functionality

**Responsibilities:**
- Implement secure authentication
- Handle user sessions
- Manage user profiles
- Role-based access control

**Key Files to Modify:**

1. **app/routes/auth.py**
```python
# Your module handles:
# - POST /api/auth/register
# - POST /api/auth/login
# - POST /api/auth/refresh
# - POST /api/auth/logout
# - POST /api/auth/forgot-password
# - POST /api/auth/reset-password
```

2. **app/models/user.py**
```python
# Your models:
# - User (base authentication)
# - Patient (patient profile)
# - Doctor (doctor profile)
# - Nurse (nurse profile)
# - MedicalStore (store profile)
# - LabStore (lab profile)
```

**Testing Your Module:**
```bash
# Run tests
pytest tests/test_auth.py

# Test endpoints
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"pass123","role":"patient"}'
```

---

### Team B: Appointment System

**Owns:**
- `app/routes/appointments.py`
- `app/models/appointment.py`
- `app/routes/doctor.py` (scheduling parts)
- Appointment booking logic
- Doctor schedule management

**Responsibilities:**
- Appointment CRUD operations
- Doctor availability management
- Appointment notifications
- Calendar integration

**Key Files to Modify:**

1. **app/models/appointment.py**
```python
# Your models:
# - Appointment
# - Chamber (doctor practice locations)
# - DoctorSchedule (availability)
```

2. **app/routes/doctor.py** (scheduling endpoints)
```python
# Your endpoints:
# - POST /api/doctor/chambers
# - POST /api/doctor/schedules
# - GET /api/doctor/appointments
# - PUT /api/doctor/appointments/<id>
```

**Dependencies:**
- Requires: User models (Team A)
- Used by: Frontend appointment screens

**Testing:**
```bash
# Test appointment booking
curl -X POST http://localhost:5000/api/patient/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"doctor_id":1,"chamber_id":1,"appointment_date":"2024-12-15T10:00:00"}'

# Test schedule availability
curl http://localhost:5000/api/doctor/schedules?doctor_id=1&date=2024-12-15 \
  -H "Authorization: Bearer $TOKEN"
```

---

### Team C: Medicine Management & Ordering

**Owns:**
- `app/routes/patient.py` (medicine order endpoints)
- `app/routes/medical_store.py`
- `app/models/medicine.py`
- Medicine inventory
- Order processing

**Responsibilities:**
- Medicine catalog management
- Order creation and tracking
- Prescription validation
- Stock management

**Key Files to Modify:**

1. **app/models/medicine.py**
```python
# Your models:
# - Medicine
# - MedicineOrder
# - OrderItem
# - Prescription
```

2. **app/routes/medical_store.py**
```python
# Your endpoints:
# - GET /api/medical-store/medicines
# - POST /api/medical-store/medicines
# - PUT /api/medical-store/medicines/<id>
# - GET /api/medical-store/orders
# - PUT /api/medical-store/orders/<id>
# - GET /api/medical-store/dashboard
```

**Business Logic:**
```python
def create_medicine_order(patient_id, items, delivery_address):
    """
    Your responsibility:
    1. Validate prescription for Rx medicines
    2. Check stock availability
    3. Calculate total amount
    4. Create order and items
    5. Route to admin for home delivery
    6. Send notifications
    """
    pass
```

**Testing:**
```bash
# Add medicine
curl -X POST http://localhost:5000/api/medical-store/medicines \
  -H "Authorization: Bearer $STORE_TOKEN" \
  -d '{"name":"Aspirin","price":5.99,"stock_quantity":100}'

# Place order
curl -X POST http://localhost:5000/api/patient/medicine-orders \
  -H "Authorization: Bearer $PATIENT_TOKEN" \
  -d '{"items":[{"medicine_id":1,"quantity":2}],"delivery_address":"123 Main St"}'
```

---

### Team D: Lab Test Management

**Owns:**
- `app/routes/lab_store.py`
- `app/routes/doctor_lab_tests.py`
- `app/models/lab.py`
- Lab test catalog
- Test result management

**Responsibilities:**
- Lab test CRUD
- Test order processing
- Result entry and reporting
- Lab analytics

**Key Files to Modify:**

1. **app/models/lab.py**
```python
# Your models:
# - LabTest
# - DoctorLabTest (orders)
# - LabStore
```

2. **app/routes/lab_store.py**
```python
# Your endpoints:
# - GET /api/lab-store/tests
# - POST /api/lab-store/tests
# - GET /api/lab-store/orders
# - PUT /api/lab-store/orders/<id> (update status/results)
# - GET /api/lab-store/dashboard
```

**Result Format (JSON):**
```json
{
  "test_name": "Complete Blood Count",
  "result_date": "2024-12-11",
  "values": {
    "WBC": {"value": 7.5, "unit": "10^3/μL", "range": "4-11"},
    "RBC": {"value": 5.2, "unit": "10^6/μL", "range": "4.5-5.5"}
  },
  "interpretation": "All values normal"
}
```

**Testing:**
```bash
# Add lab test
curl -X POST http://localhost:5000/api/lab-store/tests \
  -H "Authorization: Bearer $LAB_TOKEN" \
  -d '{"name":"CBC","category":"Blood","price":25.00}'

# Update test result
curl -X PUT http://localhost:5000/api/lab-store/orders/1 \
  -H "Authorization: Bearer $LAB_TOKEN" \
  -d '{"status":"completed","result":{...}}'
```

---

### Team E: Admin & Analytics

**Owns:**
- `app/routes/admin.py`
- Dashboard analytics
- Reporting endpoints
- Home delivery management

**Responsibilities:**
- Admin dashboard data
- System-wide analytics
- Home delivery order management
- Reports generation

**Key Endpoints:**
```python
# app/routes/admin.py
@bp.route('/home-delivery-orders')
@role_required(['admin'])
def get_home_delivery_orders():
    """Get all home delivery orders"""
    pass

@bp.route('/dashboard')
@role_required(['admin'])
def get_admin_dashboard():
    """
    Return:
    - Total users by role
    - Total appointments
    - Total orders
    - Revenue statistics
    """
    pass
```

**Analytics Queries:**
```python
from sqlalchemy import func
from app.models import User, Appointment, MedicineOrder

def get_dashboard_stats():
    # Count users by role
    user_stats = db.session.query(
        User.role,
        func.count(User.id)
    ).group_by(User.role).all()
    
    # Total revenue
    total_revenue = db.session.query(
        func.sum(MedicineOrder.total_amount)
    ).scalar()
    
    # Appointments this month
    from datetime import datetime, timedelta
    month_start = datetime.now().replace(day=1)
    appointments_this_month = Appointment.query.filter(
        Appointment.appointment_date >= month_start
    ).count()
    
    return {
        'users': dict(user_stats),
        'total_revenue': total_revenue,
        'appointments_this_month': appointments_this_month
    }
```

---

## 🔄 Module Interaction

### How Modules Communicate

```
┌─────────────────────────────────────────────────────────┐
│ Example: Patient Books Appointment                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ Team B (Appointments)                                    │
│   ├─> Uses: User model from Team A                      │
│   ├─> Creates: Appointment record                       │
│   └─> Triggers: Notification (shared utility)           │
│                                                          │
│ Team A (Auth) provides:                                 │
│   └─> User authentication                               │
│   └─> Patient/Doctor models                             │
│                                                          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Example: Medicine Order with Prescription               │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ Team C (Medicine)                                        │
│   ├─> Uses: Prescription model                          │
│   ├─> Validates: Rx requirements                        │
│   ├─> Creates: MedicineOrder                            │
│   └─> Routes to: Admin (Team E)                         │
│                                                          │
│ Team B (Appointments) provides:                          │
│   └─> Prescription after appointment                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Shared Utilities

All teams can use these shared utilities:

**app/utils/decorators.py**
```python
# Role-based access control
from functools import wraps
from flask_jwt_extended import get_jwt, jwt_required

def role_required(allowed_roles):
    def wrapper(fn):
        @wraps(fn)
        @jwt_required()
        def decorator(*args, **kwargs):
            claims = get_jwt()
            if claims.get('role') not in allowed_roles:
                return {'error': 'Forbidden'}, 403
            return fn(*args, **kwargs)
        return decorator
    return wrapper
```

**app/utils/validators.py**
```python
# Input validation
def validate_email(email):
    import re
    pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
    return re.match(pattern, email) is not None

def validate_phone(phone):
    import re
    pattern = r'^\+?1?\d{9,15}$'
    return re.match(pattern, phone) is not None
```

## 🧪 Testing Your Module

### Unit Tests Structure

```
backend/tests/
├── test_auth.py          # Team A
├── test_appointments.py  # Team B
├── test_medicines.py     # Team C
├── test_lab.py           # Team D
└── test_admin.py         # Team E
```

### Example Test File

**tests/test_auth.py**
```python
import pytest
from app import create_app, db
from app.models.user import User

@pytest.fixture
def client():
    app = create_app('testing')
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()

def test_register(client):
    """Test user registration"""
    response = client.post('/api/auth/register', json={
        'email': 'test@test.com',
        'password': 'password123',
        'role': 'patient',
        'name': 'Test User'
    })
    assert response.status_code == 201
    assert response.json['success'] == True

def test_login(client):
    """Test user login"""
    # First register
    client.post('/api/auth/register', json={
        'email': 'test@test.com',
        'password': 'password123',
        'role': 'patient'
    })
    
    # Then login
    response = client.post('/api/auth/login', json={
        'email': 'test@test.com',
        'password': 'password123'
    })
    assert response.status_code == 200
    assert 'access_token' in response.json
```

### Run Tests

```bash
# Run all tests
pytest

# Run specific module tests
pytest tests/test_auth.py

# Run with coverage
pytest --cov=app tests/

# Run with verbose output
pytest -v
```

## 📝 Documentation Responsibilities

Each team should document:

1. **API Endpoints**
   - Request/response formats
   - Authentication requirements
   - Error codes

2. **Database Models**
   - Table structure
   - Relationships
   - Constraints

3. **Business Logic**
   - Validation rules
   - Workflow steps
   - Edge cases

## 🔄 Development Workflow

### 1. Feature Development

```bash
# Create feature branch
git checkout -b feature/team-c-prescription-validation

# Make changes to your module
# ... edit files ...

# Run your module tests
pytest tests/test_medicines.py

# Commit changes
git add .
git commit -m "Add prescription validation for medicine orders"

# Push and create PR
git push origin feature/team-c-prescription-validation
```

### 2. Database Changes

```bash
# Create migration
flask db migrate -m "Add expiry_date to Medicine model"

# Review migration file
# migrations/versions/xxx_add_expiry_date.py

# Apply migration
flask db upgrade

# Commit migration
git add migrations/
git commit -m "Add expiry_date column to medicines table"
```

### 3. Code Review Checklist

- [ ] Tests pass
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] No breaking changes to other modules
- [ ] Migration files included (if schema changed)
- [ ] Error handling implemented
- [ ] Input validation added

## 🤝 Communication Between Teams

### When to Coordinate

**Scenario 1: Adding New Endpoint**
- Team C wants to add prescription history endpoint
- Coordinate with Team B (they own Prescription model)

**Scenario 2: Changing Model**
- Team A wants to add field to User model
- Notify all teams (everyone uses User)
- Create migration
- Update documentation

**Scenario 3: Shared Utility**
- Any team can add to `app/utils/`
- Notify team in PR description
- Add tests for utility function

## 🎯 Best Practices

1. **Stay in Your Module**
   - Modify only files you own
   - Use existing models from other teams
   - Don't duplicate logic

2. **Test Your Changes**
   - Write tests before code
   - Test happy path and errors
   - Test with different roles

3. **Document Everything**
   - Update API docs
   - Add docstrings
   - Comment complex logic

4. **Handle Errors**
   - Validate inputs
   - Return meaningful errors
   - Log exceptions

5. **Use Transactions**
```python
try:
    # Multiple database operations
    db.session.add(order)
    db.session.add(notification)
    db.session.commit()
except Exception as e:
    db.session.rollback()
    return {'error': str(e)}, 500
```

---

**Next:** See [Team Workflow Guide](../05-team/team-workflow.md) for collaboration practices.
