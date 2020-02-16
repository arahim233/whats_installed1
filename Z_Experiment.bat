@cls
@ECHO OFF
@title What's Installed v2.0
pushd "%~dp0"
mode con: cols=56
color 3f
if not "%1" == "max" start /MAX cmd /c %0 max & exit/b

echo.
echo Detecting GSP platform, please wait...

:: #########################
:: ###  Set Timestamps   ###
:: #########################
set hour=%time:~0,2%
if "%hour:~0,1%" == " " set hour=0%hour:~1,1%
set min=%time:~3,2%
if "%min:~0,1%" == " " set min=0%min:~1,1%
set secs=%time:~6,2%
if "%secs:~0,1%" == " " set secs=0%secs:~1,1%
for /f "skip=1" %%x in ('wmic os get localdatetime') do if not defined MyDate set MyDate=%%x
set today=%MyDate:~0,4%-%MyDate:~4,2%-%MyDate:~6,2%


:: ######################
:: ###  Pre-StartUp   ###
:: ######################
taskkill /IM "plink.exe" /T /F >nul 2>nul
taskkill /IM "DCUTerm.exe" /T /F >nul 2>nul
if exist coms.txt del /f /q coms.txt >nul 2>nul
if exist SessionLog.txt del /f /q SessionLog.txt >nul 2>nul
if exist "COM_Logs\" rd /q /s "COM_Logs\" >nul 2>nul
if not exist "COM_Logs\" mkdir COM_Logs\ >nul 2>nul
attrib +h COM_Logs  >nul 2>nul
if not exist "SubMods\" mkdir SubMods\  >nul 2>nul
attrib +h SubMods\ >nul 2>nul

goto :CheckifAAlive


:: ###############################
:: ### Check if CPU-A is alive ###
:: ###############################

:CheckifAAlive
	ping -n 1 192.168.2.10 2>nul | find "TTL=" >nul
	if [%errorlevel%]==[0] (
	goto :labconfig_from_CPU_A
)
	if [%errorlevel%]==[1] ( 
	call :Ping_Failed_A_StartUp
	goto :CheckifBAlive
)
exit /b


:: ###############################
:: ### Check if CPU-B is alive ###
:: ###############################

:CheckifBAlive
	ping -n 1 192.168.2.11 | find "TTL=" >nul
	if [%errorlevel%]==[0] (
	goto :labconfig_from_CPU_B
)
	if [%errorlevel%]==[1] ( 
	call :Ping_Failed_B_StartUp
	goto :NoGSPDetected
) 
exit /b


:: ###################################
:: ### Check Lab Config from CPU-A ###
:: ###################################

:labconfig_from_CPU_A
	set board=A
	echo y | plink root@192.168.2.10 -pw admin mount_rw >nul  2>nul
	plink root@192.168.2.10 -pw admin opkg-cl list >COM_Logs\CPU_A.txt 2>nul

::-------------------------------------
::	Detect if R4.1 or R4.2 from CPU-A |
::-------------------------------------
	findstr /c:"cohpa - cohp1-" "COM_Logs\CPU_A.txt" >nul  2>nul
	if [%errorlevel%]==[0] set cohp=R4.1
	
	findstr /c:"cohpa - cohp2-" "COM_Logs\CPU_A.txt" >nul  2>nul
	if [%errorlevel%]==[0] set cohp=R4.2

::-----------------------------------
::	Detect if P8C or P8E from CPU-A |
::-----------------------------------
	findstr /c:"gisu-disp-cohpa" "COM_Logs\CPU_A.txt" >nul  2>nul
	if [%errorlevel%]==[0] set project=P8E
	if [%errorlevel%]==[1] set project=P8C

	goto :Main_Function
		
	
:: ###################################
:: ### Check Lab Config from CPU-B ###
:: ###################################
:labconfig_from_CPU_B
	set board=B
	echo y | plink root@192.168.2.11 -pw admin mount_rw >nul  2>nul
	plink root@192.168.2.11 -pw admin opkg-cl list >COM_Logs\CPU_B.txt 2>nul

::-------------------------------------
::	Detect if R4.1 or R4.2 from CPU-B |
::-------------------------------------
	findstr /c:"cohpb - cohp1-" "COM_Logs\CPU_B.txt" >nul  2>nul
	if [%errorlevel%]==[0] set cohp=R4.1
	
	findstr /c:"cohpb - cohp2-" "COM_Logs\CPU_B.txt" >nul  2>nul
	if [%errorlevel%]==[0] set cohp=R4.2
	
::-----------------------------------
::	Detect if P8C or P8E from CPU-B |
::-----------------------------------
	findstr /c:"cmd-disp-cohpb -" "COM_Logs\CPU_B.txt" >nul  2>nul
	if [%errorlevel%]==[0] set project=P8E
	if [%errorlevel%]==[1] set project=P8C
	
	findstr /c:"sdpcohpb - 4." "COM_Logs\CPU_B.txt" >nul  2>nul
	if [%errorlevel%]==[0] set project=P8E
	
	findstr /c:"sdpcohpb - 2." "COM_Logs\CPU_B.txt" >nul  2>nul
	if [%errorlevel%]==[0] set project=P8C

	goto :Main_Function


:: #####################
:: ### Main Function ###
:: #####################

:Main_Function

::--------------------
::	Check competency |
::--------------------
	ping -n 1 192.168.2.110>nul 2>nul
	if [%errorlevel%]==[0] set "competency=System testing/Onboard " && set "mro_level=Onboard" && nircmd exec hide help_main_wi.bat
	if [%errorlevel%]==[1] set "competency=Subsystem testing/Mixed" && set "mro_level=Mixed"

