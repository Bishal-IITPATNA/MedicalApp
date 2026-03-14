# Database Models Guide

This guide explains all database tables (models) in the Medical App. Think of each model as a spreadsheet with columns.

## 🎯 What You'll Learn

- All 24+ database models
- Relationships between models
- How to query data
- How to create/update records

## 📊 Entity Relationship Overview

```
┌──────────┐         ┌──────────┐         ┌──────────┐
│   User   │────────▶│ Patient  │────────▶│Appointment│
│          │         │          │         │          │
│  (Auth)  │         │ (Profile)│◀────────│ (Booking)│
└──────────┘         └──────────┘         └──────────┘
     │                    │                     │
     │                    │                     ▼
     ▼                    │              ┌──────────┐
┌──────────┐              │              │Prescription│
│  Doctor  │──────────────┘              │          │
│          │                             └──────────┘
│ (Profile)│                                  │
└──────────┘                                  ▼
     │                                 ┌──────────┐
     ▼                                 │ Medicine │
┌──────────┐                           │          │
│ Chamber  │                           └──────────┘
│          │                                  │
│(Location)│                                  ▼
└──────────┘                          ┌──────────┐
     │                                 │MedicineOrder│
     ▼                                 │          │
┌──────────┐                           └──────────┘
│ Schedule │                                  │
│          │                                  ▼
│  (Time)  │                           ┌──────────┐
└──────────┘                           │OrderItem │
                                       │          │
                                       └──────────┘
```

## 👤 User & Authentication Models

### 1. User (Core Authentication)

**Purpose**: Store login credentials for all system users

**File**: `app/models/user.py`

**Table Structure**:
```python
class User(db.Model):
    id                   # Auto-increment primary key
    email                # Unique login email
    password_hash        # Bcrypt hashed password
    role                 # Enum: patient, doctor, nurse, medical_store, lab_store, admin
    created_at           # Timestamp of registration
    is_active            # Boolean: can they login?
    reset_token          # Password reset token (String 100, unique, nullable)
    reset_token_expiry   # Token expiration timestamp (DateTime, nullable)
```

**Example Record**:
```
id: 1
email: patient@example.com
password_hash: $2b$12$KIXqF3qNk...
role: patient
created_at: 2024-12-01 10:30:00
is_active: True
reset_token: null
reset_token_expiry: null
```

**Key Methods**:
```python
# Create new user
user = User(
    email='new@user.com',
    password_hash=generate_password_hash('password123'),
    role='patient'
)
db.session.add(user)
db.session.commit()

# Check password
user.check_password('password123')  # Returns True/False

# Generate password reset token
reset_token = user.generate_reset_token()
# Token expires in 1 hour
# Store this token to send via email

# Verify reset token
is_valid = user.verify_reset_token(token)
# Returns True if token matches and hasn't expired

# Clear reset token (after password reset)
user.clear_reset_token()
db.session.commit()

# Find user by email
user = User.query.filter_by(email='patient@example.com').first()

# Get user's role-specific profile
if user.role == 'patient':
    profile = user.patient  # Uses backref
```

**Relationships**:
- One User → One Patient (if role='patient')
- One User → One Doctor (if role='doctor')
- One User → One Nurse (if role='nurse')
- One User → One MedicalStore (if role='medical_store')
- One User → One LabStore (if role='lab_store')

### 2. Patient

**Purpose**: Patient profile information

**Table Structure**:
```python
class Patient(db.Model):
    id              # Primary key
    user_id         # Foreign key → user.id
    name            # Full name
    phone           # Contact number
    dob             # Date of birth
    gender          # Male/Female/Other
    blood_group     # A+, B+, O-, etc.
    address         # Full address
    emergency_contact  # Emergency phone
```

**Example Record**:
```
id: 1
user_id: 1
name: John Doe
phone: +1-234-567-8900
dob: 1990-05-15
gender: Male
blood_group: O+
address: 123 Main St, City
emergency_contact: +1-234-567-8901
```

