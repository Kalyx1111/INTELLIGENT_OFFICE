@echo off
setlocal enabledelayedexpansion
title INTELLIGENT OFFICE - CRASH RECOVERY
color 0C

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - CRASH RECOVERY v1.0             ║
echo  ║         Full system recovery - use when nothing else works    ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.
echo  This will:
echo    1. Force-kill ALL related processes
echo    2. Clear all temporary/lock files
echo    3. Restore from backups where possible
echo    4. Rebuild any corrupt config files
echo    5. Restart everything fresh
echo.
echo  ⚠️  This is a HARD RESET. Chat history is preserved.
echo  ⚠️  Your uploaded documents are preserved.
echo.
pause

set "BASE=%~dp0"
set "LOG=%BASE%logs\recovery_log.txt"
echo [%date% %time%] ===== CRASH RECOVERY STARTED ===== >> "%LOG%"

echo.
echo  ─────────────────────────────────────────
echo  PHASE 1: NUCLEAR PROCESS KILL
echo  ─────────────────────────────────────────

echo  Killing all AI-related processes...
taskkill /f /im ollama.exe >nul 2>&1
taskkill /f /im ollama_llama_server.exe >nul 2>&1
taskkill /f /im "AnythingLLM Desktop.exe" >nul 2>&1
taskkill /f /im node.exe >nul 2>&1

:: Kill our Python processes
for /f "tokens=1,2" %%a in ('tasklist /fo csv ^| findstr /i "python"') do (
    set "PNAME=%%~a"
    set "PPID=%%~b"
    wmic process where "ProcessId='!PPID!'" get CommandLine 2>nul | findstr /i "watchdog\|intelligent_office\|ingest\|whisper_" >nul 2>&1
    if not errorlevel 1 (
        taskkill /f /pid !PPID! >nul 2>&1
        echo  Killed Python process: !PPID!
    )
)

timeout /t 5 /nobreak >nul
echo  ✅ Processes cleared

echo.
echo  ─────────────────────────────────────────
echo  PHASE 2: CLEAR TEMP / LOCK FILES
echo  ─────────────────────────────────────────

:: Clear Ollama lock files
if exist "%USERPROFILE%\.ollama\*.lock" (
    del "%USERPROFILE%\.ollama\*.lock" /f >nul 2>&1
    echo  ✅ Cleared Ollama lock files
)

:: Clear Ollama running file
if exist "%USERPROFILE%\.ollama\id.lock" del "%USERPROFILE%\.ollama\id.lock" /f >nul 2>&1

:: Clear AnythingLLM temp
if exist "%APPDATA%\anythingllm-desktop\*.tmp" (
    del "%APPDATA%\anythingllm-desktop\*.tmp" /f >nul 2>&1
)
if exist "%APPDATA%\anythingllm-desktop\temp" (
    rd /s /q "%APPDATA%\anythingllm-desktop\temp" >nul 2>&1
    mkdir "%APPDATA%\anythingllm-desktop\temp" >nul 2>&1
)

:: Clear Python cache that might be corrupt
for /d %%c in ("%BASE%python_env\scripts\__pycache__") do (
    if exist "%%c" rd /s /q "%%c" >nul 2>&1
)

echo  ✅ Temporary files cleared

echo.
echo  ─────────────────────────────────────────
echo  PHASE 3: RESTORE FROM BACKUPS
echo  ─────────────────────────────────────────

:: Restore Ollama models if corrupted
set "OLLAMA_MODELS=%USERPROFILE%\.ollama\models"
if exist "%BASE%models\ollama_cache" (
    echo  Checking model integrity...
    if not exist "%OLLAMA_MODELS%\manifests\registry.ollama.ai\library\qwen2.5" (
        echo  Models appear missing/corrupt. Restoring from backup...
        if not exist "%OLLAMA_MODELS%" mkdir "%OLLAMA_MODELS%"
        xcopy "%BASE%models\ollama_cache" "%OLLAMA_MODELS%" /E /I /Y /Q
        echo  ✅ Models restored from local backup
        echo [RESTORED] Models from cache >> "%LOG%"
    ) else (
        echo  ✅ Models appear intact
    )
) else (
    echo  ⚠️  No model backup found in models\ollama_cache
    echo     If models are lost, re-run 01_DOWNLOAD_ALL.bat
)

echo.
echo  ─────────────────────────────────────────
echo  PHASE 4: REBUILD CONFIGURATION
echo  ─────────────────────────────────────────

:: Always regenerate config on recovery
(
    echo # INTELLIGENT OFFICE Configuration - RECOVERY REBUILD
    echo # Rebuilt on %date% at %time%
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
echo  ✅ Configuration rebuilt

:: Rebuild directories
for %%D in (logs config input_docs\audio input_docs\video input_docs\images input_docs\pdfs input_docs\office_docs output_docs\reports output_docs\presentations output_docs\spreadsheets output_docs\charts vector_db\lancedb anythingllm\storage watchdog) do (
    if not exist "%BASE%%%D\" (
        mkdir "%BASE%%%D"
        echo  Rebuilt: %%D
    )
)
echo  ✅ Directory structure verified

echo.
echo  ─────────────────────────────────────────
echo  PHASE 5: FRESH RESTART
echo  ─────────────────────────────────────────
echo.
echo  Recovery complete. Starting services fresh...
timeout /t 3 /nobreak >nul
call "%BASE%start_all.bat"

echo [%date% %time%] ===== CRASH RECOVERY COMPLETE ===== >> "%LOG%"
