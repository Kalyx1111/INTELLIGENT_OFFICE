@echo off
setlocal enabledelayedexpansion
title INTELLIGENT OFFICE - Starting All Services...
color 0A

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║              INTELLIGENT OFFICE - STARTUP v1.0                ║
echo  ║         Starting all AI services... please wait               ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "LOG=%BASE%logs\startup_log.txt"
set "FFMPEG=%BASE%tools\ffmpeg"
set "CONFIG=%BASE%config\intelligent_office.conf"

if not exist "%BASE%logs" mkdir "%BASE%logs"
echo [%date% %time%] ===== STARTUP BEGIN ===== >> "%LOG%"

:: ─── Add tools to PATH ────────────────────────────────────────────────────────
set "PATH=%FFMPEG%;%PATH%"
set "PATH=%LOCALAPPDATA%\Programs\Ollama;%PATH%"

:: ─── Read config ──────────────────────────────────────────────────────────────
set "OLLAMA_PORT=11434"
set "ALLM_PORT=3001"
set "OLLAMA_MODEL=qwen2.5:7b"
set "EMBED_MODEL=nomic-embed-text"
set "OLLAMA_NUM_THREADS=4"

for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG%") do (
    if "%%a"=="PORT" set "OLLAMA_PORT=%%b"
    if "%%a"=="MODEL" set "OLLAMA_MODEL=%%b"
    if "%%a"=="EMBED_MODEL" set "EMBED_MODEL=%%b"
    if "%%a"=="OLLAMA_NUM_THREADS" set "OLLAMA_NUM_THREADS=%%b"
)

:: ─── STEP 1: Kill any leftover processes ─────────────────────────────────────
echo  [STEP 1/6] Cleaning up any leftover processes...
taskkill /f /im ollama.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo  ✅ Clean slate ready

:: ─── STEP 2: Start Ollama service ────────────────────────────────────────────
echo.
echo  [STEP 2/6] Starting Ollama AI Engine...
where ollama >nul 2>&1
if errorlevel 1 (
    echo  ❌ Ollama not found! Run 02_INSTALL_HERE.bat first.
    echo [ERROR] Ollama not found at startup >> "%LOG%"
    pause
    exit /b 1
)

:: Set environment for Ollama
set "OLLAMA_HOST=127.0.0.1:%OLLAMA_PORT%"
set "OLLAMA_NUM_PARALLEL=1"
set "OLLAMA_MAX_LOADED_MODELS=2"
set "OLLAMA_KEEP_ALIVE=10m"

start "Ollama Engine" /MIN cmd /c "ollama serve >> "%BASE%logs\ollama.log" 2>&1"
echo  Waiting for Ollama to initialize...
timeout /t 8 /nobreak >nul

:: Verify Ollama is running
:check_ollama
curl -s "http://127.0.0.1:%OLLAMA_PORT%/api/tags" >nul 2>&1
if errorlevel 1 (
    echo  Ollama still loading... waiting 5 more seconds
    timeout /t 5 /nobreak >nul
    set /a OLLAMA_WAIT+=1
    if !OLLAMA_WAIT! lss 6 goto :check_ollama
    echo  ❌ Ollama failed to start! Check logs\ollama.log
    echo [ERROR] Ollama did not respond >> "%LOG%"
) else (
    echo  ✅ Ollama Engine running on port %OLLAMA_PORT%
    echo [OK] Ollama started >> "%LOG%"
)

:: ─── STEP 3: Load Qwen model (pre-warm) ──────────────────────────────────────
echo.
echo  [STEP 3/6] Pre-loading Qwen 2.5 7B model into memory...
echo  (This takes 20-60 seconds on first load - normal!)
start "" /MIN cmd /c "ollama run %OLLAMA_MODEL% \"Say: INTELLIGENT OFFICE is ready\" >> "%BASE%logs\model_warmup.log" 2>&1"
echo  ✅ Qwen model loading in background...
echo [OK] Model warmup triggered >> "%LOG%"

