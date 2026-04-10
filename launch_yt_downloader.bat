@echo off
REM YouTube Downloader Quick Launch Script
echo ========================================
echo YouTube Downloader Launcher
echo ========================================
echo.

REM Navigate to project directory
cd /d "%~dp0"

REM Force UTF-8 to prevent encoding errors with non-ASCII video titles
set PYTHONUTF8=1
chcp 65001 >nul

REM Check if virtual environment exists, if not create it
if not exist "venv\" (
    echo Creating virtual environment...
    python -m venv venv
    echo Virtual environment created.
    echo.
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Install/Update requirements
echo Installing/Updating requirements...
pip install -r requirements.txt --quiet

echo.
echo ========================================
echo Starting YouTube Downloader...
echo.
echo Access the app at: http://localhost:8000
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

REM Wait a moment then open browser
start "" timeout /t 3 /nobreak >nul && start http://localhost:8000

REM Run the app
python main.py

pause
