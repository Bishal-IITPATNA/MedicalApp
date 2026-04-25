# Medical App API Documentation

## Base URL
```
Development: http://localhost:5001
Production: https://your-domain.com
```

## Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Response Format

All API responses follow this standard format:

```json
{
  "success": true|false,
  "data": {...},
  "error": "Error message",
  "message": "Success message"
}
```

## Authentication Endpoints

### Check User Roles
```http
POST /api/auth/check-roles
Content-Type: application/json

{
  "login_id": "user@example.com" // Email or mobile number
}
```

**Response:**
```json
{
  "success": true,
  "available_roles": ["patient", "doctor"],
  "user_id": 123
}
```

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "login_id": "user@example.com", // Email or mobile
  "password": "password123",
  "role": "patient" // Optional, defaults to primary role
}
```

**Response:**
```json
{
  "success": true,
  "access_token": "jwt-token",
  "refresh_token": "refresh-token",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "patient",
    "selected_role": "patient"
  }
}
```

### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "role": "patient",
  "name": "John Doe",
  "phone": "1234567890"
}
```

### Refresh Token
```http
POST /api/auth/refresh
Authorization: Bearer <refresh-token>
```

### Logout
```http
POST /api/auth/logout
Authorization: Bearer <access-token>
```

## Patient Endpoints

### Get Patient Profile
```http
GET /api/patient/profile
Authorization: Bearer <patient-token>
```

### Update Patient Profile
```http
PUT /api/patient/profile
Authorization: Bearer <patient-token>
Content-Type: application/json

{
  "name": "Updated Name",
  "phone": "9876543210",
  "address": "New Address",
  "city": "City Name"
}
```

### Search Doctors
```http
GET /api/patient/doctors/search?name=doctor&specialization=cardiology
Authorization: Bearer <patient-token>
```

### Book Appointment
```http
POST /api/patient/appointments/book
Authorization: Bearer <patient-token>
Content-Type: application/json

{
  "doctor_id": 1,
  "chamber_id": 1,
  "appointment_date": "2025-12-30",
  "appointment_time": "10:00",
  "reason": "Regular checkup"
}
```

### Get Appointments
```http
GET /api/patient/appointments?status=confirmed&limit=10
Authorization: Bearer <patient-token>
```

### Search Medicines
```http
GET /api/patient/medicines/search?name=paracetamol&category=painkiller
Authorization: Bearer <patient-token>
```

### Place Medicine Order
```http
POST /api/patient/medicines/order
Authorization: Bearer <patient-token>
Content-Type: application/json

{
  "items": [
    {
      "medicine_id": 1,
      "quantity": 2
    }
  ],
  "delivery_type": "home", // "home" or "pickup"
  "delivery_address": "123 Main St"
}
```

### Search Lab Tests
```http
GET /api/patient/lab-tests/search?test_name=blood&lab_id=1
Authorization: Bearer <patient-token>
```

### Book Lab Tests
```http
POST /api/patient/lab-tests/book
Authorization: Bearer <patient-token>
Content-Type: application/json

{
  "lab_id": 2,
  "test_ids": [1, 2, 3],
  "test_date": "2025-12-30",
  "test_time": "09:00"
}
```

### Get Lab Stores
```http
GET /api/patient/lab-stores
Authorization: Bearer <patient-token>
```

## Doctor Endpoints

### Get Doctor Profile
```http
GET /api/doctor/profile
Authorization: Bearer <doctor-token>
```

### Update Doctor Profile
```http
PUT /api/doctor/profile
Authorization: Bearer <doctor-token>
Content-Type: application/json

{
  "name": "Dr. Updated Name",
  "specialization": "Cardiology",
  "experience_years": 15,
  "consultation_fee": 800
}
```

### Get Appointments
```http
GET /api/doctor/appointments?date=2025-12-30&status=confirmed
Authorization: Bearer <doctor-token>
```