::---------------------------
::	Detect which MR version |
::---------------------------
	for /f  %%a in ('findstr /c:"etcswbin - 4.4." COM_Logs\CPU_%board%.txt') do set "mr=MR3" >nul  2>nul
	for /f  %%a in ('findstr /c:"etcswbin - 4.5." COM_Logs\CPU_%board%.txt') do set "mr=MR4" >nul  2>nul
	for /f  %%a in ('findstr /c:"etcswbin - 4.6." COM_Logs\CPU_%board%.txt') do set "mr=MR5" >nul  2>nul
	for /f  %%a in ('findstr /c:"etcswbin - 4.7." COM_Logs\CPU_%board%.txt') do set "mr=MR6" >nul  2>nul
	for /f  %%a in ('findstr /c:"etcswbin - 4.8." COM_Logs\CPU_%board%.txt') do set "mr=MR7" >nul  2>nul
	for /f  %%a in ('findstr /c:"etcswbin - 4.9." COM_Logs\CPU_%board%.txt') do set "mr=MR8" >nul  2>nul
	for /f  %%a in ('findstr /c:"etcswbin - 5.0." COM_Logs\CPU_%board%.txt') do set "mr=   " && set "space=      " >nul  2>nul 
	for /f  %%a in ('findstr /c:"etcswbin - 5.1." COM_Logs\CPU_%board%.txt') do set "mr=MR1" >nul  2>nul
	for /f  %%a in ('findstr /c:"etcswbin - 5.2." COM_Logs\CPU_%board%.txt') do set "mr=MR2" >nul  2>nul
	for /f  %%a in ('findstr /c:"etcswbin - 5.3." COM_Logs\CPU_%board%.txt') do set "mr=MR3" >nul  2>nul
	
	findstr /c:"etcswbin -" COM_Logs\CPU_%board%.txt >nul  2>nul
	if [%errorlevel%]==[1] set "mr=?? ">nul  2>nul
	
::----------------
::	Main Display |
::----------------	
	mode con: cols=56
	echo.
	echo #############################################
	echo #    Detected %cohp% - %project% - %mr% Platform     #
	echo #   -------------------------------------   #
	echo #    Competency: %competency%    #
	echo #############################################
	echo.
::--------------------------------------------------------------------------------------------------------------------
	echo.############################################>> SessionLog.txt
	echo.#             Detected %cohp% - %project% - %mr% Platform       %space%    #>> SessionLog.txt
	echo.#        ----------------------------------------------------       #>> SessionLog.txt
	echo.#            Competency: %competency%          #>> SessionLog.txt
	echo.############################################>> SessionLog.txt
::--------------------------------------------------------------------------------------------------------------------			
	echo.>_ && type _ && type _ >> SessionLog.txt

::--------------
::	Call whom? |
::--------------	
	if [%cohp%]==[R4.1] (
			if [%mro_level%]==[Mixed] (
				goto :Subsystem_CPU_A
	))
::----------------------------------------------
	if [%cohp%]==[R4.2] (
			if [%mro_level%]==[Mixed] (
				goto :Subsystem_CPU_A
	))
::----------------------------------------------
		if [%cohp%]==[R4.1] (
			if [%mro_level%]==[Onboard] (
				goto :R41_A_Systemtest
	))
::----------------------------------------------
		if [%cohp%]==[R4.2] (
			if [%mro_level%]==[Onboard] (
				goto :R42_A_Systemtest
	))
::----------------------------------------------

:: ################################
:: ### R4.1 - CPU-A - Subsystem ###
:: ################################

:Subsystem_CPU_A
	ping -n 1 192.168.2.10 | find "TTL=" >nul 
	if errorlevel 1 ( 
	call :Ping_Failed_A
	echo Will try to print installed versions for CPU-B..
	echo.
	echo.
	goto :Subsystem_CPU_B
) else (
	call :Display_A
	goto :Subsystem_CPU_B
)
exit /b


:: ################################
:: ### R4.1 - CPU-B - Subsystem ###
:: ################################
:Subsystem_CPU_B
	ping -n 1 192.168.2.11 | find "TTL=" >nul 
	if errorlevel 1 ( 
	call :Ping_Failed_B
	echo.
	goto :CleanUp
) else (
	call :Display_B
	goto :CleanUp
)
exit /b


:: #################################
:: ### R4.1 - CPU-A - Systemtest ###
:: #################################
:R41_A_Systemtest
	ping -n 1 192.168.2.10 | find "TTL=" >nul 
	if errorlevel 1 ( 
	call :Ping_Failed_A
	echo Will try to print installed versions for CPU-B..>_ && type _ && type _ >> SessionLog.txt
	echo.>_ && type _ && type _ >> SessionLog.txt
	echo.>_ && type _ && type _ >> SessionLog.txt
	goto :R41_B_Systemtest
) else (
	call :Display_A
	goto :R41_B_Systemtest
)
exit /b


:: #################################
:: ### R4.1 - CPU-B - Systemtest ###
:: #################################
:R41_B_Systemtest
	ping -n 1 192.168.2.11 | find "TTL=" >nul 
	if errorlevel 1 ( 
	call :Ping_Failed_B
	echo.>_ && type _ && type _ >> SessionLog.txt
	goto :OtherSubsytems
) else (
	call :Display_B
	goto :OtherSubsytems
)
exit /b


:: #################################
:: ### R4.2 - CPU-A - Systemtest ###
:: #################################
:R42_A_Systemtest
	ping -n 1 192.168.2.10 | find "TTL=" >nul 
	if errorlevel 1 ( 
	call :Ping_Failed_A
	echo Will try to print installed versions for CPU-B..
	echo.
	echo.
	goto :R42_B_Systemtest
) else (
	call :Display_A
	goto :R42_B_Systemtest
)
exit /b


:: #################################
:: ### R4.2 - CPU-B - Systemtest ###
:: #################################
:R42_B_Systemtest
	ping -n 1 192.168.2.11 | find "TTL=" >nul 
	if errorlevel 1 ( 
	call :Ping_Failed_B
	echo Will try to print installed versions for CPU-C..
	echo.
	echo.
	goto :R42_C_Systemtest
) else (
	call :Display_B
	goto :R42_C_Systemtest
)
exit /b


:: ################################
:: ### R4.2 - CPU-C - Systemtest###
:: ################################
:R42_C_Systemtest
	ping -n 1 192.168.2.12 | find "TTL=" >nul 
	if errorlevel 1 ( 
	call :Ping_Failed_C
	echo.
	goto :OtherSubsytems
) else (
	call :Display_C
	goto :OtherSubsytems
)
exit /b


