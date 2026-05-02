@echo off
setlocal
title INTELLIGENT OFFICE - Generate Excel Spreadsheet
color 0D

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - EXCEL GENERATOR                 ║
echo  ║         AI-powered .xlsx spreadsheet with charts              ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "OUTPUT=%BASE%output_docs\spreadsheets"
set "LOG=%BASE%logs\generate_log.txt"

curl -s --connect-timeout 3 "http://127.0.0.1:11434/api/tags" >nul 2>&1
if errorlevel 1 (
    echo  ❌ Ollama is not running! Run start_all.bat first.
    pause
    exit /b 1
)

echo  Enter the TOPIC for your spreadsheet:
echo  (Example: "Q3 Sales Report", "Department Budget 2025")
echo.
set /p "TOPIC=Topic: "
if "%TOPIC%"=="" ( echo No topic. Exiting. & pause & exit /b 1 )

echo.
echo  Generating Excel spreadsheet: "%TOPIC%"
echo  Please wait (30-60 seconds)...
echo.

echo [%date% %time%] Generating Excel: %TOPIC% >> "%LOG%"

python "%BASE%python_env\scripts\generate_excel.py" ^
    --topic "%TOPIC%" ^
    --output_dir "%OUTPUT%" ^
    --ollama_url "http://127.0.0.1:11434" ^
    --model "qwen2.5:7b"

if errorlevel 1 (
    echo  ❌ Excel generation failed.
) else (
    echo  ✅ Excel file created!
    start "" "%OUTPUT%"
)
echo [%date% %time%] Excel done >> "%LOG%"
pause
