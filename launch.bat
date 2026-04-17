@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

cd /d "%~dp0"

echo.
echo ========================================
echo   FluxTube Launcher
echo ========================================
echo.

REM ── 1. PYTHON ────────────────────────────────────────────────────────────────
echo [1/4] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo  [!] Python not found. Trying to install via winget...
    winget install --id Python.Python.3.11 -e --silent --accept-package-agreements --accept-source-agreements
    REM Refresh PATH
    set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts"
    python --version >nul 2>&1
    if errorlevel 1 (
        echo  [ERROR] Python install failed.
        echo  Please install Python 3.11 manually from https://python.org
        pause & exit /b 1
    )
    echo  Python installed.
) else (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  Found: %%v
)

REM ── 2. VIRTUAL ENV ───────────────────────────────────────────────────────────
echo.
echo [2/4] Checking virtual environment...
if not exist "venv\Scripts\python.exe" (
    echo  Creating venv...
    python -m venv venv
    if errorlevel 1 (
        echo  [ERROR] Failed to create virtual environment.
        pause & exit /b 1
    )
    echo  venv created.
) else (
    echo  venv OK.
)

echo  Installing/updating dependencies...
venv\Scripts\pip install -q --upgrade pip >nul 2>&1
venv\Scripts\pip install -q -r requirements.txt
if errorlevel 1 (
    echo  [ERROR] Failed to install dependencies.
    pause & exit /b 1
)
echo  Dependencies OK.

REM ── 3. FFMPEG ────────────────────────────────────────────────────────────────
echo.
echo [3/4] Checking FFmpeg...

REM Check if ffmpeg is already on PATH
where ffmpeg >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('ffmpeg -version 2^>^&1 ^| findstr /i "ffmpeg version"') do echo  Found: %%v
    goto FFMPEG_OK
)

REM Check if winget already installed it (not on PATH yet)
set "FFMPEG_BIN="
for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_*") do (
    for /d %%s in ("%%d\ffmpeg-*") do (
        if exist "%%s\bin\ffmpeg.exe" set "FFMPEG_BIN=%%s\bin"
    )
)
if defined FFMPEG_BIN (
    set "PATH=%PATH%;%FFMPEG_BIN%"
    echo  Found FFmpeg at: %FFMPEG_BIN%
    goto FFMPEG_OK
)

REM Not found anywhere — install via winget
echo  FFmpeg not found. Installing via winget...
winget install --id Gyan.FFmpeg -e --silent --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo  [!] winget install failed. Trying direct download...
    REM Fallback: download a static build via PowerShell
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$url='https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip';" ^
        "$out='%TEMP%\ffmpeg.zip';" ^
        "Invoke-WebRequest $url -OutFile $out -UseBasicParsing;" ^
        "Expand-Archive $out '%LOCALAPPDATA%\ffmpeg' -Force;" ^
        "Write-Host done"
    for /d %%d in ("%LOCALAPPDATA%\ffmpeg\ffmpeg-*") do set "FFMPEG_BIN=%%d\bin"
    if defined FFMPEG_BIN (
        set "PATH=%PATH%;%FFMPEG_BIN%"
        echo  FFmpeg installed via download.
        goto FFMPEG_OK
    )
    echo  [!] FFmpeg could not be installed automatically.
    echo  [!] Downloads will be capped at 720p.
    echo  [!] Install FFmpeg manually: https://ffmpeg.org/download.html
    goto FFMPEG_SKIP
)

REM Winget succeeded — find the bin path
for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_*") do (
    for /d %%s in ("%%d\ffmpeg-*") do (
        if exist "%%s\bin\ffmpeg.exe" set "FFMPEG_BIN=%%s\bin"
    )
)
if defined FFMPEG_BIN (
    set "PATH=%PATH%;%FFMPEG_BIN%"
    echo  FFmpeg installed at: %FFMPEG_BIN%
) else (
    echo  [!] FFmpeg installed but path not found. Restart may be needed.
)

:FFMPEG_OK
echo  FFmpeg OK.
:FFMPEG_SKIP

REM ── 4. START SERVER ──────────────────────────────────────────────────────────
echo.
echo [4/4] Starting server...
echo.
echo ========================================
echo   App running at: http://localhost:8080
echo   Press Ctrl+C to stop
echo ========================================
echo.

REM Open browser after 4 seconds in background
start "" cmd /c "timeout /t 4 /nobreak >nul && start http://localhost:8080"

REM Run server in this window so all logs and errors are visible
set PYTHONUTF8=1
set PYTHONIOENCODING=utf-8
venv\Scripts\python.exe main.py

echo.
echo  Server stopped.
pause