### Update Appointment Status
```http
PUT /api/doctor/appointments/{appointment_id}/status
Authorization: Bearer <doctor-token>
Content-Type: application/json

{
  "status": "completed",
  "notes": "Patient is stable"
}
```

### Manage Chambers
```http
GET /api/doctor/chambers
POST /api/doctor/chambers
PUT /api/doctor/chambers/{chamber_id}
DELETE /api/doctor/chambers/{chamber_id}
Authorization: Bearer <doctor-token>
```

## Medical Store Endpoints

### Get Store Profile
```http
GET /api/medical-store/profile
Authorization: Bearer <store-token>
```

### Get Orders
```http
GET /api/medical-store/orders?status=pending&limit=20
Authorization: Bearer <store-token>
```

### Update Order Status
```http
PUT /api/medical-store/orders/{order_id}/status
Authorization: Bearer <store-token>
Content-Type: application/json

{
  "status": "processing",
  "estimated_delivery": "2025-12-31"
}
```

### Manage Inventory
```http
GET /api/medical-store/inventory
POST /api/medical-store/inventory
PUT /api/medical-store/inventory/{medicine_id}
Authorization: Bearer <store-token>
```

## Lab Store Endpoints

### Get Lab Profile
```http
GET /api/lab-store/profile
Authorization: Bearer <lab-token>
```

### Get Lab Orders
```http
GET /api/lab-store/orders?status=pending&date=2025-12-30
Authorization: Bearer <lab-token>
```

### Update Test Results
```http
PUT /api/lab-store/orders/{order_id}/results
Authorization: Bearer <lab-token>
Content-Type: application/json

{
  "results": {
    "hemoglobin": "12.5 g/dL",
    "wbc_count": "7000/μL"
  },
  "report_url": "https://example.com/report.pdf"
}
```

## Admin Endpoints

### Dashboard Stats
```http
GET /api/admin/dashboard
Authorization: Bearer <admin-token>
```

### Manage Users
```http
GET /api/admin/users?role=patient&limit=50
POST /api/admin/users
PUT /api/admin/users/{user_id}
DELETE /api/admin/users/{user_id}
Authorization: Bearer <admin-token>
```

### System Analytics
```http
GET /api/admin/analytics?start_date=2025-12-01&end_date=2025-12-31
Authorization: Bearer <admin-token>
```

## Notification Endpoints

### Get Notifications
```http
GET /api/notifications?unread_only=true&limit=20
Authorization: Bearer <user-token>
```

### Mark as Read
```http
PUT /api/notifications/{notification_id}/read
Authorization: Bearer <user-token>
```

### Mark All as Read
```http
PUT /api/notifications/read-all
Authorization: Bearer <user-token>
```

## Error Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Invalid/missing token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 409 | Conflict - Resource already exists |
| 422 | Unprocessable Entity - Validation error |
| 500 | Internal Server Error |

## Rate Limiting

API endpoints are rate-limited:
- Authentication endpoints: 5 requests per minute
- General endpoints: 100 requests per minute
- File upload endpoints: 10 requests per minute

## Pagination

For endpoints that return lists, use these query parameters:
- `limit`: Number of items (default: 20, max: 100)
- `offset`: Number of items to skip (default: 0)
- `page`: Page number (alternative to offset)

Example:
```http
GET /api/patient/appointments?limit=10&offset=20
```

## Filtering and Sorting

Many endpoints support filtering and sorting:
- `sort_by`: Field to sort by (e.g., `created_at`, `name`)
- `sort_order`: `asc` or `desc` (default: `desc`)
- Filter by field values using query parameters

Example:
```http
GET /api/admin/users?role=patient&sort_by=created_at&sort_order=asc
```

## Webhooks

Webhooks are available for real-time updates:
- Appointment status changes
- Order status updates
- Payment confirmations
- Lab report availability

Contact admin to configure webhook endpoints.
