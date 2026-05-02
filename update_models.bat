@echo off
title INTELLIGENT OFFICE - Update AI Models
color 0A

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - MODEL UPDATER                   ║
echo  ║         Download newer/better AI models (needs internet)      ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.
echo  ⚠️  This requires an internet connection.
echo  Run this on your INTERNET computer, then copy to friend's PC.
echo.

set "BASE=%~dp0"
set "LOG=%BASE%logs\update_log.txt"

ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (
    echo  ❌ No internet connection.
    pause
    exit /b 1
)

echo  Current AI models:
echo    [1] qwen2.5:7b     → Main AI (already installed, ~4.7 GB)
echo    [2] qwen2.5:3b     → Faster, less RAM, weaker (~2.0 GB)
echo    [3] llama3.2:3b    → Alternative fast model (~2.0 GB)
echo    [4] phi3.5:mini    → Very fast, small (~2.2 GB)
echo    [5] nomic-embed-text → Embedding (already installed)
echo    [6] whisper (base)  → Already via Python
echo    [7] Skip - exit
echo.
set /p "CHOICE=Which model to pull [1-7]: "

echo [%date% %time%] Update started >> "%LOG%"

if "%CHOICE%"=="1" (
    echo Pulling qwen2.5:7b...
    ollama pull qwen2.5:7b
)
if "%CHOICE%"=="2" (
    echo Pulling qwen2.5:3b (faster option)...
    ollama pull qwen2.5:3b
    echo After install, edit config\intelligent_office.conf
    echo Change MODEL=qwen2.5:3b for faster responses
)
if "%CHOICE%"=="3" (
    echo Pulling llama3.2:3b...
    ollama pull llama3.2:3b
)
if "%CHOICE%"=="4" (
    echo Pulling phi3.5:mini...
    ollama pull phi3.5:mini
)
if "%CHOICE%"=="5" (
    echo Pulling nomic-embed-text...
    ollama pull nomic-embed-text
)
if "%CHOICE%"=="6" echo Whisper is installed via Python - no pull needed.
if "%CHOICE%"=="7" goto :done

:: Backup new models
echo.
echo  Backing up models for offline transfer...
set "OLLAMA_MODELS=%USERPROFILE%\.ollama\models"
if exist "%OLLAMA_MODELS%" (
    xcopy "%OLLAMA_MODELS%" "%BASE%models\ollama_cache\" /E /I /Y /Q
    echo  ✅ Models backed up to models\ollama_cache\
    echo  You can now copy the full folder to your friend's PC.
)

:done
echo [%date% %time%] Update done >> "%LOG%"
echo.
echo  Done. Run restart_all.bat to use the new model.
pause
