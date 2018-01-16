net use * /delete /y

@echo Installing KB2999226
REM xcopy /y /d \\%3\tools\Windows6.1-KB2999226-x64.msu C:\
wusa.exe C:\Windows6.1-KB2999226-x64.msu /extract:C:\Windows6.1-KB2999226-x64\
DISM.exe /Online /Add-Package /PackagePath:C:\Windows6.1-KB2999226-x64\Windows6.1-KB2999226-x64.cab


IF NOT EXIST P: ECHO P: was not mounted. mounting it to \\%3\builds & net use P: \\%3\builds /user:WORKGROUP\appsadmin appsadmin /persistent:no
set DVD_Path=P:\%1\DVD
REM SET DVD_Path=\\%3\builds\%1\DVD
REM set DVD_Path=C:\DVD

set SEE_MASK_NOZONECHECKS=1
set SUCCESS_STRING="completed successfully"

pushd %DVD_Path%\Unified Functional Testing\EN
REM net stop wuauserv 
REM sc config wuauserv start= disabled 
setup.exe /InstallOnlyPrerequisite /s
popd 


set AddinsToInstall=Core_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in
set UFTConfiguration=CONF_MSIE=1 ALLOW_RUN_FROM_ALM=1 ALLOW_RUN_FROM_SCRIPTS=1 DLWN_SCRIPT_DBGR=1
set LeanFTConfiguration=LeanFT,LeanFT_Engine,LeanFT_Client,Vs2013Addin,EclipseAddin  ECLIPSE_INSTALLDIR="c:\eclipse"
set LicenseAddress=%2


REM ######################   Getting the language of the machine and setting the correct PRODUCT_LOCALE ######################   
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "(Get-UICulture).ThreeLetterWindowsLanguageName"`) DO (SET THREE_LETTER_LANG=%%F)
IF %THREE_LETTER_LANG%==ENU (
	SET LOCALE_STRING=
	) ELSE IF %THREE_LETTER_LANG%==ESN (
	SET LOCALE_STRING=PRODUCT_LOCALE=ESP
	) ELSE (
	SET LOCALE_STRING=PRODUCT_LOCALE=%THREE_LETTER_LANG%
	)
ECHO ##%LOCALE_STRING%##

MsiExec /qn /i "%DVD_Path%\Unified Functional Testing\MSI\Unified_Functional_Testing_x64.msi" /l*xv C:\UFT_Install_Log.txt ADDLOCAL=%AddinsToInstall% LICSVR=%LicenseAddress% %UFTConfiguration% %LOCALE_STRING%


if %errorlevel% EQU 3010 goto RESTART
goto CheckOS
:RESTART
set RestartNeed=true


:CheckOS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT

IF NOT EXIST "C:\Program Files (x86)\HPE\Unified Functional Testing\bin\UFT.exe" GOTO ERRINSTALL
type c:\UFT_Install_Log.txt | findstr /C:%SUCCESS_STRING%>nul
if NOT "%errorlevel%"=="0" (GOTO ERRINSTALL) ELSE (GOTO END)

:32BIT


IF NOT EXIST "C:\Program Files\HPE\Unified Functional Testing\bin\UFT.exe" GOTO ERRINSTALL
type c:\UFT_Install_Log.txt | findstr /C:%SUCCESS_STRING%>nul
if NOT "%errorlevel%"=="0" (GOTO ERRINSTALL) ELSE (GOTO END)

:ERRINSTALL
echo "HP Unified Functional Testing -- Installation Failed!"
net use * /delete /y 
exit 1



:END
IF NOT "%RestartNeed%" == "true" goto Finished
Echo "HP Unified Functional Testing -- Installation completed BUT Restart is needed...."
net use * /delete /y 
exit 0
:Finished
echo %SUCCESS_STRING%
net use * /delete /y 
exit 0