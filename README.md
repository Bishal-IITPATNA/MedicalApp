# Seevak Care - Healthcare Management System

A comprehensive healthcare management system built with Flask (Backend) and Flutter (Frontend) that facilitates patient care, doctor consultations, medical store operations, and lab services.

## Features

- **Multi-Role Authentication**: Automatic role detection with support for users with multiple roles
- **Patient Management**: Registration, appointments, medical records, medicine orders, lab tests
- **Doctor Portal**: Patient consultations, appointment management, chamber management
- **Medical Store**: Medicine inventory, order fulfillment, delivery tracking
- **Lab Services**: Lab test bookings, sample collection, report generation
- **Admin Panel**: System administration, user management, analytics
- **Real-time Notifications**: OTP verification, order updates, appointment reminders.

## Quick Start

### Backend Setup
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
flask db upgrade
python create_sample_data.py
python create_lab_data.py
python run.py
```

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run -d web-server --web-port=8080
```

### Access the Application
- **Backend API**: http://localhost:5001
- **Frontend App**: http://localhost:8080

### Default Users
| Role | Email/Mobile | Password |
|------|--------------|----------|
| Admin | admin@medical.com | password123 |
| Patient | testpatient2@medical.com | password123 |
| Doctor | testdoctor1@medical.com | password123 |
| Medical Store | testmedical@store.com | password123 |
| Lab Store | pathlab@example.com | password123 |

## Documentation

Detailed documentation is available in the `backend/docs/` folder:

- **[README.md](backend/docs/README.md)** - Complete project overview and setup
- **[API_DOCUMENTATION.md](backend/docs/API_DOCUMENTATION.md)** - REST API endpoints and usage
- **[DATABASE_QUERIES.md](backend/docs/DATABASE_QUERIES.md)** - Database queries and maintenance
- **[ARCHITECTURE.md](backend/docs/ARCHITECTURE.md)** - System architecture and design
- **[DEPLOYMENT_GUIDE.md](backend/docs/DEPLOYMENT_GUIDE.md)** - Production deployment guide

## Technology Stack

### Backend
- **Framework**: Flask 3.0.x with SQLAlchemy 2.0.x
- **Database**: SQLite (dev) / PostgreSQL (prod)
- **Authentication**: JWT with role-based access control
- **API**: RESTful endpoints with comprehensive validation

### Frontend
- **Framework**: Flutter 3.x with Material Design
- **State Management**: Provider pattern
- **HTTP Client**: Custom API service with error handling
- **Navigation**: Named routes with role-based redirection

## Key Features Implemented

### Authentication System
- Email/Mobile number login with automatic role detection
- Multi-role support (users can be both doctor and patient)
- JWT token-based authentication with refresh tokens
- Role-based dashboard redirection

### Patient Features
- Complete registration with medical history
- Doctor search and appointment booking
- Medicine ordering with home delivery
- Lab test booking with multiple labs
- Digital prescriptions and medical records

### Doctor Features
- Professional profile with chamber management
- Appointment scheduling and patient management
- Prescription writing and medical consultations
- Availability management

### Medical Store Features
- Medicine inventory management
- Order processing with OTP verification
- Delivery tracking and management
- Revenue analytics and reporting

### Lab Services
- Comprehensive test catalog
- Multi-lab booking system
- Sample collection scheduling
- OTP-based verification system

### Admin Panel
- User management across all roles
- System analytics and reporting
- Order oversight and management
- Content and inventory management

## API Highlights

- **Authentication**: `/api/auth/check-roles`, `/api/auth/login`
- **Patient Services**: `/api/patient/appointments`, `/api/patient/medicines`
- **Doctor Portal**: `/api/doctor/appointments`, `/api/doctor/chambers`
- **Medical Store**: `/api/medical-store/orders`, `/api/medical-store/inventory`
- **Lab Services**: `/api/patient/lab-tests`, `/api/lab-store/orders`
- **Admin Panel**: `/api/admin/dashboard`, `/api/admin/users`

## Development Status

✅ **Completed Features:**
- Multi-role authentication system
- Patient registration and profile management
- Doctor appointment booking system
- Medicine ordering with delivery tracking
- Lab test booking with OTP verification
- Real-time notification system
- Admin panel with user management
- Comprehensive API documentation

🔄 **In Development:**
- Payment gateway integration
- Mobile app versions (iOS/Android)
- Advanced reporting and analytics
- Telemedicine video consultations

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:
- 📧 Email: support@medicalapp.com
- 📖 Documentation: [backend/docs/](backend/docs/)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/medical_app_v1/issues)

## Acknowledgments

- Flask and Flutter communities for excellent documentation
- Contributors who helped shape the project architecture
- Healthcare professionals who provided domain expertise
