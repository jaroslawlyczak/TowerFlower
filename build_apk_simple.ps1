# Simple script to build APK - accepts Flutter path as parameter
# Usage: .\build_apk_simple.ps1 -FlutterPath "C:\flutter\bin\flutter.bat"

param(
    [Parameter(Mandatory=$false)]
    [string]$FlutterPath = ""
)

Write-Host "=== Building APK for TowerFlower ===" -ForegroundColor Cyan

# If Flutter path not provided, try to find it
if ([string]::IsNullOrWhiteSpace($FlutterPath)) {
    Write-Host "Searching for Flutter..." -ForegroundColor Yellow
    
    # Try common locations
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
            $FlutterPath = $path
            Write-Host "Found Flutter at: $FlutterPath" -ForegroundColor Green
            break
        }
    }
    
    # Try PATH
    if ([string]::IsNullOrWhiteSpace($FlutterPath)) {
        $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
        if ($flutterCmd) {
            $FlutterPath = $flutterCmd.Source
            Write-Host "Found Flutter in PATH: $FlutterPath" -ForegroundColor Green
        }
    }
}

# Check if Flutter path is valid
if ([string]::IsNullOrWhiteSpace($FlutterPath) -or -not (Test-Path $FlutterPath)) {
    Write-Host ""
    Write-Host "ERROR: Flutter not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please provide Flutter path:" -ForegroundColor Yellow
    Write-Host "  .\build_apk_simple.ps1 -FlutterPath `"C:\flutter\bin\flutter.bat`"" -ForegroundColor White
    Write-Host ""
    Write-Host "Or add Flutter to your PATH environment variable." -ForegroundColor Yellow
    exit 1
}

Write-Host "Using Flutter: $FlutterPath" -ForegroundColor Green
Write-Host ""

# Check if we are in project directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: pubspec.yaml file not found!" -ForegroundColor Red
    Write-Host "Run the script from the Flutter project root directory."
    exit 1
}

# Add Flutter directory to PATH for this session
$flutterDir = Split-Path $FlutterPath -Parent
$env:PATH = "$flutterDir;$env:PATH"

# Check Flutter configuration
Write-Host "Checking Flutter configuration..." -ForegroundColor Yellow
& $FlutterPath doctor

Write-Host ""
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
& $FlutterPath clean

Write-Host ""
Write-Host "Fetching dependencies..." -ForegroundColor Yellow
& $FlutterPath pub get

Write-Host ""
Write-Host "Building APK (release)..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Gray

# Build APK
& $FlutterPath build apk --release

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
        Write-Host "You can now install the APK on an Android device." -ForegroundColor Cyan
    } else {
        Write-Host "Warning: APK file not found in expected location." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "=== BUILD ERROR ===" -ForegroundColor Red
    Write-Host "Check error messages above." -ForegroundColor Yellow
    exit 1
}

