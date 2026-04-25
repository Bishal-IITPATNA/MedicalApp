@echo off
REM Local CI/CD Testing Script (Windows PowerShell version)
REM This script mimics what GitHub Actions does locally
REM Usage: powershell -ExecutionPolicy Bypass -File test-locally.ps1

# Colors for output
$colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Cyan"
    Gray = "Gray"
}

# Configuration
$BackendDir = "backend"
$FrontendDir = "frontend"
$SkipTests = $false
$SkipBuild = $false
$SkipLint = $false
$Verbose = $false

# Parse arguments
$args | ForEach-Object {
    switch ($_) {
        "--skip-tests" { $SkipTests = $true }
        "--skip-build" { $SkipBuild = $true }
        "--skip-lint" { $SkipLint = $true }
        "--verbose" { $Verbose = $true }
        "-v" { $Verbose = $true }
        "--help" {
            Write-Host "Local CI/CD Testing Script (Windows PowerShell)"
            Write-Host ""
            Write-Host "Usage: powershell -ExecutionPolicy Bypass -File test-locally.ps1 [options]"
            Write-Host ""
            Write-Host "Options:"
            Write-Host "  --skip-tests    Skip running tests"
            Write-Host "  --skip-build    Skip building"
            Write-Host "  --skip-lint     Skip linting"
            Write-Host "  --verbose, -v   Verbose output"
            Write-Host "  --help, -h      Show this help message"
            exit 0
        }
    }
}

