# PowerShell Script to Update, Build and Run the Dev Environment
# Run this script on your host machine's PowerShell terminal outside the IDE sandbox.

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ($scriptPath -eq $null -or $scriptPath -eq "") {
    $scriptPath = Get-Location
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Setting up and running Agent Framework DevUI   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Build Frontend
$frontendDir = Join-Path $scriptPath "python\packages\devui\frontend"
if (Test-Path $frontendDir) {
    Write-Host "`n[1/3] Setting up Frontend in: $frontendDir" -ForegroundColor Yellow
    Push-Location $frontendDir
    
    # Try yarn, fallback to npm
    if (Get-Command yarn -ErrorAction SilentlyContinue) {
        Write-Host "Running yarn install..." -ForegroundColor Gray
        yarn install
        Write-Host "Running yarn build..." -ForegroundColor Gray
        yarn build
    } else {
        Write-Host "yarn not found, using npm instead..." -ForegroundColor Gray
        Write-Host "Running npm install..." -ForegroundColor Gray
        npm install
        Write-Host "Running npm run build..." -ForegroundColor Gray
        npm run build
    }
    Pop-Location
} else {
    Write-Warning "Frontend directory not found at $frontendDir"
}

# 2. Setup/Sync Python Dependencies
$pythonDir = Join-Path $scriptPath "python"
if (Test-Path $pythonDir) {
    Write-Host "`n[2/3] Setting up Python dependencies in: $pythonDir" -ForegroundColor Yellow
    Push-Location $pythonDir

    if (Get-Command uv -ErrorAction SilentlyContinue) {
        Write-Host "Running uv sync --dev..." -ForegroundColor Gray
        uv sync --dev
    } else {
        Write-Warning "uv tool not found! Please install uv or make sure it is on your PATH."
        Write-Host "Alternatively, attempting standard pip install in virtualenv..." -ForegroundColor Gray
        if (-not (Test-Path ".venv")) {
            python -m venv .venv
        }
    }
    
    # Check venv path
    $venvActivate = Join-Path $pythonDir ".venv\Scripts\Activate.ps1"
    if (Test-Path $venvActivate) {
        Write-Host "Activating virtual environment..." -ForegroundColor Gray
        . $venvActivate
    } else {
        Write-Warning "Virtual environment activation script not found at $venvActivate"
    }
    
    Pop-Location
} else {
    Write-Warning "Python directory not found at $pythonDir"
}

# 3. Running DevUI
Write-Host "`n[3/3] Launching Dev Environment Options" -ForegroundColor Yellow
Write-Host "Select which dev environment option to run:" -ForegroundColor Cyan
Write-Host "1) Option A: In-Memory Mode (Predefined agents/weather assistant)"
Write-Host "2) Option B: Directory-Based Discovery (Scan current directory)"
Write-Host "3) Exit"

$choice = Read-Host "Enter option [1-3] (Default is 2)"
if ($choice -eq "") { $choice = "2" }

if ($choice -eq "1") {
    $sampleDir = Join-Path $scriptPath "python\samples\02-agents\devui"
    if (Test-Path $sampleDir) {
        Push-Location $sampleDir
        Write-Host "Running: python in_memory_mode.py" -ForegroundColor Green
        # Ensure venv is active in local scope if running
        if (Test-Path (Join-Path $pythonDir ".venv\Scripts\Activate.ps1")) {
            . (Join-Path $pythonDir ".venv\Scripts\Activate.ps1")
        }
        python in_memory_mode.py
        Pop-Location
    } else {
        Write-Error "Sample directory not found at $sampleDir"
    }
} elseif ($choice -eq "2") {
    $devuiPackageDir = Join-Path $scriptPath "python\packages\devui"
    Push-Location $devuiPackageDir
    Write-Host "Running DevUI server with discovery (no-auth)..." -ForegroundColor Green
    if (Test-Path (Join-Path $pythonDir ".venv\Scripts\Activate.ps1")) {
        . (Join-Path $pythonDir ".venv\Scripts\Activate.ps1")
    }
    # We run using python -c to load the package and call main()
    python -c "import agent_framework_devui; agent_framework_devui.main()" --no-auth
    Pop-Location
} else {
    Write-Host "Exited." -ForegroundColor Yellow
}
