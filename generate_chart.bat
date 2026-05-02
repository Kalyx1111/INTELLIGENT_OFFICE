@echo off
setlocal
title INTELLIGENT OFFICE - Generate Charts
color 0D

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - CHART GENERATOR                 ║
echo  ║         Professional charts via Plotly (offline)              ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "OUTPUT=%BASE%output_docs\charts"

echo  Chart types available:
echo    [1] Bar Chart       - Compare categories
echo    [2] Line Chart      - Show trends over time
echo    [3] Pie Chart       - Show distribution/percentages
echo    [4] 3D Surface      - 3D visualization
echo    [5] Dashboard       - Multiple charts on one page
echo.
set /p "TYPE=Choose chart type [1-5]: "

echo.
set /p "TITLE=Chart title: "
if "%TITLE%"=="" set "TITLE=Business Analysis"

set "CHART_TYPE=bar"
if "%TYPE%"=="2" set "CHART_TYPE=line"
if "%TYPE%"=="3" set "CHART_TYPE=pie"
if "%TYPE%"=="4" set "CHART_TYPE=3d"
if "%TYPE%"=="5" set "CHART_TYPE=dashboard"

echo.
echo  Generating %CHART_TYPE% chart: "%TITLE%"...

python "%BASE%python_env\scripts\charts.py" ^
    --type "%CHART_TYPE%" ^
    --title "%TITLE%" ^
    --output_dir "%OUTPUT%"

if errorlevel 1 (
    echo  ❌ Chart creation failed.
) else (
    echo  ✅ Chart created! Saved to: %OUTPUT%
    start "" "%OUTPUT%"
)
pause
