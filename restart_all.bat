@echo off
title INTELLIGENT OFFICE - Restarting All Services
color 0E

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - RESTART                         ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"

echo  Stopping all services...
call "%BASE%stop_all.bat" >nul 2>&1
timeout /t 5 /nobreak >nul

echo  Starting all services...
call "%BASE%start_all.bat"