:: #######################
:: ### No GSP Detected ###
:: #######################
:NoGSPDetected
	timeout /t 3 > nul
	mode con: cols=56 lines=28
	echo.
	echo.
	echo.     #############################################
	echo.     ##                                         ##
	echo.     ##       ---------------------------       ##
	echo.     ##       IMPORTANT! No GSP detected.       ##
	echo.     ##       ---------------------------       ##
	echo.     ##                                         ##
	echo.     ##       ***************************       ##
	echo.     ##       *  Pinging CPU-A Failed!  *       ##
	echo.     ##       *  Pinging CPU-B Failed!  *       ##
	echo.     ##       ***************************       ##
	echo.     ##                                         ##
	echo.     ##        Cannot continue further...       ##
	echo.     ##                                         ##
	echo.     ##  If you are connected to a GSP,         ##
	echo.     ##  then make sure:                        ##
	echo      ##  - GSP is powered ON and                ##
	echo.     ##  - GSP ethernet cable is connected and  ##
	echo.     ##  - GSP network has a valid IP address.  ##
	echo.     ##                                         ##
	echo.     ##                                         ##
	echo.     #############################################
	echo.
	echo.
	echo.
	pause
	goto :Exit
exit /b


:: ###########################
:: ### Ping failed - CPU-A ###
:: ###########################
:Ping_Failed_A
	echo.
	echo **********************************************
	echo *      Pinging 192.168.2.10 was Failed!      *
	echo *      --------------------------------      *
	echo * Cannot display installed versions of CPU-A *
	echo **********************************************
	echo.
exit /b


:: ###########################
:: ### Ping failed - CPU-B ###
:: ###########################
:Ping_Failed_B
	echo.
	echo **********************************************
	echo *      Pinging 192.168.2.11 was Failed!      *
	echo *      --------------------------------      *
	echo * Cannot display installed versions of CPU-B *
	echo **********************************************
	echo.
exit /b
	

:: ###########################
:: ### Ping failed - CPU-C ###
:: ###########################
:Ping_Failed_C
	echo.
	echo **********************************************
	echo *      Pinging 192.168.2.12 was Failed!      *
	echo *      --------------------------------      *
	echo * Cannot display installed versions of CPU-c *
	echo **********************************************
	echo.
exit /b


:: ######################################
:: ### Ping failed at StartUp - CPU-A ###
:: ######################################
:Ping_Failed_A_StartUp
	mode con: cols=56
	echo.
	echo **************************************************
	echo *        Pinging 192.168.2.10 was Failed!        *
	echo *        --------------------------------        *
	echo * Will check again if CPU-A comes alive later... *
	echo **************************************************
	echo.
exit /b


:: ######################################
:: ### Ping failed at StartUp - CPU-B ###
:: ######################################
:Ping_Failed_B_StartUp
	echo.
	echo **************************************************
	echo *        Pinging 192.168.2.11 was Failed!        *
	echo *        --------------------------------        *
	echo * Will check again if CPU-B comes alive later... *
	echo **************************************************
	echo.
exit /b


:: #######################
:: ### Display - CPU-A ###
:: #######################
:Display_A
::-------------------------------------------------------------------------------------------------------------------
	echo.************************************>> SessionLog.txt
	echo.*	Pinging 192.168.2.10 was Successful!	*>> SessionLog.txt
	echo.*	----------------------------------------------	  *>> SessionLog.txt
	echo.*			 Installed versions on CPU-A		  *>> SessionLog.txt
	echo.************************************>> SessionLog.txt
::--------------------------------------------------------------------------------------------------------------------
	echo ******************************************
	echo *  Pinging 192.168.2.10 was Successful!  *
	echo *  ------------------------------------  *
	echo *      Installed versions on CPU-A       *
	echo ******************************************
	echo y | plink root@192.168.2.10 -pw admin mount_rw >nul  2>nul
	if exist COM_Logs\CPU_A.txt type COM_Logs\CPU_A.txt>_ && type _ && type _ >> SessionLog.txt 2>nul
	if not exist COM_Logs\CPU_A.txt plink root@192.168.2.10 -pw admin opkg-cl list>_ && type _ && type _ >> SessionLog.txt 2>nul
	echo -----------------------------------
	echo ---------------------------------------------->> SessionLog.txt
	echo. Other component versions of CPU-A>_ && type _ && type _ >> SessionLog.txt
	echo ---------------------------------------------->> SessionLog.txt
	echo -----------------------------------
	plink root@192.168.2.10 -pw admin cat /opt/atpcu/run/ATPMainLog-A>temp.txt 2>nul
	findstr /c:"SetTimeOfDay" temp.txt>nul 2>nul
	if [%errorlevel%]==[0] (
	for /f "tokens=7 delims=. " %%i in ('FINDSTR /C:"SetTimeOfDay" temp.txt') do echo.SetTimeOfDay version - %%i>_ && type _ && type _ >> SessionLog.txt 2>nul
	)
	findstr /c:"DispatcherInput" temp.txt>nul 2>nul
	if [%errorlevel%]==[0] (
	for /f "tokens=9 delims=:, " %%i in ('FINDSTR /C:"DispatcherInput" temp.txt') do echo.DispatcherInput version  - %%i>_ && type _ && type _ >> SessionLog.txt 2>nul
	)
	findstr /c:"DispatcherOutput" temp.txt>nul 2>nul
	if [%errorlevel%]==[0] (
	for /f "tokens=9 delims=:, " %%i in ('FINDSTR /C:"DispatcherOutput" temp.txt') do echo.DispatcherOutput version - %%i>_ && type _ && type _ >> SessionLog.txt 2>nul
	)	
	plink root@192.168.2.10 -pw admin mount_ro >nul  2>nul
	echo.>_ && type _ && type _ >> SessionLog.txt
	echo.>_ && type _ && type _ >> SessionLog.txt
exit /b


:: #######################
:: ### Display - CPU-B ###
:: #######################
:Display_B
::-------------------------------------------------------------------------------------------------------------------
	echo.************************************>> SessionLog.txt
	echo.*	Pinging 192.168.2.11 was Successful!	*>> SessionLog.txt
	echo.*	----------------------------------------------	  *>> SessionLog.txt
	echo.*			 Installed versions on CPU-B		  *>> SessionLog.txt
	echo.************************************>> SessionLog.txt
