@echo off
setlocal
title INTELLIGENT OFFICE - Generate Report
color 0D

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - REPORT GENERATOR                ║
echo  ║         AI-powered DOCX report creation                       ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "OUTPUT=%BASE%output_docs\reports"
set "LOG=%BASE%logs\generate_log.txt"

:: Check Ollama is running
curl -s --connect-timeout 3 "http://127.0.0.1:11434/api/tags" >nul 2>&1
if errorlevel 1 (
    echo  ❌ Ollama is not running!
    echo  Please run start_all.bat first.
    pause
    exit /b 1
)

echo  Enter the TOPIC for your report:
echo  (Examples: "Q3 Sales Summary", "Project Status Update", "Market Analysis")
echo.
set /p "TOPIC=Topic: "

if "%TOPIC%"=="" (
    echo  ❌ No topic entered. Exiting.
    pause
    exit /b 1
)

echo.
echo  Choose report style:
echo    [1] Executive Summary (1-2 pages)
echo    [2] Detailed Report  (3-5 pages)
echo    [3] Full Analysis    (5+ pages)
echo.
set /p "STYLE=Choose [1/2/3]: "
if "%STYLE%"=="" set "STYLE=1"

echo.
echo  Generating report: "%TOPIC%"
echo  This may take 30-90 seconds...
echo.

echo [%date% %time%] Generating report: %TOPIC% >> "%LOG%"

python "%BASE%python_env\scripts\generate_report.py" ^
    --topic "%TOPIC%" ^
    --style "%STYLE%" ^
    --output_dir "%OUTPUT%" ^
    --ollama_url "http://127.0.0.1:11434" ^
    --model "qwen2.5:7b"

if errorlevel 1 (
    echo  ❌ Report generation failed. Check logs\generate_log.txt
) else (
    echo  ✅ Report created successfully!
    echo  Saved to: %OUTPUT%
    start "" "%OUTPUT%"
)

echo [%date% %time%] Report done: %TOPIC% >> "%LOG%"
pause
