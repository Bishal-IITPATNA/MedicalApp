# API Endpoints Guide

Complete reference for all backend API endpoints.

## 🎯 Base URL

```
Development: http://localhost:5000
Production: https://your-domain.com
```

## 🔐 Authentication

Most endpoints require JWT authentication. Include token in header:

```
Authorization: Bearer <your_access_token>
```

## 📋 Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message here"
}
```

## 🔑 Authentication Endpoints

### POST /api/auth/register
Register a new user.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "role": "patient",
  "name": "John Doe",
  "phone": "1234567890",
  "dob": "1990-01-01",
  "gender": "Male",
  "blood_group": "O+"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "patient"
  }
}
```

### POST /api/auth/login
Login user and get access tokens.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "success": true,
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "patient"
  }
}
```

### POST /api/auth/refresh
Refresh access token.

**Headers:**
```
Authorization: Bearer <refresh_token>
```

**Response (200):**
```json
{
  "access_token": "new_access_token_here"
}
```

### POST /api/auth/logout
Logout user (client-side token removal).

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### POST /api/auth/change-password
Change password for authenticated user.

**Auth Required:** Yes

**Request Body:**
```json
{
  "current_password": "oldPassword123",
  "new_password": "newPassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

**Error (400):**
```json
{
  "success": false,
  "error": "Current password is incorrect"
}
```

### POST /api/auth/forgot-password
Request password reset token.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset token has been generated. Please check your notifications for the reset token.",
  "token": "abc123def456"
}
```

**Note:** Token is sent to user's notifications. In production, also send via email.

### POST /api/auth/reset-password
Reset password using token.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "user@example.com",
  "reset_token": "abc123def456",
  "new_password": "newPassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset successfully. You can now login with your new password."
}
```

**Error (400):**
```json
{
  "success": false,
  "error": "Invalid or expired token"
}
```

**Error (404):**
```json
{
  "success": false,
  "error": "User not found"
}
```

## 👤 Patient Endpoints

### GET /api/patient/profile
Get patient profile.

**Auth Required:** Yes

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "name": "John Doe",
    "email": "patient@example.com",
    "phone": "1234567890",
    "dob": "1990-01-01",
    "gender": "Male",
    "blood_group": "O+",
    "address": "123 Main St",
    "emergency_contact": "0987654321"
  }
}
```

### PUT /api/patient/profile
Update patient profile.

**Auth Required:** Yes

**Request Body:**
```json
{
  "name": "John Updated",
  "phone": "9999999999",
  "address": "456 New St"
}
```

### GET /api/patient/appointments
Get patient's appointments.

**Auth Required:** Yes

**Query Parameters:**
- `status` (optional): pending, confirmed, completed, cancelled
- `upcoming` (optional): true/false

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "doctor_name": "Dr. Sarah Smith",
      "doctor_specialization": "General Physician",
      "chamber_name": "Downtown Clinic",
      "chamber_address": "456 Oak Ave",
      "appointment_date": "2024-12-15T10:00:00",
      "status": "confirmed",
      "problem_description": "Fever and headache",
      "consultation_fee": 50.00
    }
  ]
}
```

### POST /api/patient/appointments
Book new appointment.

**Auth Required:** Yes

**Request Body:**
```json
{
  "doctor_id": 5,
  "chamber_id": 2,
  "appointment_date": "2024-12-15T10:00:00",
  "problem_description": "Regular checkup"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Appointment booked successfully",
  "appointment": {
    "id": 10,
    "appointment_date": "2024-12-15T10:00:00",
    "status": "pending"
  }
}
```

### GET /api/patient/prescriptions
Get patient's prescriptions.

**Auth Required:** Yes

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 5,
      "doctor_name": "Dr. Sarah Smith",
      "prescription_date": "2024-12-10",
      "diagnosis": "Upper Respiratory Infection",
      "medicines": [
        {
          "medicine_id": 20,
          "medicine_name": "Amoxicillin 500mg",
          "dosage": "1 tablet",
          "frequency": "twice daily",
          "duration": "7 days"
        }
      ],
      "instructions": "Rest and fluids"
    }
  ]
}
```

### GET /api/patient/medicine-orders
Get patient's medicine orders.

**Auth Required:** Yes

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 55,
      "order_date": "2024-12-10T15:00:00",
      "total_amount": 147.50,
      "delivery_address": "123 Main St",
      "delivery_type": "home_delivery",
      "order_status": "pending",
      "items": [
        {
          "medicine_name": "Amoxicillin 500mg",
          "quantity": 14,
          "unit_price": 0.50,
          "subtotal": 7.00
        }
      ]
    }
  ]
}
```