**Queries**:
```python
# Get patient by user_id
patient = Patient.query.filter_by(user_id=1).first()

# Get patient with user info
patient = Patient.query.join(User).filter(User.email == 'patient@example.com').first()

# Get all patients
patients = Patient.query.all()

# Update patient info
patient = Patient.query.get(1)
patient.phone = '+1-999-888-7777'
db.session.commit()
```

**Relationships**:
- Many Appointments (patient.appointments)
- Many Prescriptions (patient.prescriptions)
- Many MedicineOrders (patient.medicine_orders)
- Many PatientHistory records (patient.history)

### 3. Doctor

**Purpose**: Doctor profile and credentials

**Table Structure**:
```python
class Doctor(db.Model):
    id                  # Primary key
    user_id             # Foreign key → user.id
    name                # Full name
    specialization      # e.g., Cardiology, Pediatrics
    qualification       # e.g., MBBS, MD
    experience_years    # Years of practice
    registration_number # Medical registration ID
    phone               # Contact
    bio                 # About the doctor
    consultation_fee    # Default fee (can be overridden per chamber)
```

**Example Record**:
```
id: 1
user_id: 2
name: Dr. Sarah Smith
specialization: General Physician
qualification: MBBS, MD
experience_years: 10
registration_number: MED12345
phone: +1-555-1234
bio: Experienced family doctor...
consultation_fee: 50.00
```

**Queries**:
```python
# Search doctors by specialization
doctors = Doctor.query.filter(
    Doctor.specialization.ilike('%cardio%')
).all()

# Get doctor with chambers
doctor = Doctor.query.get(1)
chambers = doctor.chambers  # All practice locations

# Get doctor's upcoming appointments
from datetime import datetime
appointments = Appointment.query.filter(
    Appointment.doctor_id == 1,
    Appointment.appointment_date >= datetime.now()
).all()
```

**Relationships**:
- Many Chambers (practice locations)
- Many Schedules (availability)
- Many Appointments
- Many Prescriptions

## 🏥 Appointment Models

### 4. Chamber

**Purpose**: Doctor's practice locations (a doctor can work at multiple places)

**Table Structure**:
```python
class Chamber(db.Model):
    id          # Primary key
    doctor_id   # Foreign key → doctor.id
    name        # e.g., "Main Clinic", "City Hospital"
    address     # Full address
    phone       # Chamber contact
    city        # City name
    state       # State/Province
    zipcode     # Postal code
```

**Example Records**:
```
Doctor ID 1 has 2 chambers:

Chamber 1:
  id: 1
  doctor_id: 1
  name: Downtown Clinic
  address: 456 Oak Ave
  city: New York
  
Chamber 2:
  id: 2
  doctor_id: 1
  name: City Hospital
  address: 789 Hospital Rd
  city: New York
```

**Usage**:
```python
# Get all chambers for a doctor
chambers = Chamber.query.filter_by(doctor_id=1).all()

# Add new chamber
new_chamber = Chamber(
    doctor_id=1,
    name='Suburb Clinic',
    address='321 Suburb St',
    city='Brooklyn'
)
db.session.add(new_chamber)
db.session.commit()
```

### 5. DoctorSchedule

**Purpose**: Doctor's availability at each chamber

**Table Structure**:
```python
class DoctorSchedule(db.Model):
    id              # Primary key
    doctor_id       # Foreign key → doctor.id
    chamber_id      # Foreign key → chamber.id
    day_of_week     # 0=Monday, 6=Sunday
    start_time      # e.g., "09:00"
    end_time        # e.g., "17:00"
    slot_duration   # Minutes per appointment (e.g., 30)
```

