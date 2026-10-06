@echo off
setlocal

:: ============================================================================
:: Laptop Guardian — Windows Scheduled Task Uninstaller
:: Removes the auto-starting task and stops running instances cleanly.
:: ============================================================================

set "TASK_NAME=LaptopGuardianAgent"

echo ============================================================
echo   Laptop Guardian — Remove Scheduled Task
echo ============================================================
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

:: 2. Stop running task
echo [INFO] Stopping any running instance of "%TASK_NAME%"...
schtasks /end /tn "%TASK_NAME%" >nul 2>&1

:: 3. Delete scheduled task
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %errorLevel% equ 0 (
    schtasks /delete /tn "%TASK_NAME%" /f
    if %errorLevel% equ 0 (
        echo.
        echo [SUCCESS] Windows Scheduled Task "%TASK_NAME%" has been removed.
        echo Laptop Guardian Agent will no longer start automatically on Windows boot.
    ) else (
        echo [ERROR] Failed to delete task "%TASK_NAME%".
    )
) else (
    echo.
    echo [INFO] Scheduled Task "%TASK_NAME%" was not found on this system.
)

echo.
pause
