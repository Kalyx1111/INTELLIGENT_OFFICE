@echo off
setlocal enabledelayedexpansion
title INTELLIGENT OFFICE - Step 1: Download Everything
color 0A

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║         INTELLIGENT OFFICE - MASTER DOWNLOADER v1.0           ║
echo  ║         Run this on your INTERNET-connected computer           ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.
echo  This script will download:
echo    [1] Python 3.11 installer
echo    [2] Ollama for Windows
echo    [3] AnythingLLM Desktop app
echo    [4] Umi-OCR (image/PDF text extraction)
echo    [5] FFmpeg (audio/video processing)
echo    [6] Whisper (via Python - offline packages)
echo    [7] Qwen 2.5 7B AI model (via Ollama)
echo    [8] Nomic Embed model (for memory/RAG)
echo    [9] All Python packages (offline bundle)
echo.
echo  ⚠️  ESTIMATED DOWNLOAD SIZE: 12-18 GB
echo  ⚠️  ESTIMATED TIME: 1-3 hours (depends on internet speed)
echo.
echo  Make sure you have at least 25 GB free disk space.
echo.
pause

:: ─── Set base directory ──────────────────────────────────────────────────────
set "BASE=%~dp0"
set "TOOLS=%BASE%tools"
set "OFFLINE=%BASE%offline_packages"
set "OLLAMA_DIR=%BASE%ollama"
set "LOG=%BASE%logs\download_log.txt"

if not exist "%BASE%logs" mkdir "%BASE%logs"
if not exist "%OFFLINE%" mkdir "%OFFLINE%"

echo [%date% %time%] Download started >> "%LOG%"

:: ─── Check internet connection ───────────────────────────────────────────────
echo.
echo  [1/9] Checking internet connection...
ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (
    echo  ❌ ERROR: No internet connection detected!
    echo  Please connect to the internet and try again.
    pause
    exit /b 1
)
echo  ✅ Internet connection confirmed

:: ─── Check for curl and wget ─────────────────────────────────────────────────
where curl >nul 2>&1
if errorlevel 1 (
    echo  ❌ curl not found. Windows 10/11 should have it built-in.
    echo  Please update Windows and try again.
    pause
    exit /b 1
)

:: ─── DOWNLOAD: Python 3.11 ───────────────────────────────────────────────────
echo.
echo  [2/9] Downloading Python 3.11.9...
if not exist "%BASE%tools\python-3.11.9-amd64.exe" (
    curl -L -o "%BASE%tools\python-3.11.9-amd64.exe" ^
    "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
    if errorlevel 1 (
        echo  ❌ Python download failed. Check internet and retry.
        echo [ERROR] Python download failed >> "%LOG%"
    ) else (
        echo  ✅ Python 3.11.9 downloaded
        echo [OK] Python downloaded >> "%LOG%"
    )
) else (
    echo  ✅ Python already downloaded, skipping
)

:: ─── DOWNLOAD: Ollama ─────────────────────────────────────────────────────────
echo.
echo  [3/9] Downloading Ollama for Windows...
if not exist "%OLLAMA_DIR%\OllamaSetup.exe" (
    curl -L -o "%OLLAMA_DIR%\OllamaSetup.exe" ^
    "https://ollama.com/download/OllamaSetup.exe"
    if errorlevel 1 (
        echo  ❌ Ollama download failed.
        echo [ERROR] Ollama download failed >> "%LOG%"
    ) else (
        echo  ✅ Ollama downloaded
        echo [OK] Ollama downloaded >> "%LOG%"
    )
) else (
    echo  ✅ Ollama already downloaded, skipping
)

:: ─── DOWNLOAD: AnythingLLM Desktop ───────────────────────────────────────────
echo.
echo  [4/9] Downloading AnythingLLM Desktop...
if not exist "%BASE%anythingllm\AnythingLLMDesktop.exe" (
    curl -L -o "%BASE%anythingllm\AnythingLLMDesktop.exe" ^
    "https://cdn.anythingllm.com/latest/AnythingLLMDesktop.exe"
    if errorlevel 1 (
        echo  ❌ AnythingLLM download failed.
        echo  ℹ️  Try manually: https://anythingllm.com/download
        echo [ERROR] AnythingLLM download failed >> "%LOG%"
    ) else (
        echo  ✅ AnythingLLM downloaded
        echo [OK] AnythingLLM downloaded >> "%LOG%"
    )
) else (
    echo  ✅ AnythingLLM already downloaded, skipping
)

:: ─── DOWNLOAD: FFmpeg ─────────────────────────────────────────────────────────
echo.
echo  [5/9] Downloading FFmpeg (audio/video processor)...
if not exist "%TOOLS%\ffmpeg\ffmpeg.exe" (
    echo  Downloading FFmpeg builds...
    curl -L -o "%TOOLS%\ffmpeg\ffmpeg-release.zip" ^
    "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    if errorlevel 1 (
        echo  ❌ FFmpeg download failed.
        echo [ERROR] FFmpeg download failed >> "%LOG%"
    ) else (
        echo  Extracting FFmpeg...
        powershell -Command "Expand-Archive -Path '%TOOLS%\ffmpeg\ffmpeg-release.zip' -DestinationPath '%TOOLS%\ffmpeg\extracted' -Force"
        :: Move binaries to expected location
        for /d %%i in ("%TOOLS%\ffmpeg\extracted\*") do (
            copy "%%i\bin\ffmpeg.exe" "%TOOLS%\ffmpeg\" >nul 2>&1
            copy "%%i\bin\ffprobe.exe" "%TOOLS%\ffmpeg\" >nul 2>&1
        )
        del "%TOOLS%\ffmpeg\ffmpeg-release.zip"
        echo  ✅ FFmpeg ready
        echo [OK] FFmpeg downloaded >> "%LOG%"
    )
) else (
    echo  ✅ FFmpeg already present, skipping
)

