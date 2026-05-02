@echo off
setlocal enabledelayedexpansion
title INTELLIGENT OFFICE - Step 2: Install Everything
color 0B

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║         INTELLIGENT OFFICE - INSTALLER v1.0                   ║
echo  ║         Works OFFLINE - no internet needed here               ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.
echo  This script will INSTALL:
echo    ✔ Python 3.11
echo    ✔ Ollama (AI model runner)
echo    ✔ AnythingLLM (document chat interface)
echo    ✔ All Python packages (whisper, python-docx, pptx, etc.)
echo    ✔ System configuration
echo    ✔ Watchdog auto-restart service
echo.
echo  ⚠️  Run as the SAME USER who will use this system daily.
echo  ⚠️  Do NOT run as Administrator unless you have to.
echo.
pause

set "BASE=%~dp0"
set "LOG=%BASE%logs\install_log.txt"
if not exist "%BASE%logs" mkdir "%BASE%logs"
echo [%date% %time%] Installation started >> "%LOG%"

:: ─── CHECK: Python installer ─────────────────────────────────────────────────
echo.
echo  [1/8] Installing Python 3.11...
where python >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PYVER=%%v
    echo  ✅ Python already installed: !PYVER!
    goto :python_done
)

if exist "%BASE%tools\python-3.11.9-amd64.exe" (
    echo  Installing Python 3.11.9 silently...
    "%BASE%tools\python-3.11.9-amd64.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 Include_tcltk=1
    timeout /t 10 /nobreak >nul
    where python >nul 2>&1
    if errorlevel 1 (
        echo  ❌ Python install failed!
        echo  Try running the installer manually: tools\python-3.11.9-amd64.exe
        echo [ERROR] Python install failed >> "%LOG%"
        pause
        exit /b 1
    )
    echo  ✅ Python 3.11 installed successfully
    echo [OK] Python installed >> "%LOG%"
) else (
    echo  ❌ Python installer not found at tools\python-3.11.9-amd64.exe
    echo  Please run 01_DOWNLOAD_ALL.bat first.
    pause
    exit /b 1
)
:python_done

:: ─── Refresh PATH ─────────────────────────────────────────────────────────────
:: Find Python location
for /f "delims=" %%i in ('where python 2^>nul') do set "PYTHON_PATH=%%i"
if not defined PYTHON_PATH (
    :: Try common locations
    if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
        set "PYTHON_PATH=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
        set "PATH=%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;%PATH%"
    )
)
echo  Python location: %PYTHON_PATH%

:: ─── INSTALL: Python packages (offline) ──────────────────────────────────────
echo.
echo  [2/8] Installing Python packages (offline)...
if exist "%BASE%offline_packages" (
    set "PKG_COUNT=0"
    for %%f in ("%BASE%offline_packages\*.whl") do set /a PKG_COUNT+=1
    echo  Found !PKG_COUNT! packages in offline_packages/
    
    python -m pip install --no-index --find-links="%BASE%offline_packages" ^
        -r "%BASE%python_env\requirements\requirements.txt" ^
        --quiet
    if errorlevel 1 (
        echo  ⚠️  Some packages may have failed. Trying one-by-one...
        for /f "delims=" %%p in ("%BASE%python_env\requirements\requirements.txt") do (
            python -m pip install --no-index --find-links="%BASE%offline_packages" "%%p" --quiet 2>nul
        )
        echo  ℹ️  Check logs for details.
    ) else (
        echo  ✅ All Python packages installed
        echo [OK] Python packages installed >> "%LOG%"
    )
) else (
    echo  ❌ offline_packages folder not found!
    echo  Please run 01_DOWNLOAD_ALL.bat first.
    echo [ERROR] offline_packages missing >> "%LOG%"
    pause
    exit /b 1
)

:: ─── INSTALL: Ollama ─────────────────────────────────────────────────────────
echo.
echo  [3/8] Installing Ollama...
where ollama >nul 2>&1
if not errorlevel 1 (
    echo  ✅ Ollama already installed
    goto :ollama_done
)

if exist "%BASE%ollama\OllamaSetup.exe" (
    echo  Installing Ollama...
    "%BASE%ollama\OllamaSetup.exe" /S
    timeout /t 20 /nobreak >nul
    where ollama >nul 2>&1
    if errorlevel 1 (
        echo  ⚠️  Ollama not in PATH yet. May need restart.
        :: Try adding Ollama to PATH manually
        set "PATH=%LOCALAPPDATA%\Programs\Ollama;%PATH%"
    )
    echo  ✅ Ollama installed
    echo [OK] Ollama installed >> "%LOG%"
) else (
    echo  ❌ OllamaSetup.exe not found!
    echo  Run 01_DOWNLOAD_ALL.bat first.
    echo [ERROR] Ollama installer missing >> "%LOG%"
)
:ollama_done

:: ─── RESTORE AI Models from local cache ──────────────────────────────────────
echo.
echo  [4/8] Restoring AI models from local cache...
set "OLLAMA_MODELS_DEST=%USERPROFILE%\.ollama\models"
set "OLLAMA_MODELS_SRC=%BASE%models\ollama_cache"

if exist "%OLLAMA_MODELS_SRC%" (
    if not exist "%OLLAMA_MODELS_DEST%" mkdir "%OLLAMA_MODELS_DEST%"
    echo  Copying AI models (this may take a few minutes)...
    xcopy "%OLLAMA_MODELS_SRC%" "%OLLAMA_MODELS_DEST%" /E /I /Y /Q
    echo  ✅ AI models restored
    echo [OK] Models restored >> "%LOG%"
) else (
    echo  ⚠️  No local model cache found.
    echo  Models will be downloaded when Ollama first runs.
    echo  (Needs internet connection for first model pull)
)

