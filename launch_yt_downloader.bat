@echo off
REM YouTube Downloader Quick Launch Script
echo ========================================
echo YouTube Downloader Launcher
echo ========================================
echo.

REM Navigate to project directory
cd /d "%~dp0"

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

REM Launch the Flask application
echo.
echo ========================================
echo Starting YouTube Downloader...
echo.
echo Access the app at: http://localhost:5000
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

REM Wait a moment then open browser
start "" timeout /t 3 /nobreak >nul && start http://localhost:5000

REM Run the Flask app
python main.py

pause
