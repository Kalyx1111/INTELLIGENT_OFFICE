@echo off
setlocal
title INTELLIGENT OFFICE - OCR (Image to Text)
color 0B

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - OCR ENGINE                      ║
echo  ║         Extract text from images and scanned PDFs             ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.

set "BASE=%~dp0"
set "INPUT_IMAGES=%BASE%input_docs\images"
set "INPUT_PDFS=%BASE%input_docs\pdfs"
set "OUTPUT_DIR=%BASE%output_docs\reports"
set "LOG=%BASE%logs\ocr_log.txt"

echo  Supported inputs:
echo    Images:  .jpg .jpeg .png .bmp .tiff .webp
echo    PDFs:    .pdf (scanned/image-based)
echo.
echo  Drop files in:
echo    %INPUT_IMAGES%
echo    %INPUT_PDFS%
echo.

:: Count files
set "TOTAL=0"
for %%F in ("%INPUT_IMAGES%\*.jpg" "%INPUT_IMAGES%\*.jpeg" "%INPUT_IMAGES%\*.png" "%INPUT_IMAGES%\*.bmp" "%INPUT_IMAGES%\*.tiff") do (
    if exist "%%F" (
        set /a TOTAL+=1
        echo  Image: %%~nxF
    )
)
for %%F in ("%INPUT_PDFS%\*.pdf") do (
    if exist "%%F" (
        set /a TOTAL+=1
        echo  PDF:   %%~nxF
    )
)

if %TOTAL%==0 (
    echo  ❌ No image or PDF files found in input folders.
    pause
    exit /b 1
)

echo.
echo  Found %TOTAL% file(s) to process.
pause

echo [%date% %time%] OCR started >> "%LOG%"

python "%BASE%python_env\scripts\ocr_extract.py" ^
    --image_dir "%INPUT_IMAGES%" ^
    --pdf_dir "%INPUT_PDFS%" ^
    --output_dir "%OUTPUT_DIR%"

if errorlevel 1 (
    echo  ❌ OCR failed. Check logs\ocr_log.txt
) else (
    echo.
    echo  ✅ OCR complete! Text files saved to:
    echo  %OUTPUT_DIR%
    start "" "%OUTPUT_DIR%"
)

echo [%date% %time%] OCR done >> "%LOG%"
pause
