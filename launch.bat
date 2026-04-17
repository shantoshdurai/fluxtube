@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

cd /d "%~dp0"

echo.
echo  ===================================
echo    FluxTube Launcher
echo  ===================================
echo.

REM ---------- 1. PYTHON ----------
echo  [1/4] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo  Python not found. Installing via winget...
    winget install --id Python.Python.3.11 -e --silent --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts"
    python --version >nul 2>&1
    if errorlevel 1 (
        echo  ERROR: Python install failed.
        echo  Please install Python 3.11 from https://python.org
        pause
        exit /b 1
    )
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  OK: %%v

REM ---------- 2. VIRTUAL ENV + DEPS ----------
echo.
echo  [2/4] Checking virtual environment...
if not exist "venv\Scripts\python.exe" (
    echo  Creating venv...
    python -m venv venv
    if errorlevel 1 (
        echo  ERROR: Failed to create virtual environment.
        pause
        exit /b 1
    )
)
echo  Installing dependencies...
venv\Scripts\pip install -q --upgrade pip >nul 2>&1
venv\Scripts\pip install -q -r requirements.txt
if errorlevel 1 (
    echo  ERROR: Failed to install dependencies.
    pause
    exit /b 1
)
echo  OK: venv and dependencies ready.

REM ---------- 3. FFMPEG ----------
echo.
echo  [3/4] Checking FFmpeg...

where ffmpeg >nul 2>&1
if not errorlevel 1 (
    echo  OK: FFmpeg already on PATH.
    goto FFMPEG_DONE
)

REM Check winget install folder even if not on PATH
set "FFMPEG_BIN="
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_*") do (
    for /d %%S in ("%%D\ffmpeg-*") do (
        if exist "%%S\bin\ffmpeg.exe" (
            set "FFMPEG_BIN=%%S\bin"
        )
    )
)
if defined FFMPEG_BIN (
    set "PATH=%PATH%;%FFMPEG_BIN%"
    echo  OK: FFmpeg found at %FFMPEG_BIN%
    goto FFMPEG_DONE
)

REM Not found at all - install via winget
echo  FFmpeg not found. Installing via winget...
winget install --id Gyan.FFmpeg -e --silent --accept-package-agreements --accept-source-agreements

REM Re-check winget folder after install
set "FFMPEG_BIN="
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_*") do (
    for /d %%S in ("%%D\ffmpeg-*") do (
        if exist "%%S\bin\ffmpeg.exe" (
            set "FFMPEG_BIN=%%S\bin"
        )
    )
)
if defined FFMPEG_BIN (
    set "PATH=%PATH%;%FFMPEG_BIN%"
    echo  OK: FFmpeg installed at %FFMPEG_BIN%
    goto FFMPEG_DONE
)

REM winget failed - download zip directly via PowerShell
echo  winget failed. Downloading FFmpeg directly...
set "FFMPEG_DIR=%LOCALAPPDATA%\ffmpeg"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile '%TEMP%\ffmpeg.zip' -UseBasicParsing; Expand-Archive '%TEMP%\ffmpeg.zip' '%FFMPEG_DIR%' -Force"
for /d %%D in ("%FFMPEG_DIR%\ffmpeg-*") do (
    if exist "%%D\bin\ffmpeg.exe" (
        set "FFMPEG_BIN=%%D\bin"
    )
)
if defined FFMPEG_BIN (
    set "PATH=%PATH%;%FFMPEG_BIN%"
    echo  OK: FFmpeg downloaded to %FFMPEG_BIN%
    goto FFMPEG_DONE
)

echo  WARNING: FFmpeg could not be installed. Downloads capped at 720p.
echo  Install manually from https://ffmpeg.org/download.html

:FFMPEG_DONE

REM ---------- 4. START SERVER ----------
echo.
echo  [4/4] Starting server...
echo.
echo  ===================================
echo    Open: http://localhost:8080
echo    Press Ctrl+C to stop
echo  ===================================
echo.

start "" cmd /c "timeout /t 4 /nobreak >nul && start http://localhost:8080"

set PYTHONUTF8=1
set PYTHONIOENCODING=utf-8
venv\Scripts\python.exe main.py

echo.
echo  Server stopped.
pause
