<# :
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (${%~f0} | Out-String)"
pause
exit /b
#>

# --- EVERYTHING BELOW IS PURE POWERSHELL ---
$Host.UI.RawUI.ForegroundColor = 'DarkYellow'
$Host.UI.RawUI.BackgroundColor = 'Black'
Clear-Host

Write-Host ">> AZ Login <<" -ForegroundColor Yellow

# Your logic
# Login to Azure at script start
Write-Host "Logging into Azure..."
az login
if ($LASTEXITCODE -ne 0) {
    Write-Host "Azure login failed. Exiting..."
    exit
}