:: ─── DOWNLOAD: Umi-OCR ───────────────────────────────────────────────────────
echo.
echo  [6/9] Downloading Umi-OCR (image/PDF text extractor)...
if not exist "%TOOLS%\umi-ocr\UmiOCR.exe" (
    curl -L -o "%TOOLS%\umi-ocr\UmiOCR-setup.exe" ^
    "https://github.com/hiroi-sora/Umi-OCR/releases/latest/download/UmiOCR-v2_windows_x64.zip"
    if errorlevel 1 (
        echo  ❌ Umi-OCR download failed.
        echo  ℹ️  Download manually from: https://github.com/hiroi-sora/Umi-OCR
        echo [ERROR] Umi-OCR download failed >> "%LOG%"
    ) else (
        echo  Extracting Umi-OCR...
        powershell -Command "Expand-Archive -Path '%TOOLS%\umi-ocr\UmiOCR-setup.exe' -DestinationPath '%TOOLS%\umi-ocr\' -Force"
        echo  ✅ Umi-OCR downloaded
        echo [OK] Umi-OCR downloaded >> "%LOG%"
    )
) else (
    echo  ✅ Umi-OCR already present, skipping
)

:: ─── INSTALL PYTHON (needed to download packages) ────────────────────────────
echo.
echo  [7/9] Installing Python 3.11 (needed for package download)...
where python >nul 2>&1
if errorlevel 1 (
    if exist "%BASE%tools\python-3.11.9-amd64.exe" (
        echo  Installing Python 3.11...
        "%BASE%tools\python-3.11.9-amd64.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1
        echo  ✅ Python installed
    ) else (
        echo  ❌ Python installer not found. Re-run this script.
    )
) else (
    echo  ✅ Python already installed
)

:: Refresh PATH
call refreshenv >nul 2>&1

:: ─── DOWNLOAD: Python packages (offline bundle) ───────────────────────────────
echo.
echo  [8/9] Downloading Python packages for OFFLINE installation...
echo  This may take 20-40 minutes...
python -m pip install --upgrade pip >nul 2>&1
pip download -r "%BASE%python_env\requirements\requirements.txt" -d "%OFFLINE%" --no-deps
pip download -r "%BASE%python_env\requirements\requirements.txt" -d "%OFFLINE%"
echo  ✅ Python packages downloaded to offline_packages/
echo [OK] Python packages downloaded >> "%LOG%"

:: ─── PULL AI MODELS (via Ollama) ─────────────────────────────────────────────
echo.
echo  [9/9] Downloading AI Models via Ollama...
echo  ⚠️  This is the BIGGEST step - Qwen 7B is ~4.7 GB, Nomic ~274 MB
echo.

:: Check if Ollama is installed
where ollama >nul 2>&1
if errorlevel 1 (
    echo  Ollama not in PATH. Installing now...
    if exist "%OLLAMA_DIR%\OllamaSetup.exe" (
        "%OLLAMA_DIR%\OllamaSetup.exe" /S
        timeout /t 15 /nobreak >nul
        echo  ✅ Ollama installed
    ) else (
        echo  ❌ OllamaSetup.exe not found. Cannot pull models.
        echo  Please install Ollama manually and run this step again.
        goto :skip_models
    )
)

:: Start Ollama service temporarily for download
echo  Starting Ollama service for model download...
start /B ollama serve >"%BASE%logs\ollama_download.log" 2>&1
timeout /t 8 /nobreak >nul

echo  Pulling Qwen 2.5 7B model (main AI brain - ~4.7 GB)...
ollama pull qwen2.5:7b
if errorlevel 1 (
    echo  ❌ Qwen 2.5:7b download failed. Check internet and retry.
    echo [ERROR] qwen2.5:7b pull failed >> "%LOG%"
) else (
    echo  ✅ Qwen 2.5 7B downloaded successfully
    echo [OK] qwen2.5:7b pulled >> "%LOG%"
)

echo.
echo  Pulling Nomic Embed model (document memory - ~274 MB)...
ollama pull nomic-embed-text
if errorlevel 1 (
    echo  ❌ nomic-embed-text download failed.
    echo [ERROR] nomic-embed-text pull failed >> "%LOG%"
) else (
    echo  ✅ Nomic Embed downloaded successfully
    echo [OK] nomic-embed-text pulled >> "%LOG%"
)

:skip_models

:: ─── Copy Ollama models to local models folder ───────────────────────────────
echo.
echo  Copying downloaded models to local models/ folder for portability...
set "OLLAMA_MODELS=%USERPROFILE%\.ollama\models"
if exist "%OLLAMA_MODELS%" (
    xcopy "%OLLAMA_MODELS%" "%BASE%models\ollama_cache\" /E /I /Y /Q
    echo  ✅ Models backed up to models/ollama_cache/
    echo [OK] Models backed up >> "%LOG%"
) else (
    echo  ℹ️  Ollama models folder not found at expected location.
)

:: ─── DONE ────────────────────────────────────────────────────────────────────
echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║                    DOWNLOAD COMPLETE! ✅                       ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.
echo  NEXT STEPS:
echo    1. Run  02_INSTALL_HERE.bat  to install on THIS computer
echo       OR
echo    1. Copy the ENTIRE INTELLIGENT_OFFICE folder to USB drive
echo    2. On your friend's PC: run  02_INSTALL_HERE.bat
echo.
echo  Folder size is now approximately 15-20 GB.
echo.
echo [%date% %time%] Download complete >> "%LOG%"
pause
