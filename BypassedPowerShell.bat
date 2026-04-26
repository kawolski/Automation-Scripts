@echo off
REM Open one PowerShell window and run a command
@REM start powershell.exe -NoExit -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass"

start powershell.exe -NoExit -Command "& {Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; $Host.UI.RawUI.ForegroundColor='Magenta'; $Host.UI.RawUI.BackgroundColor='Black'; Clear-Host; Write-Host '>> POWER SHELL ACTIVE <<' -ForegroundColor Yellow}"


