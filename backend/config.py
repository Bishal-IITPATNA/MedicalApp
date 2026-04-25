import os
from datetime import timedelta

class Config:
    # Database Configuration
    # Use Azure SQL Database in production, SQLite for development
    DATABASE_URL = os.environ.get('DATABASE_URL')
    if DATABASE_URL and DATABASE_URL.startswith('postgresql://'):
        DATABASE_URL = DATABASE_URL.replace('postgresql://', 'postgresql+psycopg2://', 1)
    
    SQLALCHEMY_DATABASE_URI = DATABASE_URL or 'sqlite:///medical_app.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # JWT Configuration
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'dev-secret-key-change-in-production'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    
    # App Configuration
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-app-secret-key'
    
    # Azure App Service Configuration
    # These are automatically set by Azure
    WEBSITE_SITE_NAME = os.environ.get('WEBSITE_SITE_NAME')
    WEBSITE_HOSTNAME = os.environ.get('WEBSITE_HOSTNAME')
    
    # Environment Detection
    ENV = 'production' if WEBSITE_SITE_NAME else 'development'
    DEBUG = ENV == 'development'
    
    # Payment Gateway
    RAZORPAY_KEY = os.environ.get('RAZORPAY_KEY')
    RAZORPAY_SECRET = os.environ.get('RAZORPAY_SECRET')
    
    # File Upload Configuration
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    UPLOAD_FOLDER = os.environ.get('UPLOAD_FOLDER', '/tmp/uploads') if ENV == 'production' else 'uploads'
