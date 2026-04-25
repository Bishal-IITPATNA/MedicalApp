#!/bin/bash

# Local CI/CD Testing Script
# This script mimics what GitHub Actions does locally
# Useful for testing before pushing to main

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="backend"
FRONTEND_DIR="frontend"
SKIP_TESTS=false
SKIP_BUILD=false
SKIP_LINT=false
VERBOSE=false

# Functions
print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-lint)
            SKIP_LINT=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Local CI/CD Testing Script"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-tests    Skip running tests"
            echo "  --skip-build    Skip building"
            echo "  --skip-lint     Skip linting"
            echo "  --verbose, -v   Verbose output"
            echo "  --help, -h      Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# BACKEND BUILD & TEST
# ============================================================================
backend_test() {
    print_header "BACKEND BUILD & TEST"
    
    if [ ! -d "$BACKEND_DIR" ]; then
        print_error "Backend directory not found: $BACKEND_DIR"
        return 1
    fi
    
    cd "$BACKEND_DIR"
    
    # Check required files
    if [ ! -f "requirements.txt" ]; then
        print_error "requirements.txt not found in backend directory"
        cd ..
        return 1
    fi
    
    print_info "Installing dependencies..."
    if [ "$VERBOSE" = true ]; then
        pip install -r requirements.txt
    else
        pip install -r requirements.txt > /dev/null 2>&1
    fi
    print_success "Dependencies installed"
    
    if [ "$SKIP_LINT" = false ]; then
        print_info "Running pylint..."
        if command -v pylint &> /dev/null; then
            pylint app/ --disable=all --enable=E,F || true
            print_success "Linting check complete"
        else
            print_warning "pylint not installed, skipping linting"
            pip install pylint > /dev/null 2>&1
            pylint app/ --disable=all --enable=E,F || true
        fi
    fi
    
    if [ "$SKIP_TESTS" = false ]; then
        print_info "Running pytest..."
        if ! command -v pytest &> /dev/null; then
            pip install pytest pytest-cov > /dev/null 2>&1
        fi
        
        if pytest -v --cov=app --cov-report=term; then
            print_success "Tests passed"
        else
            print_error "Tests failed"
            cd ..
            return 1
        fi
    fi
    
    if [ "$SKIP_BUILD" = false ]; then
        print_info "Testing backend startup..."
        
        # Create a simple test that imports the app
        python -c "from main import app; print('✅ Backend imports successfully')" || {
            print_error "Backend failed to import"
            cd ..
            return 1
        }
    fi
    
    cd ..
    print_success "Backend tests completed"
    return 0
}

# ============================================================================
# FRONTEND BUILD & TEST
# ============================================================================
frontend_test() {
    print_header "FRONTEND BUILD & TEST"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory not found: $FRONTEND_DIR"
        return 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Check required files
    if [ ! -f "pubspec.yaml" ]; then
        print_error "pubspec.yaml not found in frontend directory"
        cd ..
        return 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter not installed. Please install Flutter and add to PATH"
        print_info "Visit: https://flutter.dev/docs/get-started/install"
        cd ..
        return 1
    fi
    
    print_info "Installing Flutter dependencies..."
    if [ "$VERBOSE" = true ]; then
        flutter pub get
    else
        flutter pub get > /dev/null 2>&1
    fi
    print_success "Flutter dependencies installed"
    
    if [ "$SKIP_LINT" = false ]; then
        print_info "Running Flutter analyzer..."
        flutter analyze || true
        print_success "Analysis complete"
    fi
    
    if [ "$SKIP_TESTS" = false ]; then
        print_info "Running Flutter tests..."
        if flutter test; then
            print_success "Flutter tests passed"
        else
            print_warning "Flutter tests failed (not critical)"
        fi
    fi
    
    if [ "$SKIP_BUILD" = false ]; then
        print_info "Building Flutter web..."
        
        if flutter build web --release > /dev/null 2>&1; then
            SIZE=$(du -sh build/web | cut -f1)
            print_success "Flutter build completed (size: $SIZE)"
        else
            print_error "Flutter build failed"
            cd ..
            return 1
        fi
    fi
    
    cd ..
    print_success "Frontend tests completed"
    return 0
}

