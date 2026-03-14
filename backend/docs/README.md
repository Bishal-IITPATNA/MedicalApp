# Medical App - Complete Healthcare Management System

## Overview

A comprehensive healthcare management system built with Flask (Backend) and Flutter (Frontend) that facilitates:

- **Patient Management**: Registration, appointments, medical records
- **Doctor Portal**: Patient consultations, appointment management, prescriptions
- **Medical Store**: Medicine inventory, order fulfillment, delivery management
- **Lab Services**: Lab test bookings, sample collection, report generation
- **Admin Panel**: System administration, user management, analytics

## System Architecture

### Backend (Flask)
- **Framework**: Flask 3.0.x with SQLAlchemy 2.0.x
- **Database**: SQLite (development), PostgreSQL (production ready)
- **Authentication**: JWT-based with role-based access control
- **API**: RESTful APIs with comprehensive endpoints

### Frontend (Flutter)
- **Framework**: Flutter 3.x with Material Design
- **State Management**: Provider pattern
- **Navigation**: Named routes with role-based redirection
- **HTTP Client**: dart:http with custom API service

## Features

### Core Features
1. **Multi-Role Authentication System**
   - Email/Mobile login with automatic role detection
   - Multi-role users (e.g., Doctor + Patient)
   - JWT token-based authentication
   - Role-based dashboard redirection

2. **Patient Management**
   - Patient registration and profile management
   - Appointment booking with doctors
   - Medical history tracking
   - Prescription management
   - Lab test booking and reports
   - Medicine ordering with home delivery

3. **Doctor Portal**
   - Doctor profile with chamber management
   - Appointment scheduling and management
   - Patient consultation records
   - Prescription writing
   - Availability management

4. **Medical Store Management**
   - Medicine inventory management
   - Order processing and fulfillment
   - Delivery management with OTP verification
   - Stock tracking and low stock alerts
   - Revenue analytics

5. **Lab Services**
   - Lab test catalog management
   - Test booking with multiple labs
   - Sample collection scheduling
   - OTP-based sample collection verification
   - Report generation and delivery

6. **Admin Panel**
   - User management across all roles
   - System analytics and reporting
   - Content management
   - Order oversight and management

7. **Notification System**
   - Real-time notifications for all users
   - SMS/Email integration ready
   - Push notification support
   - Notification history and management

## Setup Instructions

### Backend Setup

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd medical_app_v1/backend
   ```

2. **Create Virtual Environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Environment Configuration**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Database Setup**
   ```bash
   flask db init
   flask db migrate -m "Initial migration"
   flask db upgrade
   ```

6. **Create Sample Data**
   ```bash
   python create_sample_data.py
   python create_lab_data.py
   ```

7. **Run the Server**
   ```bash
   python run.py
   # Server runs on http://localhost:5001
   ```

### Frontend Setup

1. **Prerequisites**
   - Flutter SDK 3.x+
   - Dart SDK 3.x+
   - Chrome/Edge browser for web development

2. **Setup Flutter Project**
   ```bash
   cd medical_app_v1/frontend
   flutter pub get
   ```

3. **Configure API Endpoints**
   - Edit `lib/utils/api_constants.dart`
   - Set backend URL (default: http://localhost:5001)

4. **Run the App**
   ```bash
   flutter run -d web-server --web-port=8080
   # App runs on http://localhost:8080
   ```

## Default Users

After running sample data creation, these users are available:

| Role | Email | Password | Mobile | Description |
|------|-------|----------|--------|--------------|
| Admin | admin@medical.com | password123 | - | System administrator |
| Patient | testpatient2@medical.com | password123 | 8888888888 | Sample patient |
| Doctor | testdoctor1@medical.com | password123 | 9999999999 | Test Doctor 1 |
| Doctor | testdoctor2@medical.com | password123 | 9999999998 | Test Doctor 2 |
| Medical Store | testmedical@store.com | password123 | 7777777777 | Medical store owner |
| Lab Store | pathlab@example.com | password123 | 9876543210 | PathLab Diagnostics |

## Database Schema

### Core Tables
- `users` - Base user authentication
- `patients` - Patient profiles and medical info
- `doctors` - Doctor profiles and specializations
- `medical_stores` - Medical store information
- `lab_stores` - Laboratory information

### Transaction Tables
- `appointments` - Doctor-patient appointments
- `medicine_orders` - Medicine purchase orders
- `lab_test_orders` - Lab test bookings
- `notifications` - System notifications

### Inventory Tables
- `medicines` - Medicine catalog
- `lab_tests` - Lab test catalog
- `chambers` - Doctor chamber information

## API Documentation

See `API_DOCUMENTATION.md` for detailed API endpoints, request/response formats, and authentication requirements.

## Database Operations

See `DATABASE_QUERIES.md` for common database queries, maintenance tasks, and troubleshooting.

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License

This project is licensed under the MIT License.

## Support

For support and questions:
- Email: support@medicalapp.com
- GitHub Issues: [Repository Issues]
- Documentation: See docs/ folder

## Version History

- **v1.0.0** - Initial release with core functionality
- **v1.1.0** - Added lab services and enhanced notifications
- **v1.2.0** - Multi-role authentication and improved UI