:: ─── STEP 4: Load embedding model ────────────────────────────────────────────
echo.
echo  [STEP 4/6] Pre-loading Nomic Embed (memory encoder)...
start "" /MIN cmd /c "ollama run %EMBED_MODEL% \"test\" >> "%BASE%logs\embed_warmup.log" 2>&1"
echo  ✅ Nomic Embed loading in background...
echo [OK] Embed model warmup triggered >> "%LOG%"

:: ─── STEP 5: Start AnythingLLM ───────────────────────────────────────────────
echo.
echo  [STEP 5/6] Starting AnythingLLM (Document Chat Interface)...

:: Look for AnythingLLM executable
set "ALLM_EXE="
if exist "%LOCALAPPDATA%\Programs\anythingllm-desktop\AnythingLLM Desktop.exe" (
    set "ALLM_EXE=%LOCALAPPDATA%\Programs\anythingllm-desktop\AnythingLLM Desktop.exe"
)
if exist "%PROGRAMFILES%\AnythingLLM Desktop\AnythingLLM Desktop.exe" (
    set "ALLM_EXE=%PROGRAMFILES%\AnythingLLM Desktop\AnythingLLM Desktop.exe"
)
if exist "%BASE%anythingllm\AnythingLLM Desktop.exe" (
    set "ALLM_EXE=%BASE%anythingllm\AnythingLLM Desktop.exe"
)

if defined ALLM_EXE (
    :: Set AnythingLLM storage to our local folder
    set "STORAGE_DIR=%BASE%anythingllm\storage"
    if not exist "!STORAGE_DIR!" mkdir "!STORAGE_DIR!"
    set "ANYTHING_LLM_STORAGE=!STORAGE_DIR!"
    start "AnythingLLM" "!ALLM_EXE!"
    echo  ✅ AnythingLLM started
    echo [OK] AnythingLLM started >> "%LOG%"
) else (
    echo  ❌ AnythingLLM not found! Run 02_INSTALL_HERE.bat
    echo [ERROR] AnythingLLM exe not found >> "%LOG%"
)

:: ─── STEP 6: Start Watchdog ───────────────────────────────────────────────────
echo.
echo  [STEP 6/6] Starting Watchdog (crash protection)...
if exist "%BASE%watchdog\watchdog.py" (
    start "IO-Watchdog" /MIN cmd /c "python "%BASE%watchdog\watchdog.py" >> "%BASE%logs\watchdog.log" 2>&1"
    echo  ✅ Watchdog running (auto-restarts crashed services)
    echo [OK] Watchdog started >> "%LOG%"
) else (
    echo  ⚠️  Watchdog script not found - skipping
)

:: ─── STARTUP COMPLETE ────────────────────────────────────────────────────────
echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║              ALL SERVICES STARTED! ✅                          ║
echo  ╠════════════════════════════════════════════════════════════════╣
echo  ║  🧠 Ollama (AI Engine)  → http://localhost:%OLLAMA_PORT%          ║
echo  ║  💬 AnythingLLM (Chat)  → http://localhost:%ALLM_PORT%           ║
echo  ╠════════════════════════════════════════════════════════════════╣
echo  ║  ⏳ FIRST USE: Wait 30-60 seconds for models to fully load    ║
echo  ║  📖 Open browser → http://localhost:%ALLM_PORT%                ║
echo  ║  📁 Drop files in input_docs/ to process them                 ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

:: Auto-open browser after 15 seconds
echo  Opening AnythingLLM in browser in 15 seconds...
echo  (Close this window to cancel browser open)
timeout /t 15 /nobreak >nul
start "" "http://localhost:%ALLM_PORT%"

echo [%date% %time%] ===== STARTUP COMPLETE ===== >> "%LOG%"
echo.
echo  Services are running. You can minimize this window.
echo  Run stop_all.bat when you want to shut down.
pause