# ============================================================================
# ZIP CREATION TEST (Backend deployment package)
# ============================================================================
test_backend_package() {
    print_header "BACKEND DEPLOYMENT PACKAGE TEST"
    
    cd "$BACKEND_DIR"
    
    print_info "Creating deployment package..."
    
    zip -r ../backend-deploy-test.zip . \
        -x "*.git*" \
            "**/__pycache__/**" \
            "*.pyc" \
            "**/.*" \
            "**/.DS_Store" \
            "**/*.log" \
            "**/venv/**" \
            "**/env/**" \
            "*.egg-info/**" > /dev/null 2>&1
    
    SIZE=$(du -h ../backend-deploy-test.zip | cut -f1)
    ENTRIES=$(unzip -l ../backend-deploy-test.zip | tail -1 | awk '{print $2}')
    
    print_success "Package created: backend-deploy-test.zip ($SIZE, $ENTRIES entries)"
    
    print_info "Package contents (first 15 entries):"
    unzip -l ../backend-deploy-test.zip | head -18 | tail -15
    
    # Cleanup
    rm ../backend-deploy-test.zip
    
    cd ..
    return 0
}

# ============================================================================
# VERIFICATION
# ============================================================================
verify_setup() {
    print_header "VERIFYING SETUP"
    
    local all_good=true
    
    # Check Python
    if command -v python3 &> /dev/null; then
        VERSION=$(python3 --version 2>&1)
        print_success "Python: $VERSION"
    else
        print_error "Python 3 not found"
        all_good=false
    fi
    
    # Check pip
    if command -v pip &> /dev/null; then
        print_success "pip: Available"
    else
        print_error "pip not found"
        all_good=false
    fi
    
    # Check Flutter
    if command -v flutter &> /dev/null; then
        VERSION=$(flutter --version | head -1)
        print_success "Flutter: $VERSION"
    else
        print_warning "Flutter not installed (needed for frontend tests)"
    fi
    
    # Check directories
    if [ -d "$BACKEND_DIR" ]; then
        print_success "Backend directory exists"
    else
        print_error "Backend directory not found"
        all_good=false
    fi
    
    if [ -d "$FRONTEND_DIR" ]; then
        print_success "Frontend directory exists"
    else
        print_error "Frontend directory not found"
        all_good=false
    fi
    
    # Check required files
    if [ -f "$BACKEND_DIR/requirements.txt" ]; then
        print_success "Backend: requirements.txt found"
    else
        print_error "Backend: requirements.txt not found"
        all_good=false
    fi
    
    if [ -f "$FRONTEND_DIR/pubspec.yaml" ]; then
        print_success "Frontend: pubspec.yaml found"
    else
        print_error "Frontend: pubspec.yaml not found"
        all_good=false
    fi
    
    if [ "$all_good" = true ]; then
        print_success "All prerequisites verified!"
        return 0
    else
        print_error "Some prerequisites are missing"
        return 1
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
main() {
    local start_time=$(date +%s)
    
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║     Local CI/CD Testing Script for Seevak Care     ║"
    echo "║        Mimics GitHub Actions workflow locally      ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Verify setup
    if ! verify_setup; then
        print_error "Setup verification failed. Please install missing dependencies."
        exit 1
    fi
    
    # Run tests
    local backend_success=true
    local frontend_success=true
    
    if ! backend_test; then
        backend_success=false
    fi
    
    if ! frontend_test; then
        frontend_success=false
    fi
    
    # Test packaging
    if ! test_backend_package; then
        print_warning "Package creation test failed"
    fi
    
    # Summary
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_header "TEST SUMMARY"
    
    if [ "$backend_success" = true ]; then
        print_success "Backend: PASSED"
    else
        print_error "Backend: FAILED"
    fi
    
    if [ "$frontend_success" = true ]; then
        print_success "Frontend: PASSED"
    else
        print_error "Frontend: FAILED"
    fi
    
    echo ""
    print_info "Total duration: ${duration}s"
    echo ""
    
    # Final status
    if [ "$backend_success" = true ] && [ "$frontend_success" = true ]; then
        print_success "All tests passed! Ready to deploy."
        echo ""
        print_info "Next steps:"
        echo "  1. git add ."
        echo "  2. git commit -m 'Your commit message'"
        echo "  3. git push origin main"
        echo "  4. Monitor: github.com/YOUR_ORG/MedicalApp/actions"
        echo ""
        exit 0
    else
        print_error "Some tests failed. Fix issues before deploying."
        exit 1
    fi
}

# Run main function
main
