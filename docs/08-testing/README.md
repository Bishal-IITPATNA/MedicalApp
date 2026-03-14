# Testing Guide

## Overview
Testing strategy and guidelines for Seevak Care application.

## Testing Levels

### 1. Unit Testing

#### Backend (Python/Flask)
```bash
cd backend
python -m pytest tests/ -v
```

#### Frontend (Flutter)
```bash
cd frontend
flutter test
```

### 2. Integration Testing

#### API Testing
- Test API endpoints with Postman/curl
- Validate request/response formats
- Check error handling

#### Database Testing  
- Test database operations
- Validate data integrity
- Check constraints and relationships

### 3. E2E Testing

#### Web Testing
- User journey testing
- Cross-browser compatibility
- Mobile responsiveness

## Test Data Management

### Development Database
- Use `backend/scripts/create_test_user.py` to create test users
- Use `backend/scripts/populate_medicines.py` for test medicines
- Use `backend/scripts/create_lab_data.py` for lab test data

### Test Users
- **Patient**: `patient@test.com` / `password123`
- **Doctor**: `doctor@test.com` / `password123`
- **Lab Store**: `lab@test.com` / `password123`
- **Medical Store**: `store@test.com` / `password123`

## Testing Checklist

### Authentication
- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Registration flow
- [ ] Password reset flow
- [ ] Token expiration handling

### Core Features
- [ ] Appointment booking
- [ ] Prescription management
- [ ] Lab test ordering
- [ ] Medicine ordering
- [ ] Profile management

### Error Scenarios
- [ ] Network connectivity issues
- [ ] Server errors (500)
- [ ] Validation errors (400)
- [ ] Unauthorized access (401)

## Automated Testing

### CI/CD Pipeline
```yaml
# Example GitHub Actions workflow
name: Test Suite
on: [push, pull_request]
jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.13
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: python -m pytest
        
  frontend-tests:
    runs-on: ubuntu-latest  
    steps:
      - uses: actions/checkout@v2
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
      - name: Run tests
        run: flutter test
```

## Performance Testing

### Load Testing
- Test API endpoints under load
- Database performance testing
- Frontend responsiveness testing

### Tools
- **Backend**: locust, pytest-benchmark
- **Frontend**: Flutter DevTools, Lighthouse
- **API**: Postman, Artillery

## Manual Testing Guide

### Test Scenarios
1. **User Registration & Login**
   - Register new user
   - Login with credentials
   - Test role selection
   
2. **Appointment Management**
   - Book appointment
   - View appointments
   - Cancel appointment
   
3. **Lab Test Ordering**
   - Select lab tests
   - Choose collection method
   - Complete booking
   - View order status

4. **Medicine Ordering**
   - Add medicines to cart
   - Complete order
   - Track delivery

## Bug Reporting

### Bug Report Template
```
**Title**: Brief description
**Environment**: Web/Mobile, Browser, OS
**Steps to Reproduce**: 
1. Step 1
2. Step 2
3. Step 3

**Expected Result**: What should happen
**Actual Result**: What actually happened
**Screenshots**: If applicable
**Additional Info**: Any other relevant details
```

## Quality Assurance

### Code Quality
- Use linters (eslint for Dart, pylint for Python)
- Follow coding standards
- Code review process

### Security Testing
- Authentication testing
- Authorization testing
- Input validation
- SQL injection prevention
- XSS prevention