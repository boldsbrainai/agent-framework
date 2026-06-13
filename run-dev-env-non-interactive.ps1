# Non-interactive script to build and run the DevUI dev env
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ($scriptPath -eq $null -or $scriptPath -eq "") {
    $scriptPath = Get-Location
}

Write-Host "1. Building Frontend..." -ForegroundColor Cyan
cd "$scriptPath\python\packages\devui\frontend"
if (Get-Command yarn -ErrorAction SilentlyContinue) {
    yarn install
    yarn build
} else {
    npm install
    npm run build
}

Write-Host "2. Sincronizando dependencias Python..." -ForegroundColor Cyan
cd "$scriptPath\python"
uv sync --dev

Write-Host "3. Subindo o DevUI..." -ForegroundColor Cyan
cd "$scriptPath\python\packages\devui"
# Use absolute path to the newly synced virtualenv python
$venvPython = "$scriptPath\python\.venv\Scripts\python.exe"
& $venvPython -c "import agent_framework_devui; agent_framework_devui.main()" --no-auth $args
