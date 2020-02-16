@echo off

set plink=%1
if not exist "COM_Logs\" mkdir COM_Logs\
attrib +h COM_logs
(
echo aver
timeout /t 3 >nul 2>nul
echo sm
timeout /4 >nul 2>nul
) | plink.exe -serial %plink% -sercfg 19200,8,n,1,N >"COM_Logs\Found on %plink%"