**Example Records**:
```
Schedule 1:
  doctor_id: 1
  chamber_id: 1  (Downtown Clinic)
  day_of_week: 1  (Monday)
  start_time: 09:00
  end_time: 17:00
  slot_duration: 30
  
Schedule 2:
  doctor_id: 1
  chamber_id: 2  (City Hospital)
  day_of_week: 3  (Wednesday)
  start_time: 14:00
  end_time: 20:00
  slot_duration: 45
```

**Queries**:
```python
# Get doctor's schedule for a specific day
schedules = DoctorSchedule.query.filter_by(
    doctor_id=1,
    day_of_week=1  # Monday
).all()

# Get available time slots
from datetime import datetime, timedelta

def get_available_slots(doctor_id, chamber_id, date):
    # Get schedule for that day of week
    day_of_week = date.weekday()
    schedule = DoctorSchedule.query.filter_by(
        doctor_id=doctor_id,
        chamber_id=chamber_id,
        day_of_week=day_of_week
    ).first()
    
    if not schedule:
        return []
    
    # Generate time slots
    slots = []
    current_time = datetime.strptime(schedule.start_time, '%H:%M')
    end_time = datetime.strptime(schedule.end_time, '%H:%M')
    
    while current_time < end_time:
        slots.append(current_time.strftime('%H:%M'))
        current_time += timedelta(minutes=schedule.slot_duration)
    
    return slots
```

### 6. Appointment

**Purpose**: Store patient appointment bookings

**Table Structure**:
```python
class Appointment(db.Model):
    id                      # Primary key
    patient_id              # Foreign key → patient.id
    doctor_id               # Foreign key → doctor.id
    chamber_id              # Foreign key → chamber.id
    appointment_date        # DateTime
    status                  # Enum: pending, confirmed, completed, cancelled
    problem_description     # Patient's complaint
    notes                   # Doctor's notes
    consultation_fee        # Actual fee charged
    created_at              # Booking timestamp
```

**Example Record**:
```
id: 10
patient_id: 1
doctor_id: 1
chamber_id: 1
appointment_date: 2024-12-15 10:00:00
status: confirmed
problem_description: Fever and headache for 3 days
notes: null  (filled after appointment)
consultation_fee: 50.00
created_at: 2024-12-10 14:30:00
```

**Status Flow**:
```
pending → confirmed → completed
   ↓
cancelled (at any time)
```

**Queries**:
```python
# Get patient's upcoming appointments
upcoming = Appointment.query.filter(
    Appointment.patient_id == 1,
    Appointment.appointment_date >= datetime.now(),
    Appointment.status.in_(['pending', 'confirmed'])
).order_by(Appointment.appointment_date).all()

# Get doctor's today's appointments
from datetime import date
today_start = datetime.combine(date.today(), datetime.min.time())
today_end = datetime.combine(date.today(), datetime.max.time())

todays_appointments = Appointment.query.filter(
    Appointment.doctor_id == 1,
    Appointment.appointment_date.between(today_start, today_end)
).all()

# Book new appointment
appointment = Appointment(
    patient_id=1,
    doctor_id=1,
    chamber_id=1,
    appointment_date=datetime(2024, 12, 15, 10, 0),
    status='pending',
    problem_description='Regular checkup',
    consultation_fee=50.00
)
db.session.add(appointment)
db.session.commit()
```

**Relationships**:
- One Appointment → One Prescription (appointment.prescription)
- One Appointment → Many LabTests (appointment.lab_tests)

## 💊 Medicine & Order Models

### 7. Medicine

**Purpose**: Medicine inventory

**Table Structure**:
```python
class Medicine(db.Model):
    id                      # Primary key
    name                    # Medicine name
    description             # Details
    manufacturer            # Company name
    category                # e.g., Antibiotic, Painkiller
    requires_prescription   # Boolean
    price                   # Unit price
    stock_quantity          # Available quantity
    expiry_date             # Expiration date
    dosage_form             # Tablet, Syrup, Injection
```

