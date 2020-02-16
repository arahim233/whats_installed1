@echo off
if not exist "Temp\" mkdir Temp\ 2>nul
attrib +h Temp
if not exist "COM_Logs\" mkdir COM_Logs\ 2>nul
attrib +h COM_Logs
mode >coms.txt
::for /f "tokens=4 delims=: " %%A in ('mode^|findstr "COM[0-9]*:"') do set plink=%%A && call :launch_plinks
for /f "tokens=4 delims=: " %%A in ('FINDSTR /c:"COM" "coms.txt"') do set plink=%%A && call :launch_plinks

ping -n 1 192.168.3.90 2>nul | find "TTL=" >nul 2>nul
if [%errorlevel%]==[0] wscript.exe Invisible.vbs telnet_dmi1.bat >nul  2>nul

ping -n 1 192.168.3.91 2>nul | find "TTL=" >nul  2>nul
if [%errorlevel%]==[0] wscript.exe Invisible.vbs telnet_dmi2.bat >nul  2>nul

cports.exe /scomma "" >COM_Logs\cports.txt

findstr /c:",5629," "COM_Logs\cports.txt" >nul 2>nul
if [%errorlevel%]==[0] (
for /f "tokens=5 delims=," %%b in ('FINDSTR /c:"5629" COM_Logs\cports.txt') do set tcms_ip=%%b 2>nul
for /f "tokens=7 delims=," %%b in ('FINDSTR /c:"5629" COM_Logs\cports.txt') do set vsim_ip=%%b 2>nul
ping -n 1 %tcms_ip% 2>nul | find "TTL=" >nul 2>nul
if [%errorlevel%]==[0] wscript.exe Invisible.vbs telnet_tcms.bat %tcms_ip% >nul  2>nul
ping -n 1 %vsim_ip% 2>nul | find "TTL=" >nul  2>nul
if [%errorlevel%]==[0] wscript.exe Invisible.vbs telnet_vsim.bat %vsim_ip% >nul  2>nul
)
timeout /t 3 >nul
nircmd exec hide kill_last_plink.bat
exit
:launch_plinks
nircmd exec hide plink_process.bat %plink%
exit /b