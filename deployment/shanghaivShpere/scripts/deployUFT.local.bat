REM net use * /delete /y

REM IF NOT EXIST P: ECHO P: was not mounted. mounting it to \\%3\builds & net use P: \\%3\builds /user:WORKGROUP\qtp qtpdev
REM set DVD_Path=\\%3\builds\%1\DVD
REM set DVD_Path=P:\%1\DVD


NET USE \\%3\IPC$ /u:WORKGROUP\qtp qtpdev
if exist C:\%1 goto restart_installation
md C:\%1\DVD
REM robocopy P:\%1\DVD c:\%1\DVD /e /np /R:5 /mt:4
robocopy \\%3\builds\%1\DVD c:\%1\DVD /e /np /R:5 /mt:4

echo DVD copying finished

md C:\%1\prerequisites

rem Copy prerequisites 
REM robocopy P:\%1\prerequisites c:\%1\prerequisites /e /np /R:5 /mt:4
robocopy \\%3\builds\%1\prerequisites c:\%1\prerequisites /e /np /R:5 /mt:4

:restart_installation 
echo installation files copied, Starting the installation
set DVD_Path=c:\%1\DVD

set SEE_MASK_NOZONECHECKS=1
set SUCCESS_STRING="HP Unified Functional Testing -- Installation completed successfully"

pushd c:\%1\prerequisites
setup.exe /InstallOnlyPrerequisite /s
popd


set AddinsToInstall=Core_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,Help_Documents,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in
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

MsiExec /norestart /qn /i "%DVD_Path%\Unified Functional Testing\MSI\Unified_Functional_Testing_x64.msi" /l*v C:\UFT_Install_Log.txt ADDLOCAL=%AddinsToInstall% LICSVR=%LicenseAddress% %UFTConfiguration% %LOCALE_STRING%


if %errorlevel% EQU 3010 goto RESTART
goto CheckOS
:RESTART
set RestartNeed=true


:CheckOS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT

IF NOT EXIST "C:\Program Files (x86)\HP\Unified Functional Testing" GOTO ERRINSTALL
type c:\UFT_Install_Log.txt | findstr /C:%SUCCESS_STRING%>nul
if NOT "%errorlevel%"=="0" (GOTO ERRINSTALL) ELSE (GOTO END)

:32BIT


IF NOT EXIST "C:\Program Files\HP\Unified Functional Testing" GOTO ERRINSTALL
type c:\UFT_Install_Log.txt | findstr /C:%SUCCESS_STRING%>nul
if NOT "%errorlevel%"=="0" (GOTO ERRINSTALL) ELSE (GOTO END)

:ERRINSTALL
echo "HP Unified Functional Testing -- Installation Failed!"
exit 1



:END
IF NOT "%RestartNeed%" == "true" goto Finished
Echo "HP Unified Functional Testing -- Installation completed BUT Restart is needed...."
exit 0
:Finished
echo %SUCCESS_STRING%
exit 0