::--------------------------------------------------------------------------------------------------------------------
	echo ******************************************
	echo *  Pinging 192.168.2.11 was Successful!  *
	echo *  ------------------------------------  *
	echo *      Installed versions on CPU-B       *
	echo ******************************************
	echo y | plink root@192.168.2.11 -pw admin mount_rw >nul  2>nul
	plink root@192.168.2.11 -pw admin opkg-cl list >_ && type _ && type _ >> SessionLog.txt
	echo -----------------------------------
	echo ---------------------------------------------->> SessionLog.txt
	echo. Other component versions of CPU-B>_ && type _ && type _ >> SessionLog.txt
	echo ---------------------------------------------->> SessionLog.txt
	echo -----------------------------------
	plink root@192.168.2.11 -pw admin /opt/atpcu/nvshfr/bin/nvshfr -v>temp.txt 2>nul
	findstr /c:"NVSHFR version" temp.txt>nul 2>nul
	if [%errorlevel%]==[0] (
	for /f "tokens=3 delims= " %%i in ('FINDSTR /C:"NVSHFR version" temp.txt') do echo.NVSHFR version - %%i>_ && type _ && type _ >>SessionLog.txt 2>nul
	)
	
	plink root@192.168.2.11 -pw admin /opt/atpcu/nvshft/bin/nvshft -v >temp.txt 2>nul
	findstr /c:"NVSHFT version" temp.txt>nul 2>nul
	if [%errorlevel%]==[0] (
	for /f "tokens=3 delims= " %%i in ('FINDSTR /C:"NVSHFT version" temp.txt') do echo.NVSHFT version - %%i>_ && type _ && type _ >>SessionLog.txt 2>nul
	)
	
	plink root@192.168.2.11 -pw admin head -n 1 /opt/atpcu/etcsc/cfg/def/cfgDefinition.txt>COM_Logs\cfgDefversion.txt 2>nul
	for /f %%i in (COM_Logs\cfgDefversion.txt) do echo.cfgDefinition version - %%i>_ && type _ && type _ >>SessionLog.txt 2>nul
	
	plink root@192.168.2.11 -pw admin head -n 1 /opt/atpcu/etcsc/cfg/def/mntDefinition.txt>COM_Logs\mntDefversion.txt 2>nul
	for /f %%i in (COM_Logs\mntDefversion.txt) do echo.mntDefinition version - %%i>_ && type _ && type _ >>SessionLog.txt 2>nul	
	
	plink root@192.168.2.11 -pw admin head -n 1 /opt/atpcu/etcsc/cfg/def/rtDefinition.txt>COM_Logs\rtDefversion.txt 2>nul
	for /f %%i in (COM_Logs\rtDefversion.txt) do echo.rtDefinition version  - %%i>_ && type _ && type _ >>SessionLog.txt 2>nul

	plink root@192.168.2.11 -pw admin head -n 1 /opt/atpcu/etcsc/cfg/text/RADIO_CFG.txt>COM_Logs\radioDefversion.txt 2>nul
	for /f "tokens=2 delims= " %%k in (COM_Logs\radioDefversion.txt) do echo.radioDefinition version - %%k>_ && type _ && type _ >>SessionLog.txt 2>nul

	plink root@192.168.2.11 -pw admin head -n 1 /opt/atpcu/etcsc/cfg/text/KMAC.txt>COM_Logs\KMACversion.txt 2>nul
	for /f "tokens=2 delims= " %%k in (COM_Logs\KMACversion.txt) do echo.KMAC version   - %%k>_ && type _ && type _ >>SessionLog.txt 2>nul
	
	plink root@192.168.2.11 -pw admin head -n 1 /opt/atpcu/etcsc/cfg/text/KTRANS.txt>COM_Logs\KTRANSversion.txt 2>nul
	for /f "tokens=2 delims= " %%k in (COM_Logs\KTRANSversion.txt) do echo.KTRANS version - %%k>_ && type _ && type _ >>SessionLog.txt 2>nul
	
	plink root@192.168.2.11 -pw admin mount_ro >nul  2>nul
	echo.>_ && type _ && type _ >> SessionLog.txt
	echo.
	if exist temp.txt del /f /q temp.txt
exit /b


:: #######################
:: ### Display - CPU-C ###
:: #######################
:Display_C
::-------------------------------------------------------------------------------------------------------------------
	echo.************************************>> SessionLog.txt
	echo.*	Pinging 192.168.2.12 was Successful!	*>> SessionLog.txt
	echo.*	----------------------------------------------	  *>> SessionLog.txt
	echo.*			 Installed versions on CPU-C		  *>> SessionLog.txt
	echo.************************************>> SessionLog.txt
::--------------------------------------------------------------------------------------------------------------------
	echo ******************************************
	echo *  Pinging 192.168.2.12 was Successful!  *
	echo *  ------------------------------------  *
	echo *      Installed versions on CPU-C       *
	echo ******************************************
	echo y | plink root@192.168.2.12 -pw admin mount_rw >nul  2>nul
	plink root@192.168.2.12 -pw admin opkg-cl list>_ && type _ && type _ >> SessionLog.txt
	plink root@192.168.2.12 -pw admin mount_ro >nul  2>nul
	echo.>_ && type _ && type _ >> SessionLog.txt
	echo.
exit /b
	
:: ########################
:: ### Other Subsystems ###
:: ########################
:OtherSubsytems
	echo Scanning all serial ports on this computer.
	echo -------------------------------------------
setlocal EnableDelayedExpansion
	set "cmd=findstr /R /N "^^" coms.txt | find /C "COM""
	for /f %%a in ('!cmd!') do set number=%%a
	echo Found %number% serial ports.
	echo.
endlocal
	if exist coms.txt del /f /q coms.txt 2>nul
	::nircmd exec hide kill_last_plink.bat
	pushd "COM_Logs\"
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	goto :opccode
exit /b
	
::************************************************************
::                   OPC CODE
::************************************************************
	
:opccode
	FINDSTR /m /C:"Filename OPC" * >nul 2>nul
	if errorlevel 1 goto :vapcode 
	for /f "tokens=*" %%a in ('FINDSTR /m /C:"Filename OPC" *') do set opcfound=%%a 2>nul
	echo *********************
	echo * OPC details:      *
	echo * ------------      *
	echo * %opcfound%    *
	echo *********************
