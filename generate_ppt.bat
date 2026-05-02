@echo off
setlocal
title INTELLIGENT OFFICE - Generate PowerPoint
color 0D

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - PRESENTATION GENERATOR          ║
echo  ║         AI-powered PowerPoint (.pptx) creation                ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "OUTPUT=%BASE%output_docs\presentations"
set "LOG=%BASE%logs\generate_log.txt"

curl -s --connect-timeout 3 "http://127.0.0.1:11434/api/tags" >nul 2>&1
if errorlevel 1 (
    echo  ❌ Ollama is not running! Run start_all.bat first.
    pause
    exit /b 1
)

echo  Enter the TOPIC for your presentation:
echo  (Example: "Digital Marketing Strategy 2025")
echo.
set /p "TOPIC=Topic: "
if "%TOPIC%"=="" ( echo No topic. Exiting. & pause & exit /b 1 )

echo.
echo  How many slides? (5-20 recommended):
set /p "SLIDES=Number of slides [10]: "
if "%SLIDES%"=="" set "SLIDES=10"

echo.
echo  Choose theme:
echo    [1] Corporate Blue   [2] Dark Tech   [3] Clean White   [4] Green Nature
echo.
set /p "THEME=Theme [1]: "
if "%THEME%"=="" set "THEME=1"

echo.
echo  Include charts?
echo    [1] Yes - add data charts   [2] No - text only
echo.
set /p "CHARTS=Include charts [1]: "
if "%CHARTS%"=="" set "CHARTS=1"

echo.
echo  Generating PowerPoint: "%TOPIC%"
echo  %SLIDES% slides, Theme %THEME%
echo  Please wait (45-120 seconds)...
echo.

echo [%date% %time%] Generating PPT: %TOPIC% >> "%LOG%"

python "%BASE%python_env\scripts\create_ppt.py" ^
    --topic "%TOPIC%" ^
    --slides "%SLIDES%" ^
    --theme "%THEME%" ^
    --charts "%CHARTS%" ^
    --output_dir "%OUTPUT%" ^
    --ollama_url "http://127.0.0.1:11434" ^
    --model "qwen2.5:7b"

if errorlevel 1 (
    echo  ❌ PPT generation failed. Check logs\generate_log.txt
) else (
    echo  ✅ PowerPoint created!
    echo  Saved to: %OUTPUT%
    start "" "%OUTPUT%"
)
echo [%date% %time%] PPT done: %TOPIC% >> "%LOG%"
pause
