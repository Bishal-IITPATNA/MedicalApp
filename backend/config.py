import os
from datetime import timedelta

class Config:
    # Database
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///medical_app.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # JWT
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'your-secret-key-change-in-production'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    
    # App
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'your-app-secret-key'
    
    # Payment Gateway (placeholder - add actual credentials)
    RAZORPAY_KEY = os.environ.get('RAZORPAY_KEY')
    RAZORPAY_SECRET = os.environ.get('RAZORPAY_SECRET')
    
    # File Upload
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    UPLOAD_FOLDER = 'uploads'
