@echo off
setlocal
title INTELLIGENT OFFICE - Ingest Documents into AI Memory
color 0B

echo.
echo  ╔════════════════════════════════════════════════════════════════╗
echo  ║          INTELLIGENT OFFICE - DOCUMENT INGESTION              ║
echo  ║         Load documents into AI knowledge base                 ║
echo  ╚════════════════════════════════════════════════════════════════╝
echo.
echo  This will:
echo    1. Scan input_docs/ for all supported files
echo    2. Extract text from each document
echo    3. Split text into searchable chunks
echo    4. Generate embeddings via Nomic Embed
echo    5. Store everything in the vector database
echo.
echo  After this, you can ask AnythingLLM questions about your docs!
echo.
echo  Supported: .docx .pdf .xlsx .csv .pptx .txt .md
echo.

set "BASE=%~dp0"
set "INPUT=%BASE%input_docs"
set "VECTOR_DB=%BASE%vector_db"
set "LOG=%BASE%logs\ingest_log.txt"

:: Check Ollama
curl -s --connect-timeout 3 "http://127.0.0.1:11434/api/tags" >nul 2>&1
if errorlevel 1 (
    echo  ❌ Ollama not running! Start it first with start_all.bat
    pause
    exit /b 1
)
echo  ✅ Ollama is running

echo.
echo  Which documents to ingest?
echo    [1] All new documents (skip already ingested)
echo    [2] All documents (re-ingest everything)
echo    [3] Single specific file
echo.
set /p "CHOICE=Choice [1]: "
if "%CHOICE%"=="" set "CHOICE=1"

echo.
echo [%date% %time%] Ingestion started >> "%LOG%"

if "%CHOICE%"=="1" (
    python "%BASE%python_env\scripts\ingest.py" ^
        --input_dir "%INPUT%" ^
        --vector_db_dir "%VECTOR_DB%"
)

if "%CHOICE%"=="2" (
    echo  ⚠️  Re-ingesting ALL documents (this may take a while)...
    python "%BASE%python_env\scripts\ingest.py" ^
        --input_dir "%INPUT%" ^
        --vector_db_dir "%VECTOR_DB%" ^
        --no_skip
)

if "%CHOICE%"=="3" (
    echo.
    echo  Enter the FULL PATH to the file:
    set /p "FILE_PATH=File path: "
    python "%BASE%python_env\scripts\ingest.py" ^
        --input_dir "%INPUT%" ^
        --vector_db_dir "%VECTOR_DB%" ^
        --file "!FILE_PATH!"
)

echo.
echo [%date% %time%] Ingestion done >> "%LOG%"
echo.
echo  ✅ Done! Your documents are now in the AI knowledge base.
echo  Open AnythingLLM at http://localhost:3001 and ask questions!
echo.
pause