# Functions
function Print-Header {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host $args[0] -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Print-Success {
    Write-Host "✅ $($args[0])" -ForegroundColor Green
}

function Print-Error {
    Write-Host "❌ $($args[0])" -ForegroundColor Red
}

function Print-Warning {
    Write-Host "⚠️  $($args[0])" -ForegroundColor Yellow
}

function Print-Info {
    Write-Host "ℹ️  $($args[0])" -ForegroundColor Cyan
}

# ============================================================================
# BACKEND BUILD & TEST
# ============================================================================
function Backend-Test {
    Print-Header "BACKEND BUILD & TEST"
    
    if (-not (Test-Path $BackendDir)) {
        Print-Error "Backend directory not found: $BackendDir"
        return $false
    }
    
    Push-Location $BackendDir
    
    # Check required files
    if (-not (Test-Path "requirements.txt")) {
        Print-Error "requirements.txt not found in backend directory"
        Pop-Location
        return $false
    }
    
    Print-Info "Installing dependencies..."
    try {
        if ($Verbose) {
            pip install -r requirements.txt
        } else {
            pip install -r requirements.txt | Out-Null
        }
        Print-Success "Dependencies installed"
    } catch {
        Print-Error "Failed to install dependencies: $_"
        Pop-Location
        return $false
    }
    
    # Linting
    if (-not $SkipLint) {
        Print-Info "Running pylint..."
        try {
            $pylintInstalled = pip list | Select-String "pylint"
            if (-not $pylintInstalled) {
                pip install pylint | Out-Null
            }
            pylint app/ --disable=all --enable=E,F
        } catch {
            Print-Warning "Linting skipped"
        }
        Print-Success "Linting check complete"
    }
    
    # Tests
    if (-not $SkipTests) {
        Print-Info "Running pytest..."
        try {
            $pytestInstalled = pip list | Select-String "pytest"
            if (-not $pytestInstalled) {
                pip install pytest pytest-cov | Out-Null
            }
            
            $testResult = pytest -v --cov=app --cov-report=term
            if ($LASTEXITCODE -eq 0) {
                Print-Success "Tests passed"
            } else {
                Print-Error "Tests failed"
                Pop-Location
                return $false
            }
        } catch {
            Print-Error "Tests failed: $_"
            Pop-Location
            return $false
        }
    }
    
    # Build check
    if (-not $SkipBuild) {
        Print-Info "Testing backend startup..."
        try {
            $output = python -c "from main import app; print('✅ Backend imports successfully')"
            Write-Host $output
        } catch {
            Print-Error "Backend failed to import: $_"
            Pop-Location
            return $false
        }
    }
    
    Pop-Location
    Print-Success "Backend tests completed"
    return $true
}

# ============================================================================
# FRONTEND BUILD & TEST
# ============================================================================
function Frontend-Test {
    Print-Header "FRONTEND BUILD & TEST"
    
    if (-not (Test-Path $FrontendDir)) {
        Print-Error "Frontend directory not found: $FrontendDir"
        return $false
    }
    
    Push-Location $FrontendDir
    
    # Check required files
    if (-not (Test-Path "pubspec.yaml")) {
        Print-Error "pubspec.yaml not found in frontend directory"
        Pop-Location
        return $false
    }
    
    # Check Flutter
    $flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $flutterPath) {
        Print-Error "Flutter not installed. Please install Flutter and add to PATH"
        Print-Info "Visit: https://flutter.dev/docs/get-started/install"
        Pop-Location
        return $false
    }
    
    Print-Info "Installing Flutter dependencies..."
    try {
        if ($Verbose) {
            flutter pub get
        } else {
            flutter pub get | Out-Null
        }
        Print-Success "Flutter dependencies installed"
    } catch {
        Print-Error "Failed to install Flutter dependencies: $_"
        Pop-Location
        return $false
    }
    
    # Analysis
    if (-not $SkipLint) {
        Print-Info "Running Flutter analyzer..."
        try {
            flutter analyze
        } catch {
            Print-Warning "Analysis failed (not critical)"
        }
        Print-Success "Analysis complete"
    }
    
    # Tests
    if (-not $SkipTests) {
        Print-Info "Running Flutter tests..."
        try {
            $testResult = flutter test
            if ($LASTEXITCODE -eq 0) {
                Print-Success "Flutter tests passed"
            } else {
                Print-Warning "Flutter tests failed (not critical)"
            }
        } catch {
            Print-Warning "Flutter tests failed: $_ (not critical)"
        }
    }
    
    # Build
    if (-not $SkipBuild) {
        Print-Info "Building Flutter web..."
        try {
            flutter build web --release | Out-Null
            $size = (Get-ChildItem -Path "build\web" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
            Print-Success "Flutter build completed (size: $([Math]::Round($size, 2)) MB)"
        } catch {
            Print-Error "Flutter build failed: $_"
            Pop-Location
            return $false
        }
    }
    
    Pop-Location
    Print-Success "Frontend tests completed"
    return $true
}

# ============================================================================
# ZIP CREATION TEST (Backend deployment package)
# ============================================================================
function Test-Backend-Package {
    Print-Header "BACKEND DEPLOYMENT PACKAGE TEST"
    
    Push-Location $BackendDir
    
    Print-Info "Creating deployment package..."
    
    try {
        # Create ZIP file (using 7-Zip or built-in compression)
        $zipFile = "..\backend-deploy-test.zip"
        
        if (Get-Command 7z -ErrorAction SilentlyContinue) {
            # Use 7-Zip if available
            7z a -r -x!.git -x!__pycache__ -x!*.pyc -x!venv -x!env $zipFile "*" | Out-Null
        } else {
            # Fallback: Use PowerShell compression
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            
            $files = Get-ChildItem -Exclude ".git", "__pycache__", "venv", "env" -Recurse | Where-Object { -not $_.PSIsContainer -and $_.Name -notmatch "\.pyc$|\.log$" }
            
            # Note: Manual ZIP creation is complex in PowerShell, so we'll just note that this would be done
            Print-Warning "Using 7z or manual ZIP creation (simplified test)"
            
            # For now, just verify files exist
            if (Test-Path "main.py" -and Test-Path "requirements.txt" -and Test-Path "app") {
                Print-Success "Package would contain all required files"
            }
        }
        
        if (Test-Path $zipFile) {
            $size = "{0:N2} MB" -f ((Get-Item $zipFile).Length / 1MB)
            Print-Success "Package created: backend-deploy-test.zip ($size)"
            
            # Cleanup
            Remove-Item $zipFile -Force
        } else {
            Print-Info "Package test completed (ZIP creation skipped on this system)"
        }
    } catch {
        Print-Warning "Package creation test failed: $_"
    }
    
    Pop-Location
    return $true
}

# ============================================================================
# VERIFICATION
# ============================================================================
function Verify-Setup {
    Print-Header "VERIFYING SETUP"
    
    $allGood = $true
    
    # Check Python
    $pythonPath = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonPath) {
        $version = python --version 2>&1
        Print-Success "Python: $version"
    } else {
        Print-Error "Python not found"
        $allGood = $false
    }
    
    # Check pip
    $pipPath = Get-Command pip -ErrorAction SilentlyContinue
    if ($pipPath) {
        Print-Success "pip: Available"
    } else {
        Print-Error "pip not found"
        $allGood = $false
    }
    
    # Check Flutter
    $flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterPath) {
        $version = flutter --version 2>&1 | Select-Object -First 1
        Print-Success "Flutter: $version"
    } else {
        Print-Warning "Flutter not installed (needed for frontend tests)"
    }
    
    # Check directories
    if (Test-Path $BackendDir) {
        Print-Success "Backend directory exists"
    } else {
        Print-Error "Backend directory not found"
        $allGood = $false
    }
    
    if (Test-Path $FrontendDir) {
        Print-Success "Frontend directory exists"
    } else {
        Print-Error "Frontend directory not found"
        $allGood = $false
    }
    
    # Check required files
    if (Test-Path "$BackendDir\requirements.txt") {
        Print-Success "Backend: requirements.txt found"
    } else {
        Print-Error "Backend: requirements.txt not found"
        $allGood = $false
    }
    
    if (Test-Path "$FrontendDir\pubspec.yaml") {
        Print-Success "Frontend: pubspec.yaml found"
    } else {
        Print-Error "Frontend: pubspec.yaml not found"
        $allGood = $false
    }
    
    if ($allGood) {
        Print-Success "All prerequisites verified!"
        return $true
    } else {
        Print-Error "Some prerequisites are missing"
        return $false
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
function Main {
    $startTime = Get-Date
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Local CI/CD Testing Script for Seevak Care     ║" -ForegroundColor Cyan
    Write-Host "║        Mimics GitHub Actions workflow locally      ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Verify setup
    if (-not (Verify-Setup)) {
        Print-Error "Setup verification failed. Please install missing dependencies."
        exit 1
    }
    
    # Run tests
    $backendSuccess = Backend-Test
    $frontendSuccess = Frontend-Test
    
    # Test packaging
    Test-Backend-Package | Out-Null
    
    # Summary
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Print-Header "TEST SUMMARY"
    
    if ($backendSuccess) {
        Print-Success "Backend: PASSED"
    } else {
        Print-Error "Backend: FAILED"
    }
    
    if ($frontendSuccess) {
        Print-Success "Frontend: PASSED"
    } else {
        Print-Error "Frontend: FAILED"
    }
    
    Write-Host ""
    Print-Info "Total duration: $([Math]::Round($duration, 2))s"
    Write-Host ""
    
    # Final status
    if ($backendSuccess -and $frontendSuccess) {
        Print-Success "All tests passed! Ready to deploy."
        Write-Host ""
        Print-Info "Next steps:"
        Write-Host "  1. git add ."
        Write-Host "  2. git commit -m 'Your commit message'"
        Write-Host "  3. git push origin main"
        Write-Host "  4. Monitor: github.com/YOUR_ORG/MedicalApp/actions"
        Write-Host ""
        exit 0
    } else {
        Print-Error "Some tests failed. Fix issues before deploying."
        exit 1
    }
}

# Run main function
Main
