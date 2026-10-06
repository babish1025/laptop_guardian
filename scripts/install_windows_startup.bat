@echo off
:: Laptop Guardian — Windows Startup Installer
:: Run as Administrator to install the agent as a startup task.

SET PROJECT_DIR=%~dp0..
SET PYTHON=python
SET AGENT_SCRIPT=%PROJECT_DIR%\laptop_agent\agent.py
SET TASK_NAME=LaptopGuardianAgent

echo ============================================
echo  Laptop Guardian — Windows Startup Setup
echo ============================================
echo Project dir: %PROJECT_DIR%
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Please run this script as Administrator.
    pause
    exit /b 1
)

:: Remove existing task if present
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %errorLevel% == 0 (
    echo Removing existing startup task...
    schtasks /delete /tn "%TASK_NAME%" /f
)

:: Create scheduled task to run at logon
schtasks /create ^
    /tn "%TASK_NAME%" ^
    /tr "%PYTHON% \"%AGENT_SCRIPT%\"" ^
    /sc ONLOGON ^
    /rl HIGHEST ^
    /f

if %errorLevel% == 0 (
    echo.
    echo [OK] Laptop Guardian will now start automatically on Windows login.
    echo.
    echo To remove: schtasks /delete /tn "%TASK_NAME%" /f
) else (
    echo.
    echo [FAIL] Could not create startup task. Check error above.
)

pause
