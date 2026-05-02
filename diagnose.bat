@echo off
setlocal enabledelayedexpansion
title INTELLIGENT OFFICE - System Diagnosis
color 0B

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - DIAGNOSIS TOOL v1.0             ║
echo  ║         Checking all components... please wait                ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "LOG=%BASE%logs\diagnose_log.txt"
if not exist "%BASE%logs" mkdir "%BASE%logs"

set "PASS=0"
set "WARN=0"
set "FAIL=0"

echo [%date% %time%] Diagnosis started > "%LOG%"
echo.
echo  ════════════════════════════════════════
echo   SECTION 1: SOFTWARE INSTALLATION
echo  ════════════════════════════════════════

:: ─── Python ──────────────────────────────────────────────────────────────────
where python >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do (
        echo  ✅ Python installed: %%v
        echo [OK] Python %%v >> "%LOG%"
        set /a PASS+=1
    )
) else (
    echo  ❌ Python NOT installed
    echo [FAIL] Python not found >> "%LOG%"
    set /a FAIL+=1
)

:: ─── pip ─────────────────────────────────────────────────────────────────────
python -m pip --version >nul 2>&1
if not errorlevel 1 (
    echo  ✅ pip installed
    set /a PASS+=1
) else (
    echo  ❌ pip not working
    set /a FAIL+=1
)

:: ─── Ollama ──────────────────────────────────────────────────────────────────
where ollama >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('ollama --version 2^>^&1') do (
        echo  ✅ Ollama installed: %%v
        echo [OK] Ollama %%v >> "%LOG%"
        set /a PASS+=1
    )
) else (
    echo  ❌ Ollama NOT installed
    echo [FAIL] Ollama not found >> "%LOG%"
    set /a FAIL+=1
)

:: ─── AnythingLLM ─────────────────────────────────────────────────────────────
set "ALLM_FOUND=0"
if exist "%LOCALAPPDATA%\Programs\anythingllm-desktop\AnythingLLM Desktop.exe" set "ALLM_FOUND=1"
if exist "%PROGRAMFILES%\AnythingLLM Desktop\AnythingLLM Desktop.exe" set "ALLM_FOUND=1"
if "%ALLM_FOUND%"=="1" (
    echo  ✅ AnythingLLM installed
    set /a PASS+=1
) else (
    echo  ❌ AnythingLLM NOT installed
    set /a FAIL+=1
)

:: ─── FFmpeg ──────────────────────────────────────────────────────────────────
if exist "%BASE%tools\ffmpeg\ffmpeg.exe" (
    echo  ✅ FFmpeg found
    set /a PASS+=1
) else (
    where ffmpeg >nul 2>&1
    if not errorlevel 1 (
        echo  ✅ FFmpeg found in system PATH
        set /a PASS+=1
    ) else (
        echo  ⚠️  FFmpeg not found (audio/video processing disabled)
        set /a WARN+=1
    )
)

:: ─── Python Libraries ─────────────────────────────────────────────────────────
echo.
echo  ════════════════════════════════════════
echo   SECTION 2: PYTHON LIBRARIES
echo  ════════════════════════════════════════

set "LIBS=whisper python_docx pptx openpyxl pandas plotly requests chromadb"
for %%L in (%LIBS%) do (
    python -c "import %%L" >nul 2>&1
    if not errorlevel 1 (
        echo  ✅ %%L
        set /a PASS+=1
    ) else (
        :: Try alternate import names
        if "%%L"=="python_docx" python -c "import docx" >nul 2>&1 && (
            echo  ✅ python-docx
            set /a PASS+=1
        ) || (
            echo  ⚠️  %%L not installed
            set /a WARN+=1
        )
        if not "%%L"=="python_docx" (
            echo  ⚠️  %%L not installed
            set /a WARN+=1
        )
    )
)

:: ─── SERVICES RUNNING ─────────────────────────────────────────────────────────
echo.
echo  ════════════════════════════════════════
echo   SECTION 3: SERVICES STATUS
echo  ════════════════════════════════════════

:: Ollama service
curl -s --connect-timeout 3 "http://127.0.0.1:11434/api/tags" >nul 2>&1
if not errorlevel 1 (
    echo  ✅ Ollama service RUNNING on port 11434
    set /a PASS+=1
    echo [OK] Ollama service up >> "%LOG%"
) else (
    echo  ❌ Ollama service NOT running (start with start_all.bat)
    set /a FAIL+=1
    echo [FAIL] Ollama not responding >> "%LOG%"
)

:: AnythingLLM service
curl -s --connect-timeout 3 "http://127.0.0.1:3001" >nul 2>&1
if not errorlevel 1 (
    echo  ✅ AnythingLLM RUNNING on port 3001
    set /a PASS+=1
) else (
    echo  ⚠️  AnythingLLM not responding on port 3001
    echo     (Normal if just started - wait 30 seconds)
    set /a WARN+=1
)