**Example Record**:
```
id: 20
name: Amoxicillin 500mg
description: Antibiotic for bacterial infections
manufacturer: PharmaCorp
category: Antibiotic
requires_prescription: True
price: 0.50
stock_quantity: 500
expiry_date: 2025-06-30
dosage_form: Tablet
```

**Business Logic**:
```python
# Check if medicine requires prescription
medicine = Medicine.query.get(20)
if medicine.requires_prescription:
    # Patient must have valid prescription to buy
    prescription = Prescription.query.filter_by(
        patient_id=patient_id,
        # Check if this medicine is in prescription
    ).first()
    
    if not prescription:
        return {'error': 'Prescription required'}, 403

# Update stock after purchase
medicine.stock_quantity -= quantity_sold
db.session.commit()
```

### 8. MedicineOrder

**Purpose**: Patient medicine purchases

**Table Structure**:
```python
class MedicineOrder(db.Model):
    id                  # Primary key
    patient_id          # Foreign key → patient.id
    order_date          # DateTime
    total_amount        # Total cost
    delivery_address    # Where to deliver
    delivery_type       # home_delivery, pickup
    payment_status      # pending, paid, failed
    order_status        # pending, confirmed, delivered, cancelled
    routed_to           # 'admin' for home delivery, store_id for pickup
```

**Example Record**:
```
id: 55
patient_id: 1
order_date: 2024-12-10 15:00:00
total_amount: 147.50
delivery_address: 123 Main St
delivery_type: home_delivery
payment_status: pending
order_status: pending
routed_to: admin  # Not to store!
```

**Relationships**:
- One Order → Many OrderItems

### 9. OrderItem

**Purpose**: Individual medicines in an order

**Table Structure**:
```python
class OrderItem(db.Model):
    id              # Primary key
    order_id        # Foreign key → medicine_order.id
    medicine_id     # Foreign key → medicine.id
    quantity        # How many units
    unit_price      # Price at time of purchase
    subtotal        # quantity * unit_price
```

**Example Records**:
```
Order #55 has 2 items:

Item 1:
  order_id: 55
  medicine_id: 20  (Amoxicillin)
  quantity: 14
  unit_price: 0.50
  subtotal: 7.00

Item 2:
  order_id: 55
  medicine_id: 21  (Paracetamol)
  quantity: 30
  unit_price: 0.10
  subtotal: 3.00

Total: $10.00
```

**Queries**:
```python
# Get order with items
order = MedicineOrder.query.get(55)
items = OrderItem.query.filter_by(order_id=55).all()

# Or use relationship:
order = MedicineOrder.query.get(55)
for item in order.items:
    print(f"{item.medicine.name}: {item.quantity} x ${item.unit_price}")
```

## 📋 Prescription & Medical History

### 10. Prescription

**Purpose**: Doctor's prescription after appointment

**Table Structure**:
```python
class Prescription(db.Model):
    id                  # Primary key
    appointment_id      # Foreign key → appointment.id (one-to-one)
    patient_id          # Foreign key → patient.id
    doctor_id           # Foreign key → doctor.id
    prescription_date   # Date issued
    diagnosis           # Medical diagnosis
    medicines           # JSON array of prescribed medicines
    instructions        # General instructions
    follow_up_date      # Next appointment date (optional)
```

**Medicines JSON Structure**:
```json
[
  {
    "medicine_id": 20,
    "medicine_name": "Amoxicillin 500mg",
    "dosage": "1 tablet",
    "frequency": "twice daily",
    "duration": "7 days",
    "instructions": "Take after meals"
  },
  {
    "medicine_id": 21,
    "medicine_name": "Paracetamol 500mg",
    "dosage": "1-2 tablets",
    "frequency": "as needed",
    "duration": "5 days",
    "instructions": "For fever"
  }
]
```

**Example Record**:
```
id: 10
appointment_id: 10
patient_id: 1
doctor_id: 1
prescription_date: 2024-12-15
diagnosis: Upper Respiratory Infection
medicines: [JSON array above]
instructions: Rest, drink fluids
follow_up_date: 2024-12-22
```

