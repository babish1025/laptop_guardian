@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Laptop Guardian — Windows Scheduled Task Installer
:: Installs the Laptop Agent as a resilient, auto-starting, silent Windows task.
::
:: Features:
:: - Runs automatically on user logon
:: - Runs silently in background (using pythonw without console window popup)
:: - Restarts automatically if the process exits unexpectedly or crashes
:: - Prevents duplicate running instances
:: - Runs whether plugged into AC power or running on battery
:: ============================================================================

set "TASK_NAME=LaptopGuardianAgent"
set "PROJECT_DIR=%~dp0.."
pushd "%PROJECT_DIR%"
set "PROJECT_DIR=%CD%"
popd

echo ============================================================
echo   Laptop Guardian — Scheduled Task Setup (Auto-Start)
echo ============================================================
echo Project Directory: %PROJECT_DIR%
echo.

:: 1. Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Administrative privileges required.
    echo Please right-click this script and select "Run as administrator".
    echo.
    pause
    exit /b 1
)

:: 2. Find Python executable
set "PYTHON_EXE="
set "PYTHONW_EXE="

for /f "delims=" %%I in ('where pythonw 2^>nul') do (
    if not defined PYTHONW_EXE set "PYTHONW_EXE=%%I"
)
for /f "delims=" %%I in ('where python 2^>nul') do (
    if not defined PYTHON_EXE set "PYTHON_EXE=%%I"
)

if not defined PYTHONW_EXE (
    if defined PYTHON_EXE (
        set "PYTHONW_EXE=%PYTHON_EXE%"
    ) else (
        echo [ERROR] Python not found in system PATH.
        echo Please ensure Python 3.8+ is installed and added to PATH.
        pause
        exit /b 1
    )
)

echo Python Executable: %PYTHONW_EXE%
echo Agent Script:      %PROJECT_DIR%\laptop_agent\agent.py
echo.

:: 3. Generate Temporary Task Scheduler XML Configuration
set "XML_FILE=%TEMP%\LaptopGuardianTask_%RANDOM%.xml"

(
echo ^<?xml version="1.0" encoding="UTF-16"?^>
echo ^<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
echo   ^<RegistrationInfo^>
echo     ^<Description^>Laptop Guardian background monitoring agent with WAN telemetry and auto-restart.^</Description^>
echo   ^</RegistrationInfo^>
echo   ^<Triggers^>
echo     ^<LogonTrigger^>
echo       ^<Enabled^>true^</Enabled^>
echo     ^</LogonTrigger^>
echo   ^</Triggers^>
echo   ^<Principals^>
echo     ^<Principal id="Author"^>
echo       ^<LogonType^>InteractiveToken^</LogonType^>
echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
echo     ^</Principal^>
echo   ^</Principals^>
echo   ^<Settings^>
echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^>
echo     ^<StartWhenAvailable^>true^</StartWhenAvailable^>
echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
echo     ^<IdleSettings^>
echo       ^<StopOnIdleEnd^>false^</StopOnIdleEnd^>
echo       ^<RestartOnIdle^>false^</RestartOnIdle^>
echo     ^</IdleSettings^>
echo     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^>
echo     ^<Enabled^>true^</Enabled^>
echo     ^<Hidden^>true^</Hidden^>
echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^>
echo     ^<WakeToRun^>false^</WakeToRun^>
echo     ^<ExecutionTimeLimit^>PT0S^</ExecutionTimeLimit^>
echo     ^<Priority^>7^</Priority^>
echo     ^<RestartOnFailure^>
echo       ^<Interval^>PT1M^</Interval^>
echo       ^<Count^>999^</Count^>
echo     ^</RestartOnFailure^>
echo   ^</Settings^>
echo   ^<Actions Context="Author"^>
echo     ^<Exec^>
echo       ^<Command^>%PYTHONW_EXE%^</Command^>
echo       ^<Arguments^>"%PROJECT_DIR%\laptop_agent\agent.py"^</Arguments^>
echo       ^<WorkingDirectory^>%PROJECT_DIR%^</WorkingDirectory^>
echo     ^</Exec^>
echo   ^</Actions^>
echo ^</Task^>
) > "%XML_FILE%"

:: 4. Delete existing task if present
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %errorLevel% equ 0 (
    echo [INFO] Removing existing task "%TASK_NAME%"...
    schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
)

:: 5. Register the task using the XML specification
echo [INFO] Registering Windows Scheduled Task "%TASK_NAME%"...
schtasks /create /tn "%TASK_NAME%" /xml "%XML_FILE%" /f

set "INSTALL_STATUS=%errorLevel%"
del /f /q "%XML_FILE%" >nul 2>&1

if %INSTALL_STATUS% equ 0 (
    echo.
    echo ============================================================
    echo   [SUCCESS] Laptop Guardian Agent Task Successfully Installed!
    echo ============================================================
    echo.
    echo The agent will now:
    echo   - Start automatically upon user login
    echo   - Run silently in the background (no console window)
    echo   - Restart automatically if it crashes or terminates
    echo   - Write telemetry logs to: logs\agent.log
    echo.
    echo Would you like to start the Laptop Guardian Agent now? (Y/N)
    set /p START_NOW="Choice: "
    if /i "!START_NOW!"=="Y" (
        schtasks /run /tn "%TASK_NAME%"
        echo [INFO] Agent task triggered. Check logs\agent.log for status.
    )
) else (
    echo.
    echo [FAIL] Could not create scheduled task. Check output above.
)

echo.
pause