:: ─── PORTS CHECK ─────────────────────────────────────────────────────────────
echo.
echo  ════════════════════════════════════════
echo   SECTION 4: PORTS
echo  ════════════════════════════════════════

for %%P in (11434 3001 8080) do (
    netstat -an | findstr ":%%P " | findstr "LISTEN" >nul 2>&1
    if not errorlevel 1 (
        echo  ✅ Port %%P is OPEN (service running)
    ) else (
        echo  ○  Port %%P is closed (service not running)
    )
)

:: ─── MODELS CHECK ────────────────────────────────────────────────────────────
echo.
echo  ════════════════════════════════════════
echo   SECTION 5: AI MODELS
echo  ════════════════════════════════════════

curl -s --connect-timeout 3 "http://127.0.0.1:11434/api/tags" > "%TEMP%\io_models.json" 2>nul
if exist "%TEMP%\io_models.json" (
    findstr /i "qwen2.5" "%TEMP%\io_models.json" >nul 2>&1
    if not errorlevel 1 (
        echo  ✅ Qwen 2.5 7B model: AVAILABLE
        set /a PASS+=1
    ) else (
        echo  ❌ Qwen 2.5 7B model: NOT FOUND
        echo     Run: ollama pull qwen2.5:7b
        set /a FAIL+=1
    )
    findstr /i "nomic-embed" "%TEMP%\io_models.json" >nul 2>&1
    if not errorlevel 1 (
        echo  ✅ Nomic Embed model: AVAILABLE
        set /a PASS+=1
    ) else (
        echo  ⚠️  Nomic Embed model: NOT FOUND
        echo     Run: ollama pull nomic-embed-text
        set /a WARN+=1
    )
    del "%TEMP%\io_models.json" >nul 2>&1
) else (
    echo  ⚠️  Cannot check models (Ollama not running)
    set /a WARN+=1
)

:: ─── DISK SPACE ──────────────────────────────────────────────────────────────
echo.
echo  ════════════════════════════════════════
echo   SECTION 6: DISK SPACE
echo  ════════════════════════════════════════

for /f "tokens=3" %%s in ('dir "%BASE%" /-c 2^>nul ^| findstr "bytes free"') do (
    set "FREE_BYTES=%%s"
)
:: Rough GB calculation (divide by 1 billion)
set /a FREE_GB=0
if defined FREE_BYTES (
    set /a FREE_GB=!FREE_BYTES:~0,-9!
    if !FREE_GB! lss 2 (
        echo  ❌ LOW DISK SPACE: Less than 2 GB free!
        set /a FAIL+=1
    ) else (
        echo  ✅ Disk space: ~!FREE_GB! GB free
        set /a PASS+=1
    )
)

:: ─── RAM CHECK ───────────────────────────────────────────────────────────────
echo.
echo  ════════════════════════════════════════
echo   SECTION 7: MEMORY (RAM)
echo  ════════════════════════════════════════

for /f "skip=1 tokens=2" %%r in ('wmic OS get FreePhysicalMemory') do (
    set /a FREE_MB=%%r/1024
    if !FREE_MB! lss 2048 (
        echo  ⚠️  Low free RAM: ~!FREE_MB! MB available
        echo     Close other programs for better AI performance
        set /a WARN+=1
    ) else (
        echo  ✅ Free RAM: ~!FREE_MB! MB available
        set /a PASS+=1
    )
    goto :ram_done
)
:ram_done

:: ─── FOLDER STRUCTURE ────────────────────────────────────────────────────────
echo.
echo  ════════════════════════════════════════
echo   SECTION 8: FOLDER STRUCTURE
echo  ════════════════════════════════════════

for %%D in (ollama models anythingllm vector_db tools python_env input_docs output_docs logs config watchdog offline_packages) do (
    if exist "%BASE%%%D\" (
        echo  ✅ %%D/
    ) else (
        echo  ⚠️  %%D/ is missing
        set /a WARN+=1
    )
)

:: ─── FINAL REPORT ────────────────────────────────────════════════════════════
echo.
echo  ════════════════════════════════════════
echo   DIAGNOSIS SUMMARY
echo  ════════════════════════════════════════
echo.
echo  ✅ PASSED:   %PASS% checks
echo  ⚠️  WARNINGS: %WARN% checks
echo  ❌ FAILED:   %FAIL% checks
echo.

if %FAIL% gtr 0 (
    echo  ❗ ISSUES FOUND - Run fix_errors.bat to auto-fix
    color 0C
) else if %WARN% gtr 3 (
    echo  ⚠️  MINOR ISSUES - System should still work
    color 0E
) else (
    echo  🎉 System looks healthy!
    color 0A
)

echo.
echo [%date% %time%] Diagnosis complete: %PASS% pass, %WARN% warn, %FAIL% fail >> "%LOG%"
echo  Full log saved: logs\diagnose_log.txt
echo.
pause
