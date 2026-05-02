@echo off
setlocal enabledelayedexpansion
title INTELLIGENT OFFICE - Auto Error Fixer
color 0E

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - ERROR FIXER v1.0                ║
echo  ║         Automatically detecting and fixing issues             ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "LOG=%BASE%logs\fix_log.txt"
echo [%date% %time%] Fix started > "%LOG%"

:: ─── FIX 1: Port conflicts ────────────────────────────────────────────────────
echo  [FIX 1] Clearing port conflicts...
:: Kill anything on port 11434 (Ollama)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":11434" ^| findstr "LISTENING"') do (
    echo  Killing PID %%a using port 11434
    taskkill /f /pid %%a >nul 2>&1
    echo [FIXED] Killed PID %%a on 11434 >> "%LOG%"
)
:: Kill anything on port 3001 (AnythingLLM)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":3001" ^| findstr "LISTENING"') do (
    echo  Killing PID %%a using port 3001
    taskkill /f /pid %%a >nul 2>&1
    echo [FIXED] Killed PID %%a on 3001 >> "%LOG%"
)
echo  ✅ Port conflicts cleared

:: ─── FIX 2: Ollama zombie processes ──────────────────────────────────────────
echo.
echo  [FIX 2] Killing Ollama zombie processes...
taskkill /f /im ollama.exe >nul 2>&1
taskkill /f /im ollama_llama_server.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo  ✅ Ollama processes cleared

:: ─── FIX 3: Corrupted Ollama state ───────────────────────────────────────────
echo.
echo  [FIX 3] Checking Ollama model registry...
set "OLLAMA_MODELS=%USERPROFILE%\.ollama\models"
if exist "%OLLAMA_MODELS%" (
    echo  ✅ Ollama models directory exists
) else (
    mkdir "%OLLAMA_MODELS%"
    echo  ✅ Created missing Ollama models directory
    echo [FIXED] Created Ollama models dir >> "%LOG%"
)

:: Check if models backed up and restore if needed
if not exist "%OLLAMA_MODELS%\manifests" (
    if exist "%BASE%models\ollama_cache\manifests" (
        echo  Restoring models from local cache...
        xcopy "%BASE%models\ollama_cache" "%OLLAMA_MODELS%" /E /I /Y /Q
        echo  ✅ Models restored from backup
        echo [FIXED] Models restored from cache >> "%LOG%"
    ) else (
        echo  ⚠️  No model cache found. Qwen model needs re-download.
        echo     (Needs internet - run 01_DOWNLOAD_ALL.bat)
    )
)

:: ─── FIX 4: Missing Python packages ──────────────────────────────────────────
echo.
echo  [FIX 4] Checking and fixing Python packages...
set "MISSING_PKGS="
for %%L in (whisper docx pptx openpyxl pandas plotly requests) do (
    python -c "import %%L" >nul 2>&1
    if errorlevel 1 (
        set "MISSING_PKGS=!MISSING_PKGS! %%L"
    )
)

if defined MISSING_PKGS (
    echo  Missing packages:!MISSING_PKGS!
    echo  Attempting offline reinstall...
    if exist "%BASE%offline_packages" (
        python -m pip install --no-index --find-links="%BASE%offline_packages" ^
            -r "%BASE%python_env\requirements\requirements.txt" --quiet
        echo  ✅ Packages reinstalled from offline cache
        echo [FIXED] Packages reinstalled >> "%LOG%"
    ) else (
        echo  ⚠️  No offline packages found. Run 01_DOWNLOAD_ALL.bat (needs internet)
    )
) else (
    echo  ✅ All Python packages OK
)

:: ─── FIX 5: Missing directories ───────────────────────────────────────────────
echo.
echo  [FIX 5] Recreating any missing directories...
for %%D in (logs config input_docs\audio input_docs\video input_docs\images input_docs\pdfs input_docs\office_docs output_docs\reports output_docs\presentations output_docs\spreadsheets output_docs\charts vector_db\lancedb) do (
    if not exist "%BASE%%%D\" (
        mkdir "%BASE%%%D"
        echo  ✅ Created missing: %%D
        echo [FIXED] Created %%D >> "%LOG%"
    )
)

:: ─── FIX 6: AnythingLLM storage directory ────────────────────────────────────
echo.
echo  [FIX 6] Checking AnythingLLM storage...
if not exist "%BASE%anythingllm\storage" (
    mkdir "%BASE%anythingllm\storage"
    echo  ✅ Created AnythingLLM storage directory
    echo [FIXED] Created ALLM storage dir >> "%LOG%"
) else (
    echo  ✅ AnythingLLM storage directory OK
)

:: ─── FIX 7: Config file ───────────────────────────────────────────────────────
echo.
echo  [FIX 7] Checking configuration file...
if not exist "%BASE%config\intelligent_office.conf" (
    echo  Regenerating config file...
    (
        echo # INTELLIGENT OFFICE Configuration - Auto-regenerated
        echo [ollama]
        echo HOST=127.0.0.1
        echo PORT=11434
        echo MODEL=qwen2.5:7b
        echo EMBED_MODEL=nomic-embed-text
        echo.
        echo [anythingllm]
        echo PORT=3001
        echo.
        echo [performance]
        echo OLLAMA_NUM_THREADS=4
        echo WHISPER_MODEL=base
    ) > "%BASE%config\intelligent_office.conf"
    echo  ✅ Config regenerated
    echo [FIXED] Config regenerated >> "%LOG%"
) else (
    echo  ✅ Config file OK
)

:: ─── FIX 8: Clear log files if too large ─────────────────────────────────────
echo.
echo  [FIX 8] Checking log file sizes...
for %%F in ("%BASE%logs\*.log") do (
    for %%S in ("%%F") do (
        if %%~zS gtr 10485760 (
            echo  Trimming large log: %%~nxF
            echo [Log trimmed on %date%] > "%%F"
            echo [FIXED] Trimmed %%~nxF >> "%LOG%"
        )
    )
)
echo  ✅ Log files OK

:: ─── DONE ────────────────────────────────────────────────────────────────────
echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║              ERROR FIXING COMPLETE ✅                          ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.
echo  NEXT: Run start_all.bat to restart services
echo  If issues persist, run crash_recovery.bat
echo.
echo [%date% %time%] Fix complete >> "%LOG%"
pause
