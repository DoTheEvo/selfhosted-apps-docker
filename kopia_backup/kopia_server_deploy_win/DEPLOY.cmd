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
echo.

if exist C:\Windows\System32\Tasks\kopia_server_backup_start (
    echo - scheduled task with that name already exists, skipping
    echo - delete the task in taskschd.msc if you want fresh import
) else (
    echo - importing scheduled task that starts Kopia Server on boot
    schtasks /Create /XML "%~dp0\kopia_server_backup_start.xml" /tn "kopia_server_backup_start"
)

echo - starting Kopia Server
schtasks /run /tn kopia_server_backup_start

echo.
echo --------------------------------------------------------------
echo.
echo DEPLOYMENT DONE
echo KOPIA SERVER CAN NOW BE FIND AT WEB PAGE: localhost:51515
echo.
pause
