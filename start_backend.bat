@echo off
title SignEye Backend Server
echo ===================================================
echo     DANG KHOI CHAY SIGNEYE BACKEND SERVER (PORT 8000)
echo ===================================================
cd /d "%~dp0backend"
set PGPASSWORD=12345
set DB_PASSWORD=12345
dart run bin/server.dart
pause
