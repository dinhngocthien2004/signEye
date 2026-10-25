@echo off
title SignEye Backend Server (PostgreSQL)
echo ===================================================
echo     DANG KHOI CHAY SIGNEYE BACKEND SERVER (POSTGRESQL)
echo ===================================================
cd /d "%~dp0backend"

echo May chu API: http://127.0.0.1:8000
echo Trang Admin: http://127.0.0.1:8000/admin
echo Database: PostgreSQL (signeye)
echo.

set DATABASE_URL=postgresql://postgres:12345@localhost:5432/signeye
set DB_HOST=127.0.0.1
set DB_PORT=5432
set DB_NAME=signeye
set DB_USER=postgres
set DB_PASSWORD=12345
set ADMIN_API_KEY=Admin@123456
set PORT=8000

dart run bin/server.dart
pause