::--------------------------------------------------------------------------------------------------------	
	echo *******************>> ..\SessionLog.txt
	echo * OPC details:             *>> ..\SessionLog.txt
	echo * ---------------------     *>> ..\SessionLog.txt
	echo * %opcfound%     *>> ..\SessionLog.txt
	echo *******************>> ..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=2 delims=:" %%i in ('FINDSTR /C:"Filename OPC" *') do set opcfile=%%i 2>nul
	for /f "tokens=*" %%b in ('FINDSTR /c:"Checksum" "%opcfound%"') do set findopcchecksum=%%b && call :findopcchecksum 2>nul
	goto :mainopc
	:findopcchecksum
	echo %findopcchecksum% >>foundopcchecksum.txt
	exit /b
	:mainopc
	for /f "skip=2 delims=" %%a in (foundopcchecksum.txt) do set opc_checksum=%%a && goto :nextopc 2>nul
	:nextopc
	echo.%opcfile%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt 2>nul
	echo.  %opc_checksum%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt 2>nul
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	timeout /t 1 >nul
	goto :vapcode
exit /b
	
::************************************************************
::                   VAP CODE
::************************************************************
:vapcode
	FINDSTR /m /C:"Filename OCVE" * >nul 2>nul
	if errorlevel 1 goto :pmsdpcode
	for /f "tokens=*" %%a in ('FINDSTR /m /C:"Filename OCVE" *') do set vapfound=%%a 2>nul
	echo *********************
	echo * VAP details:      *
	echo * --------------    *
	echo * %vapfound%    *
	echo *********************
::--------------------------------------------------------------------------------------------------------	
	echo *******************>> ..\SessionLog.txt
	echo * VAP details:             *>> ..\SessionLog.txt
	echo * ---------------------     *>> ..\SessionLog.txt
	echo * %vapfound%     *>> ..\SessionLog.txt
	echo *******************>> ..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=*" %%b in ('FINDSTR /c:"Checksum" "%vapfound%"') do set findvapchecksum=%%b && call :findvapchecksum 2>nul
	goto :mainvap
	:findvapchecksum
	echo %findvapchecksum% >>foundvapchecksum.txt
	exit /b
	:mainvap
	for /f "delims=" %%a in (foundvapchecksum.txt) do set vap_vcu_checksum=%%a && goto :next 2>nul
	:next
	for /f "skip=1 delims=" %%a in (foundvapchecksum.txt) do set vap_prj_checksum=%%a && goto :next1 2>nul
	:next1
	for /f "skip=2 delims=" %%a in (foundvapchecksum.txt) do set vap_core_checksum=%%a && goto :next2 2>nul
	:next2
	for /f "skip=3 delims=" %%a in (foundvapchecksum.txt) do set vap_ocve_checksum=%%a && goto :next3 2>nul
	:next3
	
	for /f "tokens=2 delims=:" %%i in ('FINDSTR /C:"Filename OCVE" *') do set vapocvefound=%%i 2>nul
	echo.%vapocvefound% %vap_ocve_checksum%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	
	for /f "tokens=* delims=:" %%j in ('FINDSTR /C:"VAP_VCU:" *') do set vapvcufound=%%j 2>nul
	echo %vapvcufound% >vapvcufound.txt
	for /f "tokens=4,5,6 delims=: " %%a IN (vapvcufound.txt) DO @echo.  %%a %%b %%c     %vap_vcu_checksum%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt  2>nul
	
	for /f "tokens=* delims=:" %%j in ('FINDSTR /C:"VAP_PRJ:" *') do set vapprjfound=%%j 2>nul
	echo %vapprjfound% >vapprjfound.txt
	for /f "tokens=4,5,6 delims=: " %%a IN (vapprjfound.txt) DO @echo.  %%a %%b %%c     %vap_prj_checksum%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt 2>nul
	
	for /f "tokens=* delims=:" %%j in ('FINDSTR /C:"VAP_CORE:" *') do set vapcorefound=%%j 2>nul
	echo %vapcorefound% >vapcorefound.txt
	for /f "tokens=4,5,6 delims=: " %%a IN (vapcorefound.txt) DO @echo.  %%a %%b %%c    %vap_core_checksum%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt  2>nul
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >> ..\SessionLog.txt
	timeout /t 1 >nul
	goto :pmsdpcode
exit /b
	
::************************************************************
::                   PM/SDP CODE
::************************************************************
:pmsdpcode
	FINDSTR /m /C:"Filename pm" * >nul 2>nul
	if errorlevel 1 goto :btm1code
	for /f "tokens=*" %%a in ('FINDSTR /m /C:"Filename pm" *') do set pmfound=%%a 2>nul
	echo *********************
	echo * PM/SDP details:   *
	echo * ---------------   *
	echo * %pmfound%    *
	echo *********************
::--------------------------------------------------------------------------------------------------------	
	echo *******************>> ..\SessionLog.txt
	echo * PM/SDP details:      *>> ..\SessionLog.txt
	echo * ----------------------    *>> ..\SessionLog.txt
	echo * %pmfound%     *>> ..\SessionLog.txt
	echo *******************>> ..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=2 delims=:" %%i in ('FINDSTR /C:"Filename pm" *') do set pmfile=%%i 2>nul
	for /f "tokens=*" %%b in ('FINDSTR /c:"Checksum" "%pmfound%"') do set findpmchecksum=%%b && call :findpmchecksum 2>nul
	goto :mainpm
	:findpmchecksum
	echo %findpmchecksum% >>foundpmchecksum.txt
	exit /b
	:mainpm
	for /f "skip=2 delims=" %%a in (foundpmchecksum.txt) do set pm_checksum=%%a && goto :nextpm 2>nul
	:nextpm
	echo.%pmfile%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt  
	echo.  %pm_checksum%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	timeout /t 1 >nul
	goto :btm1code
exit /b

::************************************************************
::                   BTM1 CODE
::************************************************************
	
:btm1code
	FINDSTR /m /C:"Filename btm1" * >nul 2>nul
	if errorlevel 1 goto :btm2code
	for /f "tokens=*" %%a in ('FINDSTR /m /C:"Filename btm1" *') do set btm1found=%%a 2>nul
	echo *********************
	echo * BTM1 details:     *
	echo * --------------    *
	echo * %btm1found%   *
	echo *********************
