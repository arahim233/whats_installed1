@echo off
if not exist "Temp\" mkdir Temp\ 2>nul
attrib +h Temp
if not exist "COM_Logs\" mkdir COM_Logs\ 2>nul
attrib +h COM_Logs
for /f "tokens=5 delims=," %%b in ('FINDSTR /c:"5629" COM_Logs\cports.txt') do set tcms_ip=%%b
echo %tcms_ip% 5529>Temp\tsim_command.txt
echo SEND "">>Temp\tsim_command.txt
echo WAIT "Train">>Temp\tsim_command.txt
tst10.exe /r:Temp\tsim_command.txt /o:COM_Logs\tcms_log.txt /m
for /f "tokens=10 delims=," %%b in ('FINDSTR /c:"5629" COM_Logs\cports.txt') do set tcms_loc=%%b
echo TCMS IP: %tcms_ip%>>COM_Logs\tcms_log.txt
echo TCMS Location: %tcms_loc%>>COM_Logs\tcms_log.txt