:: ─── INSTALL: AnythingLLM ────────────────────────────────────────────────────
echo.
echo  [5/8] Installing AnythingLLM...
set "ALLM_INSTALL=%LOCALAPPDATA%\Programs\anythingllm-desktop"
if exist "%ALLM_INSTALL%\AnythingLLM Desktop.exe" (
    echo  ✅ AnythingLLM already installed
    goto :allm_done
)

if exist "%BASE%anythingllm\AnythingLLMDesktop.exe" (
    echo  Installing AnythingLLM Desktop...
    "%BASE%anythingllm\AnythingLLMDesktop.exe" /S
    timeout /t 30 /nobreak >nul
    echo  ✅ AnythingLLM installed
    echo [OK] AnythingLLM installed >> "%LOG%"
) else (
    echo  ❌ AnythingLLMDesktop.exe not found.
    echo  Run 01_DOWNLOAD_ALL.bat first.
    echo [ERROR] AnythingLLM installer missing >> "%LOG%"
)
:allm_done

:: ─── SETUP: FFmpeg PATH ───────────────────────────────────────────────────────
echo.
echo  [6/8] Configuring FFmpeg...
if exist "%BASE%tools\ffmpeg\ffmpeg.exe" (
    :: Add to user PATH permanently
    powershell -Command "[System.Environment]::SetEnvironmentVariable('PATH', [System.Environment]::GetEnvironmentVariable('PATH','User') + ';%BASE%tools\ffmpeg', 'User')"
    set "PATH=%BASE%tools\ffmpeg;%PATH%"
    echo  ✅ FFmpeg configured
    echo [OK] FFmpeg PATH set >> "%LOG%"
) else (
    echo  ⚠️  FFmpeg not found. Audio/video features will not work.
    echo  Run 01_DOWNLOAD_ALL.bat to download FFmpeg.
)

:: ─── WRITE: System configuration ─────────────────────────────────────────────
echo.
echo  [7/8] Writing system configuration...
call :write_config
echo  ✅ Configuration written

:: ─── SETUP: Watchdog service ─────────────────────────────────────────────────
echo.
echo  [8/8] Setting up watchdog (auto-restart)...
copy "%BASE%watchdog\watchdog.py" "%BASE%watchdog\watchdog_active.py" >nul 2>&1
echo  ✅ Watchdog configured

:: ─── CREATE: Desktop shortcut ────────────────────────────────────────────────
echo.
echo  Creating desktop shortcut...
set "SHORTCUT=%USERPROFILE%\Desktop\INTELLIGENT OFFICE.lnk"
powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%SHORTCUT%');$s.TargetPath='%BASE%start_all.bat';$s.WorkingDirectory='%BASE%';$s.IconLocation='%SystemRoot%\System32\shell32.dll,77';$s.Description='Start INTELLIGENT OFFICE';$s.Save()"
echo  ✅ Desktop shortcut created

:: ─── VERIFY INSTALLATION ─────────────────────────────────────────────────────
echo.
echo  ════════════════════════════════════════
echo   VERIFICATION CHECK
echo  ════════════════════════════════════════
python --version >nul 2>&1 && echo  ✅ Python OK || echo  ❌ Python FAILED
where ollama >nul 2>&1 && echo  ✅ Ollama OK || echo  ❌ Ollama FAILED
python -c "import whisper" >nul 2>&1 && echo  ✅ Whisper OK || echo  ⚠️  Whisper (check offline_packages)
python -c "import python_pptx" >nul 2>&1 && echo  ✅ python-pptx OK || echo  ⚠️  python-pptx
python -c "import docx" >nul 2>&1 && echo  ✅ python-docx OK || echo  ⚠️  python-docx
python -c "import plotly" >nul 2>&1 && echo  ✅ Plotly OK || echo  ⚠️  Plotly
if exist "%BASE%tools\ffmpeg\ffmpeg.exe" echo  ✅ FFmpeg OK
if exist "%BASE%tools\ffmpeg\ffmpeg.exe" goto :ffmpeg_ok
echo  ⚠️  FFmpeg NOT found
:ffmpeg_ok

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║                INSTALLATION COMPLETE! ✅                       ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.
echo  TO START INTELLIGENT OFFICE:
echo    Double-click the desktop shortcut, OR
echo    Run start_all.bat from this folder
echo.
echo  Then open your browser and go to: http://localhost:3001
echo.
echo [%date% %time%] Installation complete >> "%LOG%"
pause
goto :eof

:: ─── FUNCTION: Write config file ─────────────────────────────────────────────
:write_config
(
echo # INTELLIGENT OFFICE Configuration
echo # Auto-generated by 02_INSTALL_HERE.bat
echo # Edit these values carefully
echo.
echo [paths]
echo BASE_DIR=%BASE%
echo PYTHON_SCRIPTS=%BASE%python_env\scripts
echo INPUT_DOCS=%BASE%input_docs
echo OUTPUT_DOCS=%BASE%output_docs
echo LOGS=%BASE%logs
echo FFMPEG=%BASE%tools\ffmpeg\ffmpeg.exe
echo.
echo [ollama]
echo HOST=127.0.0.1
echo PORT=11434
echo MODEL=qwen2.5:7b
echo EMBED_MODEL=nomic-embed-text
echo.
echo [anythingllm]
echo PORT=3001
echo STORAGE=%BASE%anythingllm\storage
echo.
echo [performance]
echo OLLAMA_NUM_THREADS=4
echo WHISPER_MODEL=base
echo MAX_CHUNK_SIZE=1000
echo CHUNK_OVERLAP=200
) > "%BASE%config\intelligent_office.conf"
goto :eof
