from app import db
from datetime import datetime, timedelta
import random
import string

class OTPVerification(db.Model):
    """Model for storing OTP verification data during registration"""
    __tablename__ = 'otp_verification'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    name = db.Column(db.String(100), nullable=False)
    role = db.Column(db.String(50), nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    
    # OTP fields
    email_otp = db.Column(db.String(6), nullable=False)
    phone_otp = db.Column(db.String(6), nullable=True)
    
    # Verification status
    email_verified = db.Column(db.Boolean, default=False)
    phone_verified = db.Column(db.Boolean, default=False)
    
    # Additional registration data (stored as JSON string)
    additional_data = db.Column(db.Text)  # Store other form fields as JSON
    
    # Expiry and attempts
    expires_at = db.Column(db.DateTime, nullable=False)
    email_attempts = db.Column(db.Integer, default=0)
    phone_attempts = db.Column(db.Integer, default=0)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __init__(self, email, phone, name, role, password_hash, additional_data=None):
        self.email = email
        self.phone = phone
        self.name = name
        self.role = role
        self.password_hash = password_hash
        self.additional_data = additional_data
        
        # Generate OTPs
        self.email_otp = self.generate_otp()
        if phone:
            self.phone_otp = self.generate_otp()
        
        # Set expiry (10 minutes)
        self.expires_at = datetime.utcnow() + timedelta(minutes=10)
    
    @staticmethod
    def generate_otp():
        """Generate a 6-digit OTP"""
        return ''.join(random.choices(string.digits, k=6))
    
    def is_expired(self):
        """Check if OTP has expired"""
        return datetime.utcnow() > self.expires_at
    
    def is_verified(self):
        """Check if either email or phone is verified"""
        return self.email_verified or self.phone_verified
    
    def verify_email_otp(self, otp):
        """Verify email OTP"""
        if self.is_expired():
            return False, "OTP has expired"
        
        if self.email_attempts >= 5:
            return False, "Too many attempts. Please request a new OTP"
        
        self.email_attempts += 1
        
        if self.email_otp == otp:
            self.email_verified = True
            return True, "Email verified successfully"
        
        return False, "Invalid OTP"
    
    def verify_phone_otp(self, otp):
        """Verify phone OTP"""
        if not self.phone_otp:
            return False, "Phone OTP not available"
        
        if self.is_expired():
            return False, "OTP has expired"
        
        if self.phone_attempts >= 5:
            return False, "Too many attempts. Please request a new OTP"
        
        self.phone_attempts += 1
        
        if self.phone_otp == otp:
            self.phone_verified = True
            return True, "Phone verified successfully"
        
        return False, "Invalid OTP"
    
    def regenerate_otp(self, otp_type='both'):
        """Regenerate OTP and reset expiry"""
        if otp_type in ['email', 'both']:
            self.email_otp = self.generate_otp()
            self.email_attempts = 0
            self.email_verified = False
        
        if otp_type in ['phone', 'both'] and self.phone:
            self.phone_otp = self.generate_otp()
            self.phone_attempts = 0
            self.phone_verified = False
        
        # Extend expiry by 10 minutes
        self.expires_at = datetime.utcnow() + timedelta(minutes=10)
    
    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'phone': self.phone,
            'name': self.name,
            'role': self.role,
            'email_verified': self.email_verified,
            'phone_verified': self.phone_verified,
            'expires_at': self.expires_at.isoformat(),
            'created_at': self.created_at.isoformat()
        }