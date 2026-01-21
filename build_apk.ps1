# Script to build APK for TowerFlower application
# Requirements: Flutter SDK installed

Write-Host "=== Building APK for TowerFlower ===" -ForegroundColor Cyan

# Function to find Flutter
function Find-Flutter {
    # Check PATH
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd) {
        return $flutterCmd.Source
    }
    
    # Check common locations
    $commonPaths = @(
        "C:\Users\jarek\dev\flutter\bin\flutter.bat",
        "$env:LOCALAPPDATA\Pub\Cache\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:ProgramFiles\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat",
        "$env:ProgramFiles(x86)\flutter\bin\flutter.bat"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Check in environment variables
    $envPaths = $env:PATH -split ';'
    foreach ($envPath in $envPaths) {
        if ($envPath) {
            $flutterPath = Join-Path $envPath "flutter.bat"
            if (Test-Path $flutterPath) {
                return $flutterPath
            }
        }
    }
    
    return $null
}

# Find Flutter
$flutterPath = Find-Flutter

if (-not $flutterPath) {
    Write-Host "Flutter was not found automatically!" -ForegroundColor Yellow
    Write-Host ""
    $manualPath = Read-Host "Enter full path to flutter.bat (or press Enter to cancel)"
    if ([string]::IsNullOrWhiteSpace($manualPath)) {
        Write-Host "Cancelled." -ForegroundColor Red
        exit 1
    }
    if (Test-Path $manualPath) {
        $flutterPath = $manualPath
    } else {
        Write-Host "ERROR: The specified path does not exist!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Flutter found: $flutterPath" -ForegroundColor Green
Write-Host ""

# Add Flutter to PATH for this session
$flutterDir = Split-Path $flutterPath -Parent
$env:PATH = "$flutterDir;$env:PATH"

# Check if we are in project directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: pubspec.yaml file not found!" -ForegroundColor Red
    Write-Host "Run the script from the Flutter project root directory."
    exit 1
}

# Check Flutter configuration
Write-Host "Checking Flutter configuration..." -ForegroundColor Yellow
& $flutterPath doctor

Write-Host ""
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
& $flutterPath clean

Write-Host ""
Write-Host "Fetching dependencies..." -ForegroundColor Yellow
& $flutterPath pub get

Write-Host ""
Write-Host "Building APK (release)..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Gray

# Build APK
& $flutterPath build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== SUCCESS! ===" -ForegroundColor Green
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        $fileInfo = Get-Item $apkPath
        Write-Host "APK created:" -ForegroundColor Green
        Write-Host "  Location: $($fileInfo.FullName)" -ForegroundColor White
        Write-Host "  Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor White
        Write-Host ""
        Write-Host "You can now install the APK on an Android device or share it with others." -ForegroundColor Cyan
    } else {
        Write-Host "Warning: APK file not found in expected location." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "=== BUILD ERROR ===" -ForegroundColor Red
    Write-Host "Check error messages above." -ForegroundColor Yellow
    exit 1
}
