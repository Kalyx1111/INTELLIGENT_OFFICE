@echo off
setlocal enabledelayedexpansion
title INTELLIGENT OFFICE - Audio Transcription
color 0B

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - AUDIO TRANSCRIBER               ║
echo  ║         Convert audio/video to text using Whisper             ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "LOG=%BASE%logs\transcribe_log.txt"
set "INPUT_DIR=%BASE%input_docs\audio"
set "OUTPUT_DIR=%BASE%output_docs\reports"
set "FFMPEG=%BASE%tools\ffmpeg\ffmpeg.exe"

:: Add FFmpeg to path
set "PATH=%BASE%tools\ffmpeg;%PATH%"

echo  Drop your audio files (.mp3, .wav, .m4a, .ogg, .flac) into:
echo  %INPUT_DIR%
echo.

:: Find audio files
set "FILE_COUNT=0"
for %%F in ("%INPUT_DIR%\*.mp3" "%INPUT_DIR%\*.wav" "%INPUT_DIR%\*.m4a" "%INPUT_DIR%\*.ogg" "%INPUT_DIR%\*.flac" "%INPUT_DIR%\*.mp4" "%INPUT_DIR%\*.mkv" "%INPUT_DIR%\*.avi") do (
    if exist "%%F" (
        set /a FILE_COUNT+=1
        echo  Found: %%~nxF
    )
)

if %FILE_COUNT%==0 (
    echo  ❌ No audio/video files found in input_docs\audio\
    echo.
    echo  Supported formats: .mp3 .wav .m4a .ogg .flac .mp4 .mkv .avi
    pause
    exit /b 1
)

echo.
echo  Found %FILE_COUNT% file(s) to transcribe.
echo.
pause

echo  [%date% %time%] Transcription started >> "%LOG%"

python "%BASE%python_env\scripts\transcribe_audio.py" ^
    --input_dir "%INPUT_DIR%" ^
    --output_dir "%OUTPUT_DIR%" ^
    --ffmpeg "%FFMPEG%" ^
    --model base

if errorlevel 1 (
    echo.
    echo  ❌ Transcription failed. Check logs\transcribe_log.txt
) else (
    echo.
    echo  ✅ Transcription complete!
    echo  Output saved to: %OUTPUT_DIR%
    start "" "%OUTPUT_DIR%"
)

echo  [%date% %time%] Transcription done >> "%LOG%"
pause
