@echo off
if not exist "Temp\" mkdir Temp\ 2>nul
attrib +h Temp
if not exist "COM_Logs\" mkdir COM_Logs\ 2>nul
attrib +h COM_Logs

echo 192.168.3.91>Temp\DMI2_commands.txt
echo WAIT "Password:">>Temp\DMI2_commands.txt
echo SEND "ar8529\m">>Temp\DMI2_commands.txt
echo WAIT "root@rweicab4g:~#">>Temp\DMI2_commands.txt
echo SEND "cat /uploads/dmisw_info.txt\m">>Temp\DMI2_commands.txt
echo WAIT "root@rweicab4g:~#">>Temp\DMI2_commands.txt

tst10.exe /r:Temp\DMI2_commands.txt /o:COM_logs\DMI2_log.txt /m