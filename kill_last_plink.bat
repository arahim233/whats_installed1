@echo off

:kill_last_plink
timeout /t 5
taskkill /IM "plink.exe" /T /F >nul 2>nul
exit /b