**Queries**:
```python
# Get prescription for appointment
prescription = Prescription.query.filter_by(appointment_id=10).first()

# Get patient's prescription history
prescriptions = Prescription.query.filter_by(
    patient_id=1
).order_by(Prescription.prescription_date.desc()).all()

# Create prescription
import json

prescription = Prescription(
    appointment_id=10,
    patient_id=1,
    doctor_id=1,
    prescription_date=date.today(),
    diagnosis='Upper Respiratory Infection',
    medicines=json.dumps([
        {
            'medicine_id': 20,
            'medicine_name': 'Amoxicillin 500mg',
            'dosage': '1 tablet',
            'frequency': 'twice daily',
            'duration': '7 days'
        }
    ]),
    instructions='Rest and fluids'
)
db.session.add(prescription)
db.session.commit()
```

### 11. PatientHistory

**Purpose**: Comprehensive medical history

**Table Structure**:
```python
class PatientHistory(db.Model):
    id                      # Primary key
    patient_id              # Foreign key → patient.id
    chronic_diseases        # JSON array: ['Diabetes', 'Hypertension']
    allergies               # JSON array: ['Penicillin', 'Peanuts']
    surgeries               # JSON array with date and description
    family_history          # JSON: genetic conditions
    lifestyle               # JSON: smoking, alcohol, exercise
    current_medications     # JSON array
    last_updated            # Timestamp
```

**Example Record**:
```json
{
  "id": 1,
  "patient_id": 1,
  "chronic_diseases": ["Type 2 Diabetes"],
  "allergies": ["Penicillin"],
  "surgeries": [
    {"date": "2020-05-10", "type": "Appendectomy"}
  ],
  "family_history": {
    "father": ["Heart Disease"],
    "mother": ["Diabetes"]
  },
  "lifestyle": {
    "smoking": false,
    "alcohol": "Occasional",
    "exercise": "3 times/week"
  },
  "current_medications": ["Metformin 500mg"],
  "last_updated": "2024-12-01"
}
```

## 🔬 Lab Test Models

### 12. LabTest

**Purpose**: Available lab tests catalog

**Table Structure**:
```python
class LabTest(db.Model):
    id              # Primary key
    name            # Test name
    description     # What it tests
    category        # Blood, Urine, Imaging, etc.
    price           # Cost
    preparation     # Fasting required? Instructions
    duration        # How long for results (hours)
    lab_store_id    # Which lab offers this (optional)
```

**Example Records**:
```
Test 1:
  name: Complete Blood Count (CBC)
  category: Blood Test
  price: 25.00
  preparation: No fasting required
  duration: 24

Test 2:
  name: Lipid Profile
  category: Blood Test
  price: 35.00
  preparation: 12-hour fasting required
  duration: 48
```

### 13. DoctorLabTest

**Purpose**: Lab tests ordered by doctor for patient

**Table Structure**:
```python
class DoctorLabTest(db.Model):
    id                  # Primary key
    appointment_id      # Foreign key → appointment.id
    patient_id          # Foreign key → patient.id
    doctor_id           # Foreign key → doctor.id
    test_id             # Foreign key → lab_test.id
    order_date          # When ordered
    status              # pending, sample_collected, completed
    result              # JSON with test results (after completion)
    result_date         # When results available
    lab_store_id        # Which lab is processing
```

**Result JSON Example**:
```json
{
  "test_name": "CBC",
  "result_date": "2024-12-11",
  "values": {
    "WBC": {"value": 7.5, "unit": "10^3/μL", "range": "4-11"},
    "RBC": {"value": 5.2, "unit": "10^6/μL", "range": "4.5-5.5"},
    "Hemoglobin": {"value": 14.5, "unit": "g/dL", "range": "13-17"}
  },
  "interpretation": "All values within normal range",
  "performed_by": "Lab Tech #123"
}
```

