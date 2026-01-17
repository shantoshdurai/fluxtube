@echo off
echo ========================================
echo   YouTube Downloader - Quick Launch
echo ========================================
echo.

REM Change to the script's directory
cd /d "%~dp0"

REM Check if virtual environment exists
if exist "venv\Scripts\activate.bat" (
    echo [1/3] Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo [!] Virtual environment not found. Using system Python...
)

REM Open browser
echo [2/3] Opening browser...
start http://localhost:8000

REM Run the server
echo [3/3] Starting server...
echo.
echo ========================================
echo   Server is running on http://localhost:8000
echo   Press Ctrl+C to stop the server
echo ========================================
echo.
python main.py

pause
