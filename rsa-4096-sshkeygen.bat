@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Optional argument: key directory
set KEY_DIR=%~1

:: Default to "keys" directory next to script
if "%KEY_DIR%"=="" (
  set KEY_DIR=%~dp0keys
)

:: Remove trailing backslash if present
if "%KEY_DIR:~-1%"=="\" set KEY_DIR=%KEY_DIR:~0,-1%

:: Ensure directory exists
if not exist "%KEY_DIR%" mkdir "%KEY_DIR%"

set TEMP_KEY=%KEY_DIR%\id_terraform
set PRIVATE_KEY=%KEY_DIR%\private.txt
set PUBLIC_KEY=%KEY_DIR%\public.txt

echo Generating SSH keys in %KEY_DIR%

:: Generate SSH keys
ssh-keygen -t rsa -b 4096 -C "%USERNAME%" -f "%TEMP_KEY%" -N "" -q

:: Rename for simplicity
move /Y "%TEMP_KEY%" "%PRIVATE_KEY%" >nul
move /Y "%TEMP_KEY%.pub" "%PUBLIC_KEY%" >nul

endlocal
``