## 🏪 Store Models

### 14. MedicalStore

**Purpose**: Medical store profiles

**Table Structure**:
```python
class MedicalStore(db.Model):
    id              # Primary key
    user_id         # Foreign key → user.id
    name            # Store name
    license_number  # Government license
    phone           # Contact
    address         # Full address
    city            # City
    state           # State
    operating_hours # JSON: opening/closing times
```

### 15. LabStore

**Purpose**: Lab store profiles

**Table Structure**: Similar to MedicalStore
```python
class LabStore(db.Model):
    id                  # Primary key
    user_id             # Foreign key → user.id
    name                # Lab name
    accreditation       # Certification details
    phone               # Contact
    address             # Full address
    specializations     # JSON array of test categories
```

## 🔔 Notification Model

### 16. Notification

**Purpose**: In-app notifications

**Table Structure**:
```python
class Notification(db.Model):
    id          # Primary key
    user_id     # Foreign key → user.id
    title       # Notification title
    message     # Notification body
    type        # appointment, order, result, general
    is_read     # Boolean
    created_at  # Timestamp
    related_id  # ID of related record (appointment_id, order_id, etc.)
```

**Example Records**:
```
Notification 1:
  user_id: 1  (patient)
  title: Appointment Confirmed
  message: Your appointment with Dr. Smith on Dec 15 is confirmed
  type: appointment
  is_read: false
  related_id: 10  (appointment_id)

Notification 2:
  user_id: 2  (doctor)
  title: New Appointment Request
  message: John Doe has requested an appointment
  type: appointment
  is_read: true
  related_id: 10
```

## 💳 Payment & Billing Models

### 17. Payment

**Purpose**: Payment transactions

**Table Structure**:
```python
class Payment(db.Model):
    id                  # Primary key
    user_id             # Foreign key → user.id (payer)
    amount              # Payment amount
    payment_type        # appointment, medicine, lab_test
    payment_method      # card, upi, cash, razorpay
    payment_status      # pending, success, failed
    transaction_id      # External payment gateway ID
    related_id          # ID of related record
    created_at          # Payment timestamp
```

**Example Record**:
```
id: 100
user_id: 1
amount: 500.00
payment_type: appointment
payment_method: razorpay
payment_status: success
transaction_id: pay_abc123xyz
related_id: 10  (appointment_id)
created_at: 2024-12-15 10:30:00
```

### 18. MedicineBill

**Purpose**: Medicine purchase bills for stores

**Table Structure**:
```python
class MedicineBill(db.Model):
    id                      # Primary key
    medical_store_id        # Foreign key → medical_store.id
    patient_id              # Foreign key → patient.id (nullable)
    bill_number             # Unique bill number
    total_amount            # Total bill amount
    discount                # Discount amount
    tax                     # Tax amount
    final_amount            # After discount and tax
    payment_status          # paid, pending, partial
    payment_method          # cash, card, upi
    created_at              # Bill timestamp
```

**Relationships**:
- One MedicineBill → Many MedicineBillItems

### 19. MedicineBillItem

**Purpose**: Individual medicines in a bill

**Table Structure**:
```python
class MedicineBillItem(db.Model):
    id              # Primary key
    bill_id         # Foreign key → medicine_bill.id
    medicine_id     # Foreign key → medicine.id
    quantity        # Quantity sold
    unit_price      # Price per unit
    discount        # Item discount
    subtotal        # After discount
```

### 20. LabTestBill

**Purpose**: Lab test bills for stores

**Table Structure**:
```python
class LabTestBill(db.Model):
    id                  # Primary key
    lab_store_id        # Foreign key → lab_store.id
    patient_id          # Foreign key → patient.id (nullable)
    bill_number         # Unique bill number
    total_amount        # Total bill amount
    discount            # Discount amount
    tax                 # Tax amount
    final_amount        # After discount and tax
    payment_status      # paid, pending, partial
    payment_method      # cash, card, upi
    created_at          # Bill timestamp
```

