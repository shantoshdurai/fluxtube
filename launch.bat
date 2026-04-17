@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

echo ========================================
echo   FluxTube - Starting...
echo ========================================
echo.

REM --- Check Python ---
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Install Python 3.9+ from https://python.org
    pause
    exit /b 1
)

REM --- Setup venv if missing ---
if not exist "venv\Scripts\python.exe" (
    echo [1/4] Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
)

REM --- Install/update dependencies ---
echo [2/4] Installing dependencies...
venv\Scripts\pip install -q -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies.
    pause
    exit /b 1
)

REM --- Check and install FFmpeg (required for 4K / audio merging) ---
echo [3/4] Checking FFmpeg...
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo     FFmpeg not found. Installing via winget...
    winget install --id Gyan.FFmpeg -e --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
    REM Refresh PATH for this session
    for /f "delims=" %%i in ('where ffmpeg 2^>nul') do set FFMPEG_PATH=%%i
    if not defined FFMPEG_PATH (
        REM Try common install location
        set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-*-full_build\bin"
        where ffmpeg >nul 2>&1
        if errorlevel 1 (
            echo     [!] FFmpeg install may need a restart to take effect.
            echo     [!] Downloads will be capped at 720p until FFmpeg is available.
        ) else (
            echo     FFmpeg installed successfully.
        )
    ) else (
        echo     FFmpeg installed successfully.
    )
) else (
    echo     FFmpeg OK.
)

REM --- Start server then open browser ---
echo [4/4] Starting server...
echo.

start "FluxTube Server" /min cmd /c "set PYTHONUTF8=1 && set PYTHONIOENCODING=utf-8 && venv\Scripts\python.exe main.py"

echo Waiting for server to start...
:WAIT_LOOP
timeout /t 1 /nobreak >nul
venv\Scripts\python.exe -c "import urllib.request; urllib.request.urlopen('http://localhost:8080')" >nul 2>&1
if errorlevel 1 goto WAIT_LOOP

echo Server is ready! Opening browser...
start http://localhost:8080

echo.
echo ========================================
echo   FluxTube running at http://localhost:8080
echo   Close the "FluxTube Server" window to stop.
echo ========================================
echo.
pause