::--------------------------------------------------------------------------------------------------------	
	echo *******************>> ..\SessionLog.txt
	echo * BTM1 details:     	 *>> ..\SessionLog.txt
	echo * ---------------------     *>> ..\SessionLog.txt
	echo * %btm1found%   *>> ..\SessionLog.txt
	echo *******************>> ..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=2 delims=:" %%i in ('FINDSTR /C:"Filename btm1" *') do set btm1file=%%i 2>nul
	for /f "tokens=*" %%b in ('FINDSTR /c:"Checksum" "%btm1found%"') do set findbtm1checksum=%%b && call :findbtm1checksum 2>nul
	goto :mainbtm1
	:findbtm1checksum
	echo %findbtm1checksum% >>foundbtm1checksum.txt
	exit /b
	:mainbtm1
	for /f "skip=2 delims=" %%a in (foundbtm1checksum.txt) do set btm1_checksum=%%a && goto :nextbtm1 2>nul
	:nextbtm1
	echo.%btm1file%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo.  %btm1_checksum%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	timeout /t 1 >nul
	goto :btm2code
exit /b
	
::************************************************************
::                   BTM2 CODE
::************************************************************
:btm2code
	FINDSTR /m /C:"Filename btm2" * >nul 2>nul
	if errorlevel 1 goto :dmi1code
	for /f "tokens=*" %%a in ('FINDSTR /m /C:"Filename btm2" *') do set btm2found=%%a 2>nul
	echo *********************
	echo * BTM2 details:     *
	echo * --------------    *
	echo * %btm2found%   *
	echo *********************	
::--------------------------------------------------------------------------------------------------------	
	echo *******************>> ..\SessionLog.txt
	echo * BTM2 details:     	 *>> ..\SessionLog.txt
	echo * ---------------------     *>> ..\SessionLog.txt
	echo * %btm2found%   *>> ..\SessionLog.txt
	echo *******************>> ..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=2 delims=:" %%i in ('FINDSTR /C:"Filename btm2" *') do set btm2file=%%i 2>nul
	for /f "tokens=*" %%b in ('FINDSTR /c:"Checksum" "%btm2found%"') do set findbtm2checksum=%%b && call :findbtm2checksum 2>nul
	goto :mainbtm2
	:findbtm2checksum
	echo %findbtm2checksum% >>foundbtm2checksum.txt
	exit /b
	:mainbtm2
	for /f "skip=2 delims=" %%a in (foundbtm2checksum.txt) do set btm2_checksum=%%a && goto :nextbtm2 2>nul
	:nextbtm2
	echo.%btm2file%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo.  %btm2_checksum%>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	timeout /t 1 >nul
	goto :dmi1code
exit /b
	
::************************************************************
::                DMI1 details
::************************************************************
:dmi1code
	FINDSTR /m /c:"SW Version:" DMI1_log.txt >nul 2>nul
	if errorlevel 1 goto :dmi2code
	echo *********************
	echo * DMI-1 details:    *
	echo * ----------------  *
	echo * IP: 192.168.3.90  *
	echo *********************
::--------------------------------------------------------------------------------------------------------	
	echo *******************>>..\SessionLog.txt
	echo * DMI-1 details:         *>>..\SessionLog.txt
	echo * -----------------          *>>..\SessionLog.txt
	echo * IP: 192.168.3.90      *>>..\SessionLog.txt
	echo *******************>>..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"SW Version:" DMI1_log.txt') do echo.  Kernel %%a %%b:  %%c 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"DMI Version:" DMI1_log.txt') do echo.  %%a %%b:        %%c 2>nul
	echo   .............................................
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"SW Version:" DMI1_log.txt') do echo.  Kernel %%a %%b:     %%c>> ..\SessionLog.txt 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"DMI Version:" DMI1_log.txt') do echo.  %%a %%b:               %%c>> ..\SessionLog.txt 2>nul
	echo   ............................................................>>..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------
	setlocal enableDelayedExpansion
	for /f "tokens=*" %%a in ('FINDSTR /c:"HW Platform:" DMI1_log.txt') do set "dmi1_hw_platform=%%a" 2>nul
	echo.  Kernel !dmi1_hw_platform%!> ..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	endlocal
	for /f "tokens=*" %%a in ('FINDSTR /c:"HW Version:" DMI1_log.txt') do set dmi1_kernel_hw_version=%%a 2>nul
	echo.  Kernel %dmi1_kernel_hw_version%> ..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	for /f "tokens=*" %%a in ('FINDSTR /c:"SW Codename:" DMI1_log.txt') do set dmi1_sw_codename=%%a 2>nul
	echo.  Kernel %dmi1_sw_codename%> ..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"RCI Version:" DMI1_log.txt') do  echo.  %%a %%b:        %%c 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"VSIS Version:" DMI1_log.txt') do echo.  %%a %%b:       %%c 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"IPTCom Version:" DMI1_log.txt') do  echo.  %%a %%b:     %%c 2>nul
	for /f "tokens=1,2,3,4 delims=: " %%a in ('FINDSTR /c:"DMI Version Hash:" DMI1_log.txt') do echo.  %%a %%b %%c:   %%d 2>nul
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"RCI Version:" DMI1_log.txt') do  echo.  %%a %%b:                 %%c>>..\SessionLog.txt 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"VSIS Version:" DMI1_log.txt') do echo.  %%a %%b:               %%c>>..\SessionLog.txt 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"IPTCom Version:" DMI1_log.txt') do  echo.  %%a %%b:          %%c>>..\SessionLog.txt 2>nul
	for /f "tokens=1,2,3,4 delims=: " %%a in ('FINDSTR /c:"DMI Version Hash:" DMI1_log.txt') do echo.  %%a %%b %%c:       %%d>>..\SessionLog.txt 2>nul
::--------------------------------------------------------------------------------------------------------
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	timeout /t 1 >nul
	goto :dmi2code
exit /b
	
::************************************************************
::                DMI2 details
::************************************************************
:dmi2code
	FINDSTR /m /c:"SW Version:" DMI2_log.txt >nul 2>nul
	if errorlevel 1 goto :tcmscode
	echo *********************
	echo * DMI-2 details:    *
	echo * ----------------  *
	echo * IP: 192.168.3.91  *
	echo *********************
