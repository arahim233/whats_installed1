@echo off
if not exist "Temp\" mkdir Temp\ 2>nul
attrib +h Temp
if not exist "COM_Logs\" mkdir COM_Logs\ 2>nul
attrib +h COM_Logs

echo 192.168.3.90>Temp\DMI1_commands.txt
echo WAIT "Password:">>Temp\DMI1_commands.txt
echo SEND "ar8529\m">>Temp\DMI1_commands.txt
echo WAIT "root@rweicab4g:~#">>Temp\DMI1_commands.txt
echo SEND "cat /uploads/dmisw_info.txt\m">>Temp\DMI1_commands.txt
echo WAIT "root@rweicab4g:~#">>Temp\DMI1_commands.txt

tst10.exe /r:Temp\DMI1_commands.txt /o:COM_logs\DMI1_log.txt /m