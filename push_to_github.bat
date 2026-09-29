@echo off
setlocal
title Push Vercel Wrapper PGRI Matraman ke GitHub
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0push_to_github.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" (
    echo [ERROR] Push dibatalkan atau terjadi kegagalan. Silakan baca pesan di atas.
) else (
    echo [OK] Proses selesai dengan sukses.
)
echo.
pause
exit /b %RESULT%