::--------------------------------------------------------------------------------------------------------	
	echo *******************>>..\SessionLog.txt
	echo * DMI-2 details:         *>>..\SessionLog.txt
	echo * -----------------          *>>..\SessionLog.txt
	echo * IP: 192.168.3.91      *>>..\SessionLog.txt
	echo *******************>>..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------	
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"SW Version:" DMI2_log.txt') do echo.  Kernel %%a %%b:  %%c 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"DMI Version:" DMI2_log.txt') do echo.  %%a %%b:        %%c 2>nul
	echo   .............................................
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"SW Version:" DMI2_log.txt') do echo.  Kernel %%a %%b:     %%c>>..\SessionLog.txt 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"DMI Version:" DMI2_log.txt') do echo.  %%a %%b:               %%c>>..\SessionLog.txt 2>nul
	echo   ............................................................>>..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------	
	setlocal enableDelayedExpansion
	for /f "tokens=*" %%a in ('FINDSTR /c:"HW Platform:" DMI2_log.txt') do set "dmi2_hw_platform=%%a" 2>nul
	echo.  Kernel !dmi2_hw_platform%!> ..\_ && type ..\_ && type ..\_ >>..\SessionLog.txt
	endlocal
	for /f "tokens=*" %%a in ('FINDSTR /c:"HW Version:" DMI2_log.txt') do set "dmi2_kernel_hw_version=%%a" 2>nul
	echo.  Kernel %dmi2_kernel_hw_version%> ..\_ && type ..\_ && type ..\_ >>..\SessionLog.txt
	for /f "tokens=*" %%a in ('FINDSTR /c:"SW Codename:" DMI2_log.txt') do set "dmi2_sw_codename=%%a" 2>nul
	echo.  Kernel %dmi2_sw_codename%> ..\_ && type ..\_ && type ..\_ >>..\SessionLog.txt
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"RCI Version:" DMI2_log.txt') do  echo.  %%a %%b:        %%c 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"VSIS Version:" DMI2_log.txt') do echo.  %%a %%b:       %%c 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"IPTCom Version:" DMI2_log.txt') do  echo.  %%a %%b:     %%c 2>nul
	for /f "tokens=1,2,3,4 delims=: " %%a in ('FINDSTR /c:"DMI Version Hash:" DMI2_log.txt') do echo.  %%a %%b %%c:   %%d 2>nul
::--------------------------------------------------------------------------------------------------------
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"RCI Version:" DMI2_log.txt') do  echo.  %%a %%b:                 %%c>>..\SessionLog.txt 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"VSIS Version:" DMI2_log.txt') do echo.  %%a %%b:               %%c>>..\SessionLog.txt 2>nul
	for /f "tokens=1,2,3 delims=: " %%a in ('FINDSTR /c:"IPTCom Version:" DMI2_log.txt') do  echo.  %%a %%b:          %%c>>..\SessionLog.txt 2>nul
	for /f "tokens=1,2,3,4 delims=: " %%a in ('FINDSTR /c:"DMI Version Hash:" DMI2_log.txt') do echo.  %%a %%b %%c:       %%d>>..\SessionLog.txt 2>nul
::--------------------------------------------------------------------------------------------------------
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	timeout /t 1 >nul
	goto :tcmscode
exit /b	
	
::************************************************************
::                Train Interface Simulator
::************************************************************
:tcmscode
	FINDSTR /m /c:"TCMS IP" tcms_log.txt >nul 2>nul
	if errorlevel 1 goto :vsimcode
	for /f "tokens=*" %%a in ('FINDSTR /c:"TCMS IP" tcms_log.txt') do set tcms_ip=%%a 2>nul
::---------------------------------------------------------------------------
:: IP adjustments
	>x ECHO.%tcms_ip%&FOR %%? IN (x) DO SET /A strlength=%%~z? - 2&del x
	if [%strlength%]==[16] set "tcms_ip=%tcms_ip%        "
	if [%strlength%]==[17] set "tcms_ip=%tcms_ip%       "
	if [%strlength%]==[18] set "tcms_ip=%tcms_ip%      "
	if [%strlength%]==[19] set "tcms_ip=%tcms_ip%     "
	if [%strlength%]==[20] set "tcms_ip=%tcms_ip%    "
	if [%strlength%]==[21] set "tcms_ip=%tcms_ip%   "
	if [%strlength%]==[22] set "tcms_ip=%tcms_ip%  "
	if [%strlength%]==[23] set "tcms_ip=%tcms_ip% "
::----------------------------------------------------------------------------
	echo *****************************
	echo * TCMS details:             *
	echo * ---------------------     *
	echo * %tcms_ip%  *
	echo *****************************
::--------------------------------------------------------------------------------------------------------	
	set "tcms_ip=%tcms_ip%  "
	echo **************************>>..\SessionLog.txt
	echo * TCMS details:                        *>> ..\SessionLog.txt
	echo * -----------------------                 *>>..\SessionLog.txt
	echo * %tcms_ip%    *>>..\SessionLog.txt
	echo **************************>>..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------	
	for /f "tokens=1,2,3,4" %%a in ('FINDSTR /c:"1SFW" tcms_log.txt') do echo.  TIS %%a %%b: %%c>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	for /f "tokens=*" %%a in ('FINDSTR /c:"TCMS Location:" tcms_log.txt') do echo.  %%a>..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	echo. >..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt 
	timeout /t 1 >nul
	goto :vsimcode
exit /b
	
::************************************************************
::                VSIM details
::************************************************************
:vsimcode
	FINDSTR /m /c:"VSIM IP:" vsim_log.txt >nul 2>nul
	if errorlevel 1 goto :CleanUp
	for /f "tokens=*" %%a in ('FINDSTR /c:"VSIM IP:" vsim_log.txt') do set vsim_ip=%%a 2>nul
