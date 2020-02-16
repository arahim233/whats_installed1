@echo off
if not exist "Temp\" mkdir Temp\ 2>nul
attrib +h Temp
if not exist "COM_Logs\" mkdir COM_Logs\ 2>nul
attrib +h COM_Logs
for /f "tokens=7 delims=," %%b in ('FINDSTR /c:"5629" COM_Logs\cports.txt') do set vsim_ip=%%b
echo %vsim_ip% 5630 >Temp\vsim_command.txt
echo SEND "">>Temp\vsim_command.txt
echo WAIT "info">>Temp\vsim_command.txt
tst10.exe /r:Temp\vsim_command.txt /o:COM_logs\vsim_log.txt /m
echo VSIM IP: %vsim_ip% >>COM_logs\vsim_log.txt