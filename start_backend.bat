@echo off
title SignEye Backend Server
echo ===================================================
echo     DANG KHOI CHAY SIGNEYE BACKEND SERVER (PORT 8000)
echo ===================================================
cd /d "%~dp0backend"

if exist ".venv\Scripts\uvicorn.exe" (
    echo Khoi chay Python FastAPI Server (SQLite Database)...
    echo May chu API: http://127.0.0.1:8000
    echo Trang Admin: http://127.0.0.1:8000/admin
    echo.
    ".venv\Scripts\uvicorn.exe" main:app --host 0.0.0.0 --port 8000 --reload
) else (
    echo Khoi chay Dart Backend Server...
    set PGPASSWORD=12345
    set DB_PASSWORD=12345
    dart run bin/server.dart
)
pause

