from app import db
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
import secrets

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False)  # patient, doctor, nurse, medical_store, lab_store, admin
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    reset_token = db.Column(db.String(100), unique=True, nullable=True)
    reset_token_expiry = db.Column(db.DateTime, nullable=True)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password, method='pbkdf2:sha256')
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def generate_reset_token(self):
        """Generate a password reset token valid for 1 hour"""
        self.reset_token = secrets.token_urlsafe(32)
        self.reset_token_expiry = datetime.utcnow() + timedelta(hours=1)
        return self.reset_token
    
    def verify_reset_token(self, token):
        """Verify if the reset token is valid and not expired"""
        if not self.reset_token or not self.reset_token_expiry:
            return False
        if self.reset_token != token:
            return False
        if datetime.utcnow() > self.reset_token_expiry:
            return False
        return True
    
    def clear_reset_token(self):
        """Clear the reset token after use"""
        self.reset_token = None
        self.reset_token_expiry = None
    
    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'role': self.role,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class Patient(db.Model):
    __tablename__ = 'patients'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True)
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(15))
    address = db.Column(db.Text)
    city = db.Column(db.String(50))
    state = db.Column(db.String(50))
    pincode = db.Column(db.String(10))
    date_of_birth = db.Column(db.Date)
    gender = db.Column(db.String(10))
    blood_group = db.Column(db.String(5))
    
    # Relationships
    user = db.relationship('User', backref='patient_profile', lazy=True)
    appointments = db.relationship('Appointment', backref='patient', lazy=True)
    medicine_orders = db.relationship('MedicineOrder', backref='patient', lazy=True)
    lab_orders = db.relationship('LabTestOrder', backref='patient', lazy=True)
    notifications = db.relationship('Notification', backref='patient', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'phone': self.phone,
            'address': self.address,
            'city': self.city,
            'state': self.state,
            'pincode': self.pincode,
            'date_of_birth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'gender': self.gender,
            'blood_group': self.blood_group
        }

class Doctor(db.Model):
    __tablename__ = 'doctors'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True)
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(15))
    specialty = db.Column(db.String(100))
    qualification = db.Column(db.String(200))
    experience_years = db.Column(db.Integer)
    consultation_fee = db.Column(db.Float, default=0.0)
    address = db.Column(db.Text)
    city = db.Column(db.String(50))
    state = db.Column(db.String(50))
    pincode = db.Column(db.String(10))
    rating = db.Column(db.Float, default=0.0)
    
    # Availability
    available_days = db.Column(db.String(200))  # JSON string of available days
    available_from = db.Column(db.Time)
    available_to = db.Column(db.Time)
    
    # Relationships
    user = db.relationship('User', backref='doctor_profile', lazy=True)
    appointments = db.relationship('Appointment', backref='doctor', lazy=True)
    prescriptions = db.relationship('Prescription', backref='doctor', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'phone': self.phone,
            'specialty': self.specialty,
            'qualification': self.qualification,
            'experience_years': self.experience_years,
            'consultation_fee': self.consultation_fee,
            'address': self.address,
            'city': self.city,
            'state': self.state,
            'pincode': self.pincode,
            'rating': self.rating,
            'available_days': self.available_days,
            'available_from': self.available_from.isoformat() if self.available_from else None,
            'available_to': self.available_to.isoformat() if self.available_to else None
        }

class Nurse(db.Model):
    __tablename__ = 'nurses'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True)
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(15))
    qualification = db.Column(db.String(200))
    experience_years = db.Column(db.Integer)
    consultation_fee = db.Column(db.Float, default=0.0)
    address = db.Column(db.Text)
    city = db.Column(db.String(50))
    state = db.Column(db.String(50))
    pincode = db.Column(db.String(10))
    rating = db.Column(db.Float, default=0.0)
    
    # Availability
    available_days = db.Column(db.String(200))  # JSON string
    available_from = db.Column(db.Time)
    available_to = db.Column(db.Time)
    
    # Relationships
    user = db.relationship('User', backref='nurse_profile', lazy=True)
    appointments = db.relationship('Appointment', backref='nurse', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'phone': self.phone,
            'qualification': self.qualification,
            'experience_years': self.experience_years,
            'consultation_fee': self.consultation_fee,
            'address': self.address,
            'city': self.city,
            'state': self.state,
            'pincode': self.pincode,
            'rating': self.rating,
            'available_days': self.available_days,
            'available_from': self.available_from.isoformat() if self.available_from else None,
            'available_to': self.available_to.isoformat() if self.available_to else None
        }

class MedicalStore(db.Model):
    __tablename__ = 'medical_stores'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True)
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(15))
    license_number = db.Column(db.String(50))
    address = db.Column(db.Text)
    city = db.Column(db.String(50))
    state = db.Column(db.String(50))
    pincode = db.Column(db.String(10))
    rating = db.Column(db.Float, default=0.0)
    
    # Relationships
    user = db.relationship('User', backref='medical_store_profile', lazy=True)
    medicines = db.relationship('Medicine', backref='store', lazy=True)
    orders = db.relationship('MedicineOrder', foreign_keys='MedicineOrder.store_id', backref='store', lazy=True)
    pending_offers = db.relationship('MedicineOrder', foreign_keys='MedicineOrder.current_store_id', backref='current_store', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'phone': self.phone,
            'license_number': self.license_number,
            'address': self.address,
            'city': self.city,
            'state': self.state,
            'pincode': self.pincode,
            'rating': self.rating
        }

class LabStore(db.Model):
    __tablename__ = 'lab_stores'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True)
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(15))
    license_number = db.Column(db.String(50))
    address = db.Column(db.Text)
    city = db.Column(db.String(50))
    state = db.Column(db.String(50))
    pincode = db.Column(db.String(10))
    rating = db.Column(db.Float, default=0.0)
    
    # Relationships
    user = db.relationship('User', backref='lab_store_profile', lazy=True)
    lab_tests = db.relationship('LabTest', backref='lab', lazy=True)
    test_orders = db.relationship('LabTestOrder', backref='lab', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'phone': self.phone,
            'license_number': self.license_number,
            'address': self.address,
            'city': self.city,
            'state': self.state,
            'pincode': self.pincode,
            'rating': self.rating
        }

class Admin(db.Model):
    __tablename__ = 'admins'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True)
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(15))
    
    # Relationships
    user = db.relationship('User', backref='admin_profile', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'phone': self.phone
        }
