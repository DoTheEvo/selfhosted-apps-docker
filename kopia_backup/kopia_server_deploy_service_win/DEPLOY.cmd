@echo off

:: checking if the script is run as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo - Success: Administrative permissions confirmed.
) else (
    echo - RUN AS ADMINISTRATOR
    pause
    exit /B
)

echo - powershell ExecutionPolicy changing to Bypass
powershell.exe Set-ExecutionPolicy -ExecutionPolicy Bypass

echo - checking if C:\Kopia folder exists, creating it if not
if not exist "C:\Kopia\" (
  mkdir C:\Kopia
)

if exist "C:\Kopia\kopia_server_start.cmd" (
  echo - C:\Kopia\kopia_server_start.cmd exists, renaming it with random suffix
  ren "C:\Kopia\kopia_server_start.cmd" "kopia_backup_scipt_%random%.ps1"
)

echo - copying files to C:\Kopia
robocopy "%~dp0\" "C:\Kopia" "kopia.exe" /NDL /NJH /NJS
robocopy "%~dp0\" "C:\Kopia" "kopia_server_start.cmd" /NDL /NJH /NJS
robocopy "%~dp0\" "C:\Kopia" "win_vss_before.ps1" /NDL /NJH /NJS
robocopy "%~dp0\" "C:\Kopia" "win_vss_after.ps1" /NDL /NJH /NJS
robocopy "%~dp0\" "C:\Kopia" "shawl.exe" /NDL /NJH /NJS
echo.

echo - adding C:\Kopia to PATH
setx /M PATH "%PATH%;C:\Kopia"

echo - creting Kopia service
C:\Kopia\shawl.exe add --log-dir C:\kopia\Kopia_service_logs --name Kopia -- C:\Kopia\kopia_server_start.cmd

echo - setting Kopia service to start automaticly at boot
sc config Kopia start=auto

echo - start Kopia service
sc start Kopia


echo - copying link to Desktop
robocopy "%~dp0\" "%USERPROFILE%\Desktop" "Kopia.url" /NDL /NJH /NJS

echo.
echo --------------------------------------------------------------
echo.
echo DEPLOYMENT DONE
echo KOPIA SERVER CAN NOW BE FIND AT WEB PAGE: localhost:51515
echo A LINK SHOULD BE ON YOUR DESKTOP
echo.
pause