::---------------------------------------------------------------------------
:: IP adjustments
	>x ECHO.%vsim_ip%&FOR %%? IN (x) DO SET /A strlength=%%~z? - 2&del x
	if [%strlength%]==[16] set "vsim_ip=%vsim_ip%        "
	if [%strlength%]==[17] set "vsim_ip=%vsim_ip%       "
	if [%strlength%]==[18] set "vsim_ip=%vsim_ip%      "
	if [%strlength%]==[19] set "vsim_ip=%vsim_ip%     "
	if [%strlength%]==[20] set "vsim_ip=%vsim_ip%    "
	if [%strlength%]==[21] set "vsim_ip=%vsim_ip%   "
	if [%strlength%]==[22] set "vsim_ip=%vsim_ip%  "
	if [%strlength%]==[23] set "vsim_ip=%vsim_ip% "
::----------------------------------------------------------------------------
	echo *****************************
	echo * VSIM details:             *
	echo * ---------------------     *
	echo * %vsim_ip%  *
	echo *****************************
::--------------------------------------------------------------------------------------------------------	
	set "vsim_ip=%vsim_ip%   "
	echo **************************>>..\SessionLog.txt
	echo * VSIM details:                         *>> ..\SessionLog.txt
	echo * -----------------------                 *>>..\SessionLog.txt
	echo * %vsim_ip%    *>>..\SessionLog.txt
	echo **************************>>..\SessionLog.txt
::--------------------------------------------------------------------------------------------------------	
	for /f "tokens=1, 2,3,4 delims=:, " %%a in ('FINDSTR /c:"VSIM2000" vsim_log.txt') do echo.  %%b %%c: %%d> ..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt 2>nul
	for /f "tokens=5,6,7,8,9,10,11,12 delims=:, " %%a in ('FINDSTR /c:"Product" vsim_log.txt') do echo.  %%a %%b:    %%c %%d %%e> ..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt 2>nul
	echo.> ..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt  
	echo.> ..\_ && type ..\_ && type ..\_ >> ..\SessionLog.txt
	timeout /t 1 >nul
	popd
	goto :CleanUp
exit /b
	
:: ###############
:: ### CleanUp ###
:: ###############
:CleanUp
	echo Do you want to generate a report?
	echo --------------------------------
	CHOICE /C YN /M "Y:Yes, please. N:No, not this time."
	if %ERRORLEVEL% EQU 1 goto :GenerateReport
	if %ERRORLEVEL% EQU 2 goto :Exit
	
:GenerateReport
	echo.
	echo.
	echo Please choose a folder to save the lab report.
	echo ----------------------------------------------
setlocal
	set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Please choose a folder to save the lab report.',0,0).self.path""
	for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "folder=%%I"
setlocal enabledelayedexpansion
	if [!folder!]==[] goto :CleanUp
	echo You chose: !folder!
	echo.
	if not exist "Lab_Reports\" mkdir Lab_Reports\ 2>nul
:lab_number
	echo.
	echo. Supported characters for lab number are [a-z, A-Z, 0-9, -, _]
	echo. Example for ST : "STO_TS17"
	echo. Example for SST: "STO_MIX63"
:EnterLabNumber
	echo.
	set /p "Labnumber=Enter lab number: "
	for /f "delims=0123456789_-abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" %%a in ("%Labnumber%") do goto :lab_number
	if [%Labnumber%]==[] echo Lab number cannot be empty! && goto :EnterLabNumber
	set "dash=-"
	if "%mr%"=="?? " set "mr=" && set "dash="
	if "%mr%"=="   " set "mr=" && set "dash="
	echo. Lab Name:             %Labnumber%-%cohp%-%project%%dash%%mr%>Lab_Reports\WI_LabReport_%Labnumber%_%today%_%hour%_%min%_%secs%.txt
	echo. Report generation: %today%_%hour%_%min%_%secs%>>Lab_Reports\WI_LabReport_%Labnumber%_%today%_%hour%_%min%_%secs%.txt
	echo. Report location:     !folder!\WI_LabReport_%Labnumber%-%cohp%-%project%%dash%%mr%_%today%_%hour%_%min%_%secs%.pdf>>Lab_Reports\WI_LabReport_%Labnumber%_%today%_%hour%_%min%_%secs%.txt
	echo. ****************************************************************************************>>Lab_Reports\WI_LabReport_%Labnumber%_%today%_%hour%_%min%_%secs%.txt
	type SessionLog.txt >>Lab_Reports\WI_LabReport_%Labnumber%_%today%_%hour%_%min%_%secs%.txt
	nircmd exec hide txt2pdf Lab_Reports\WI_LabReport_%Labnumber%_%today%_%hour%_%min%_%secs%.txt "!folder!\WI_LabReport_%Labnumber%-%cohp%-%project%%dash%%mr%_%today%_%hour%_%min%_%secs%.pdf" -pfn100 -ppf7 -pfs11
	if exist "COM_Logs\" rd /q /s "COM_Logs\" 2>nul
	if exist "Temp\" rd /q /s "Temp\" 2>nul
	if exist coms.txt del /f /q coms.txt 2>nul
	if exist _ del /f /q _ 2>nul
	if exist cports.cfg del /f /q cports.cfg 2>nul
	if exist settings del /f /q settings 2>nul
	if exist SessionLog.txt del /f /q SessionLog.txt 2>nul
	if exist Lab_Reports\WI_LabReport_%Labnumber%_%today%_%hour%_%min%_%secs%.txt del /f /q Lab_Reports\WI_LabReport_%Labnumber%_%today%_%hour%_%min%_%secs%.txt 2>nul
	taskkill /IM "plink.exe" /T /F >nul 2>nul
	taskkill /IM "timeout.exe" /T /F >nul 2>nul
	if exist "Lab_Reports\" rd /q /s "Lab_Reports\" 2>nul
	start "" "!folder!\WI_LabReport_%Labnumber%-%cohp%-%project%%dash%%mr%_%today%_%hour%_%min%_%secs%.pdf"
endlocal
exit


:Exit
if exist "COM_Logs\" rd /q /s "COM_Logs\" 2>nul
if exist "Temp\" rd /q /s "Temp\" 2>nul
if exist coms.txt del /f /q coms.txt 2>nul
if exist _ del /f /q _ 2>nul
if exist cports.cfg del /f /q cports.cfg 2>nul
if exist settings del /f /q settings 2>nul
if exist SessionLog.txt del /f /q SessionLog.txt 2>nul
taskkill /IM "plink.exe" /T /F >nul 2>nul
taskkill /IM "timeout.exe" /T /F >nul 2>nul
exit