**Relationships**:
- One LabTestBill → Many LabTestBillItems

### 21. LabTestBillItem

**Purpose**: Individual tests in a lab bill

**Table Structure**:
```python
class LabTestBillItem(db.Model):
    id              # Primary key
    bill_id         # Foreign key → lab_test_bill.id
    test_id         # Foreign key → lab_test.id
    quantity        # Usually 1 for tests
    unit_price      # Price per test
    discount        # Item discount
    subtotal        # After discount
```

## 👥 Admin & System Models

### 22. Admin

**Purpose**: Administrator profile

**Table Structure**:
```python
class Admin(db.Model):
    id              # Primary key
    user_id         # Foreign key → user.id
    name            # Full name
    phone           # Contact number
    designation     # Admin role/title
    permissions     # JSON array of permissions
```

**Example Record**:
```
id: 1
user_id: 5
name: System Admin
phone: 9999999999
designation: Super Admin
permissions: ["manage_users", "view_reports", "system_config"]
```

## 🔄 Model Relationships Summary

```python
# One-to-One
User ←→ Patient
User ←→ Doctor
Appointment ←→ Prescription

# One-to-Many
Doctor → Chambers (one doctor, many locations)
Doctor → Schedules (one doctor, many time slots)
Patient → Appointments (one patient, many appointments)
Doctor → Appointments
MedicineOrder → OrderItems (one order, many medicines)

# Many-to-Many (through junction tables)
Appointment ↔ LabTest (through DoctorLabTest)
```

## 📝 Common Query Patterns

### Get Related Data (Joins)

```python
# Get appointment with patient and doctor info
appointment = db.session.query(Appointment)\
    .join(Patient)\
    .join(Doctor)\
    .filter(Appointment.id == 10)\
    .first()

print(appointment.patient.name)  # Access patient name
print(appointment.doctor.name)   # Access doctor name

# Get patient with all prescriptions and medicines
patient = Patient.query.get(1)
for prescription in patient.prescriptions:
    medicines = json.loads(prescription.medicines)
    for med in medicines:
        print(med['medicine_name'])
```

### Aggregate Queries

```python
# Count patient's appointments
from sqlalchemy import func

appointment_count = db.session.query(func.count(Appointment.id))\
    .filter(Appointment.patient_id == 1)\
    .scalar()

# Total order amount for patient
total_spent = db.session.query(func.sum(MedicineOrder.total_amount))\
    .filter(MedicineOrder.patient_id == 1)\
    .scalar()

# Average consultation fee per doctor
avg_fee = db.session.query(func.avg(Appointment.consultation_fee))\
    .filter(Appointment.doctor_id == 1)\
    .scalar()
```

### Pagination

```python
# Get page 2 of appointments, 10 per page
page = 2
per_page = 10

appointments = Appointment.query\
    .filter(Appointment.patient_id == 1)\
    .order_by(Appointment.appointment_date.desc())\
    .paginate(page=page, per_page=per_page, error_out=False)

for appointment in appointments.items:
    print(appointment)

print(f"Total: {appointments.total}")
print(f"Pages: {appointments.pages}")
```

## 🎯 Best Practices

1. **Always use relationships** instead of manual joins when possible
2. **Use `db.session.commit()`** after making changes
3. **Handle exceptions** when creating/updating records
4. **Use `query.get(id)`** for single record by primary key (fastest)
5. **Use `filter_by()`** for simple equality filters
6. **Use `filter()`** for complex conditions
7. **Always check for None** before accessing relationships

## 📚 Summary

You now understand:
- All 18 database models
- How they relate to each other
- How to query data effectively
- How to create/update records

Next: Read [API Endpoints Guide](./api-endpoints.md) to see how these models are exposed via REST API!