### POST /api/patient/medicine-orders
Place medicine order.

**Auth Required:** Yes

**Request Body:**
```json
{
  "delivery_address": "123 Main St",
  "delivery_type": "home_delivery",
  "items": [
    {
      "medicine_id": 20,
      "quantity": 14,
      "prescription_id": 5
    }
  ]
}
```

### GET /api/patient/notifications
Get patient notifications.

**Auth Required:** Yes

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Appointment Confirmed",
      "message": "Your appointment with Dr. Smith is confirmed",
      "type": "appointment",
      "is_read": false,
      "created_at": "2024-12-10T10:00:00"
    }
  ]
}
```

## 👨‍⚕️ Doctor Endpoints

### GET /api/doctor/profile
Get doctor profile.

**Auth Required:** Yes

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Dr. Sarah Smith",
    "email": "doctor@example.com",
    "specialization": "General Physician",
    "qualification": "MBBS, MD",
    "experience_years": 10,
    "phone": "1234567890",
    "consultation_fee": 50.00,
    "chambers": [
      {
        "id": 1,
        "name": "Downtown Clinic",
        "address": "456 Oak Ave",
        "city": "New York"
      }
    ]
  }
}
```

### POST /api/doctor/chambers
Add new chamber.

**Auth Required:** Yes

**Request Body:**
```json
{
  "name": "Suburb Clinic",
  "address": "321 Suburb St",
  "phone": "5555555555",
  "city": "Brooklyn",
  "state": "NY",
  "zipcode": "11201"
}
```

### POST /api/doctor/schedules
Add availability schedule.

**Auth Required:** Yes

**Request Body:**
```json
{
  "chamber_id": 1,
  "day_of_week": 1,
  "start_time": "09:00",
  "end_time": "17:00",
  "slot_duration": 30
}
```

### GET /api/doctor/appointments
Get doctor's appointments.

**Auth Required:** Yes

**Query Parameters:**
- `status`: pending, confirmed, completed
- `date`: YYYY-MM-DD

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "patient_name": "John Doe",
      "patient_phone": "1234567890",
      "appointment_date": "2024-12-15T10:00:00",
      "problem_description": "Fever and headache",
      "status": "confirmed"
    }
  ]
}
```

### PUT /api/doctor/appointments/<id>
Update appointment status.

**Auth Required:** Yes

**Request Body:**
```json
{
  "status": "confirmed",
  "notes": "Patient needs blood test"
}
```

### POST /api/doctor/prescriptions
Create prescription.

**Auth Required:** Yes

**Request Body:**
```json
{
  "appointment_id": 10,
  "diagnosis": "Upper Respiratory Infection",
  "medicines": [
    {
      "medicine_id": 20,
      "medicine_name": "Amoxicillin 500mg",
      "dosage": "1 tablet",
      "frequency": "twice daily",
      "duration": "7 days",
      "instructions": "Take after meals"
    }
  ],
  "instructions": "Rest and drink fluids",
  "follow_up_date": "2024-12-22"
}
```

### GET /api/doctor/search
Search for doctors.

**No Auth Required**

**Query Parameters:**
- `specialization`: Filter by specialization
- `city`: Filter by city
- `name`: Search by name

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Dr. Sarah Smith",
      "specialization": "General Physician",
      "qualification": "MBBS, MD",
      "experience_years": 10,
      "consultation_fee": 50.00,
      "chambers": [...]
    }
  ]
}
```

## 💊 Medical Store Endpoints

### GET /api/medical-store/profile
Get medical store profile.

**Auth Required:** Yes

### GET /api/medical-store/medicines
Get medicines inventory.

