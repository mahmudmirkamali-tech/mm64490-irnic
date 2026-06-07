@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo  Deploy presf.ir to NetAfraz hosting
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0deploy-ftp.ps1"
echo.
pause
