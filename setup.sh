#!/bin/bash

# Medical App Setup Script

echo "🏥 Medical App Setup Script"
echo "=============================="
echo ""

# Check if we're in the correct directory
if [ ! -f "medical_app_spec.txt" ]; then
    echo "❌ Error: Please run this script from the medical_app_v1 directory"
    exit 1
fi

echo "📦 Setting up Flask Backend..."
echo "------------------------------"

# Backend setup
cd backend

# Create virtual environment
echo "Creating Python virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env << EOF
DATABASE_URL=sqlite:///medical_app.db
JWT_SECRET_KEY=$(openssl rand -hex 32)
SECRET_KEY=$(openssl rand -hex 32)
FLASK_APP=run.py
FLASK_ENV=development
EOF
    echo "✅ .env file created"
fi

# Initialize database
echo "Initializing database..."
python run.py

cd ..

echo ""
echo "📱 Setting up Flutter Frontend..."
echo "--------------------------------"

# Frontend setup
cd frontend

# Get Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

echo ""
echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "🚀 To start the backend server:"
echo "   cd backend"
echo "   source venv/bin/activate"
echo "   python run.py"
echo ""
echo "🚀 To start the Flutter app:"
echo "   cd frontend"
echo "   flutter run"
echo ""
echo "📖 For more details, see README.md"
echo ""
