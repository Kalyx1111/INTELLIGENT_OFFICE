@echo off
title INTELLIGENT OFFICE - Stopping All Services
color 0C

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - SHUTDOWN                        ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "LOG=%BASE%logs\startup_log.txt"
echo [%date% %time%] ===== SHUTDOWN BEGIN ===== >> "%LOG%"

echo  Stopping Watchdog...
taskkill /f /fi "WINDOWTITLE eq IO-Watchdog*" >nul 2>&1
taskkill /f /im python.exe /fi "WINDOWTITLE eq IO-Watchdog*" >nul 2>&1

echo  Stopping AnythingLLM...
taskkill /f /fi "WINDOWTITLE eq AnythingLLM*" >nul 2>&1
taskkill /f /im "AnythingLLM Desktop.exe" >nul 2>&1
taskkill /f /im "AnythingLLMDesktop.exe" >nul 2>&1

echo  Stopping Ollama...
taskkill /f /im ollama.exe >nul 2>&1
taskkill /f /im ollama_llama_server.exe >nul 2>&1

echo  Stopping any background Python tasks...
:: Only kill our specific background tasks, not all python
taskkill /f /fi "WINDOWTITLE eq Ollama Engine*" >nul 2>&1
taskkill /f /fi "WINDOWTITLE eq IO-*" >nul 2>&1

timeout /t 3 /nobreak >nul

:: Verify everything stopped
set "ALL_STOPPED=1"
tasklist | findstr /i "ollama.exe" >nul 2>&1 && set "ALL_STOPPED=0" && echo  ⚠️  Ollama still running
tasklist | findstr /i "AnythingLLM" >nul 2>&1 && set "ALL_STOPPED=0" && echo  ⚠️  AnythingLLM still running

if "%ALL_STOPPED%"=="1" (
    echo.
    echo  ✅ All services stopped cleanly.
) else (
    echo.
    echo  ⚠️  Some processes may still be running.
    echo  Run this script again or use Task Manager.
)

echo [%date% %time%] ===== SHUTDOWN COMPLETE ===== >> "%LOG%"
echo.
pause
