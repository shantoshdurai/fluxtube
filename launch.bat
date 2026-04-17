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
set "PYTHON_EXE="

REM First, try plain python command
python --version >nul 2>&1
if not errorlevel 1 set "PYTHON_EXE=python"

REM If not on PATH, search common install locations
if not defined PYTHON_EXE (
    for %%P in (
        "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
        "C:\Program Files\Python312\python.exe"
        "C:\Program Files\Python311\python.exe"
        "C:\Program Files\Python310\python.exe"
        "C:\Python312\python.exe"
        "C:\Python311\python.exe"
    ) do (
        if exist %%P if not defined PYTHON_EXE set "PYTHON_EXE=%%~P"
    )
)

REM Still not found - install via winget
if not defined PYTHON_EXE (
    echo  Python not found. Installing via winget...
    where winget >nul 2>&1
    if errorlevel 1 (
        echo  ERROR: winget is not available on this system.
        echo  Please install Python 3.11+ manually from https://python.org
        echo  Make sure to check "Add Python to PATH" during installation.
        pause
        exit /b 1
    )
    winget install --id Python.Python.3.11 -e --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo  ERROR: winget install of Python failed.
        pause
        exit /b 1
    )
    REM Re-scan after install
    for %%P in (
        "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    ) do (
        if exist %%P if not defined PYTHON_EXE set "PYTHON_EXE=%%~P"
    )
    if not defined PYTHON_EXE (
        echo  ERROR: Python installed but could not be located.
        echo  Please restart your computer and try again.
        pause
        exit /b 1
    )
)

for /f "tokens=*" %%v in ('"!PYTHON_EXE!" --version 2^>^&1') do echo  OK: %%v at !PYTHON_EXE!

REM ---------- 2. VIRTUAL ENV + DEPS ----------
echo.
echo  [2/4] Checking virtual environment...
if not exist "venv\Scripts\python.exe" (
    echo  Creating venv...
    "!PYTHON_EXE!" -m venv venv
    if errorlevel 1 (
        echo  ERROR: Failed to create virtual environment.
        pause
        exit /b 1
    )
)
echo  Installing dependencies...
venv\Scripts\python.exe -m pip install -q --upgrade pip >nul 2>&1
venv\Scripts\python.exe -m pip install -q -r requirements.txt >nul 2>&1
if errorlevel 1 (
    echo  Installing dependencies (retrying with output)...
    venv\Scripts\python.exe -m pip install -r requirements.txt
    if errorlevel 1 (
        echo  ERROR: Failed to install dependencies.
        pause
        exit /b 1
    )
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

set "FFMPEG_BIN="
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_*") do (
    for /d %%S in ("%%D\ffmpeg-*") do (
        if exist "%%S\bin\ffmpeg.exe" set "FFMPEG_BIN=%%S\bin"
    )
)
if defined FFMPEG_BIN (
    set "PATH=!PATH!;!FFMPEG_BIN!"
    echo  OK: FFmpeg found at !FFMPEG_BIN!
    goto FFMPEG_DONE
)

echo  FFmpeg not found. Installing via winget...
where winget >nul 2>&1
if not errorlevel 1 (
    winget install --id Gyan.FFmpeg -e --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
    for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_*") do (
        for /d %%S in ("%%D\ffmpeg-*") do (
            if exist "%%S\bin\ffmpeg.exe" set "FFMPEG_BIN=%%S\bin"
        )
    )
    if defined FFMPEG_BIN (
        set "PATH=!PATH!;!FFMPEG_BIN!"
        echo  OK: FFmpeg installed at !FFMPEG_BIN!
        goto FFMPEG_DONE
    )
)

echo  Trying direct download...
set "FFMPEG_DIR=%LOCALAPPDATA%\ffmpeg"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile '%TEMP%\ffmpeg.zip' -UseBasicParsing; Expand-Archive '%TEMP%\ffmpeg.zip' '%FFMPEG_DIR%' -Force" >nul 2>&1
for /d %%D in ("%FFMPEG_DIR%\ffmpeg-*") do (
    if exist "%%D\bin\ffmpeg.exe" set "FFMPEG_BIN=%%D\bin"
)
if defined FFMPEG_BIN (
    set "PATH=!PATH!;!FFMPEG_BIN!"
    echo  OK: FFmpeg downloaded to !FFMPEG_BIN!
    goto FFMPEG_DONE
)

echo  WARNING: FFmpeg install failed. Downloads will be capped at 720p.

:FFMPEG_DONE

REM ---------- 4. START SERVER ----------
echo.
echo  [4/4] Starting server...

for /f "tokens=5" %%p in ('netstat -ano 2^>nul ^| findstr ":8080 " ^| findstr "LISTENING"') do (
    echo  Stopping old server on port 8080...
    taskkill /F /PID %%p >nul 2>&1
)
timeout /t 1 /nobreak >nul

echo.
echo  ===================================
echo    Open: http://localhost:8080
echo    Press Ctrl+C to stop
echo  ===================================
echo.

start "" cmd /c "timeout /t 5 /nobreak >nul && start http://localhost:8080"

set PYTHONUTF8=1
set PYTHONIOENCODING=utf-8
venv\Scripts\python.exe main.py

echo.
echo  Server stopped.
pause