**Auth Required:** Yes

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 20,
      "name": "Amoxicillin 500mg",
      "category": "Antibiotic",
      "price": 0.50,
      "stock_quantity": 500,
      "requires_prescription": true,
      "expiry_date": "2025-06-30"
    }
  ]
}
```

### POST /api/medical-store/medicines
Add new medicine.

**Auth Required:** Yes

**Request Body:**
```json
{
  "name": "New Medicine",
  "description": "Description here",
  "manufacturer": "PharmaCorp",
  "category": "Antibiotic",
  "requires_prescription": true,
  "price": 1.50,
  "stock_quantity": 100,
  "expiry_date": "2025-12-31",
  "dosage_form": "Tablet"
}
```

### PUT /api/medical-store/medicines/<id>
Update medicine.

**Auth Required:** Yes

**Request Body:**
```json
{
  "price": 1.75,
  "stock_quantity": 150
}
```

### GET /api/medical-store/orders
Get store orders.

**Auth Required:** Yes

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 55,
      "patient_name": "John Doe",
      "order_date": "2024-12-10",
      "total_amount": 147.50,
      "order_status": "pending",
      "items": [...]
    }
  ]
}
```

### GET /api/medical-store/dashboard
Get store analytics.

**Auth Required:** Yes

**Response (200):**
```json
{
  "success": true,
  "data": {
    "total_medicines": 150,
    "total_orders": 45,
    "total_revenue": 5420.50,
    "low_stock_items": 8,
    "expiring_soon": 3,
    "recent_orders": [...]
  }
}
```

## 🔬 Lab Store Endpoints

### GET /api/lab-store/profile
Get lab store profile.

**Auth Required:** Yes

**Response (200):**
```json
{
  "id": 1,
  "name": "City Lab",
  "email": "lab@example.com",
  "phone": "1234567890",
  "address": "123 Lab St"
}
```

### GET /api/lab-store/tests
Get available lab tests.

**Auth Required:** Yes

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Complete Blood Count",
      "category": "Blood Test",
      "price": 25.00,
      "preparation": "No fasting required",
      "duration": 24
    }
  ]
}
```

### POST /api/lab-store/tests
Add new test.

**Auth Required:** Yes

**Request Body:**
```json
{
  "name": "Lipid Profile",
  "description": "Cholesterol levels",
  "category": "Blood Test",
  "price": 35.00,
  "preparation": "12-hour fasting",
  "duration": 48
}
```

### GET /api/lab-store/orders
Get lab test orders.

**Auth Required:** Yes

### PUT /api/lab-store/orders/<id>
Update test order status.

**Auth Required:** Yes

**Request Body:**
```json
{
  "status": "completed",
  "result": {
    "test_name": "CBC",
    "values": {
      "WBC": {"value": 7.5, "unit": "10^3/μL", "range": "4-11"}
    }
  }
}
```

### GET /api/lab-store/dashboard
Get lab analytics.

**Auth Required:** Yes

## 👨‍💼 Admin Endpoints

### GET /api/admin/home-delivery-orders
Get all home delivery orders.

**Auth Required:** Yes (Admin only)

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 55,
      "patient_name": "John Doe",
      "delivery_address": "123 Main St",
      "total_amount": 147.50,
      "order_status": "pending",
      "items": [...]
    }
  ]
}
```

### PUT /api/admin/orders/<id>
Update order status.

**Auth Required:** Yes (Admin only)

**Request Body:**
```json
{
  "order_status": "confirmed",
  "payment_status": "paid"
}
```

## 📊 Common Query Parameters

- `page`: Page number for pagination (default: 1)
- `per_page`: Items per page (default: 10, max: 100)
- `sort_by`: Field to sort by
- `order`: asc/desc

## ❌ Error Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Invalid data |
| 401 | Unauthorized - Invalid/missing token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found |
| 500 | Internal Server Error |

## 🔍 Testing with curl

```bash
# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"patient@test.com","password":"password123"}'

# Get profile (use token from login)
curl http://localhost:5000/api/patient/profile \
  -H "Authorization: Bearer YOUR_TOKEN"

# Book appointment
curl -X POST http://localhost:5000/api/patient/appointments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"doctor_id":1,"chamber_id":1,"appointment_date":"2024-12-15T10:00:00","problem_description":"Checkup"}'
```

---

**Next:** See [Authentication Guide](./authentication.md) for JWT implementation details.
