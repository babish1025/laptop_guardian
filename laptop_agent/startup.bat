@echo off
:: Laptop Guardian — Agent Startup Launcher
:: Launches the agent silently in the background with pythonw

cd /d "%~dp0.."

where pythonw >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set PYTHON_EXEC=pythonw
) else if exist "venv\Scripts\pythonw.exe" (
    set PYTHON_EXEC=venv\Scripts\pythonw.exe
) else if exist "venv\Scripts\python.exe" (
    set PYTHON_EXEC=venv\Scripts\python.exe
) else (
    set PYTHON_EXEC=python
)

echo Starting Laptop Guardian Agent in background...
start "" "%PYTHON_EXEC%" laptop_agent\agent.py
