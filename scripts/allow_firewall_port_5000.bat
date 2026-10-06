@echo off
:: Laptop Guardian — Auto-elevating Firewall Port Opener
:: Automatically triggers UAC Administrator prompt

:: Test for Admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb runAs"
    exit /b
)

echo =========================================================
echo  Laptop Guardian — Opening Port 5000 in Windows Firewall
echo =========================================================
echo.

echo Adding firewall rule for Port 5000...
netsh advfirewall firewall delete rule name="Laptop Guardian Backend" >nul 2>&1
netsh advfirewall firewall add rule name="Laptop Guardian Backend" dir=in action=allow protocol=TCP localport=5000

if %errorlevel% == 0 (
    echo.
    echo =========================================================
    echo  [SUCCESS] Port 5000 is now open!
    echo =========================================================
    echo.
    echo On your mobile phone, open your browser and go to:
    echo.
    echo      http://10.89.154.74:5000
    echo.
) else (
    echo.
    echo [FAIL] Could not add firewall rule. Please check your antivirus firewall.
    echo.
)

echo Press any key to close this window...
pause >nul
