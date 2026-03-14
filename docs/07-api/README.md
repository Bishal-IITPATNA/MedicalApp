# API Documentation

## Overview
Seevak Care REST API provides endpoints for healthcare management system functionality.

**Base URL**: `http://localhost:5001/api`

## Authentication
All API endpoints (except login/register) require JWT token authentication.

### Headers
```
Authorization: Bearer <your-jwt-token>
Content-Type: application/json
```

## Core Endpoints

### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration 
- `POST /auth/refresh` - Refresh JWT token
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password with token

### User Management
- `GET /user/profile` - Get user profile
- `PUT /user/profile` - Update user profile
- `POST /user/change-password` - Change password

### Patient Endpoints
- `GET /patient/dashboard` - Patient dashboard data
- `GET /patient/appointments` - Patient appointments
- `GET /patient/prescriptions` - Patient prescriptions
- `GET /patient/lab-orders` - Patient lab test orders

### Doctor Endpoints
- `GET /doctor/dashboard` - Doctor dashboard data
- `GET /doctor/patients` - Doctor's patients
- `GET /doctor/appointments` - Doctor's appointments
- `POST /doctor/prescriptions` - Create prescription

### Lab Store Endpoints
- `GET /lab-store/orders` - Lab test orders
- `PUT /lab-store/orders/<id>` - Update order status
- `GET /lab-store/tests` - Available lab tests
- `POST /lab-store/tests` - Add new test

### Medical Store Endpoints
- `GET /medical-store/orders` - Medicine orders
- `PUT /medical-store/orders/<id>` - Update order status
- `GET /medical-store/medicines` - Available medicines

## Response Format

### Success Response
```json
{
    "success": true,
    "data": {...},
    "message": "Operation successful"
}
```

### Error Response
```json
{
    "success": false,
    "error": "Error description",
    "code": "ERROR_CODE"
}
```

## Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

For detailed endpoint documentation, see individual module guides in the backend documentation.