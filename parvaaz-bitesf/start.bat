@echo off
chcp 65001 >nul
title Parvaaz PWA Server
cd /d "%~dp0"
echo.
echo Starting Parvaaz server...
powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause
