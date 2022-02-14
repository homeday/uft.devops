
net use * /delete /y

SET STORAGE_WIN_SERVER=\\mydanas01.swinfra.net
REM IF NOT EXIST X: ECHO X: was not mounted. mounting it to \\mydastr01.hpeswlab.net\products\FT\QTP\win32_release & net use X: \\mydastr01.hpeswlab.net\products\FT\QTP\win32_release %4 /USER:%3
net use %STORAGE_WIN_SERVER%\IPC$ %4 /USER:%3

robocopy /s /e %STORAGE_WIN_SERVER%\products\FT\QTP\win32_release\%1\DVD_WIX C:\Installation_uft\%1 /MT:16 /R:5 /NDL /NFL
set DVD_Path=C:\Installation_uft\%1

set SEE_MASK_NOZONECHECKS=1
set SUCCESS_STRING="completed successfully"

pushd %STORAGE_WIN_SERVER%\products\FT\QTP\win32_release\%1\SetupBuilder\Output\UFT\prerequisites
cmd /c setup.exe /InstallOnlyPrerequisite /s
popd 

SET DVDNUM=%1
IF "%DVDNUM:~0,5%"=="12.02" goto 12.02 
IF "%DVDNUM:~0,9%"=="UFT_12_02" goto 12.02

goto common

:12.02
	set AddinsToInstall=Core_Components,Web_Add_in,ALM_Plugin,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in 
	goto continue

:common
	set AddinsToInstall=Core_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in,AIServices,PDF_Add_in,Abbyy_OCR
	goto continue

:continue
	echo %AddinsToInstall%

set UFTConfiguration=CONF_MSIE=1 ALLOW_RUN_FROM_ALM=1 ALLOW_RUN_FROM_SCRIPTS=1 DLWN_SCRIPT_DBGR=1
set LeanFTConfiguration=UFTDeveloper,UFTDeveloper_Engine,UFTDeveloper_Client,Vs2015Addin,IntelliJAddin,EclipseAddin ECLIPSE_INSTALLDIR="C:\DevTools\eclipse"
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


echo installing UFT and LFT as a feature	
:: Setting MSI path based on the condition
SET msi_path="%DVD_Path%\Unified Functional Testing\MSI\Unified_Functional_Testing_x64.msi"
IF EXIST "%DVD_Path%\UFT One\MSI\UFT_One_x64.msi" (
	SET msi_path="%DVD_Path%\UFT One\MSI\UFT_One_x64.msi"
) 
echo msi_path=%msi_path%

cmd /c MsiExec /norestart /qn /i %msi_path% /l*xv C:\UFT_Install_Log.txt ADDLOCAL=%AddinsToInstall%,%LeanFTConfiguration% LICSVR=%LicenseAddress% LICID=23078 %UFTConfiguration% %LOCALE_STRING%	


if %errorlevel% EQU 3010 goto RESTART
goto CheckOS
:RESTART
	set RestartNeed=true

:CheckOS
	IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
	IF EXIST "C:\Program Files (x86)\Micro Focus\UFT One\bin\UFT.exe" GOTO SUCCESS
	IF EXIST "C:\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\UFT.exe" GOTO SUCCESS
	IF EXIST "C:\Program Files (x86)\HPE\Unified Functional Testing\bin\UFT.exe" GOTO SUCCESS
	IF EXIST "C:\Program Files (x86)\HP\Unified Functional Testing\bin\UFT.exe" GOTO SUCCESS

:SUCCESS
	type c:\UFT_Install_Log.txt | findstr /C:%SUCCESS_STRING%>nul
	if NOT "%errorlevel%"=="0" (GOTO ERRINSTALL) ELSE (GOTO END)

:32BIT
	IF EXIST "C:\Program Files\Micro Focus\UFT One\bin\UFT.exe" GOTO SUCCESS32
	IF EXIST "C:\Program Files\Micro Focus\Unified Functional Testing\bin\UFT.exe" GOTO SUCCESS32
	IF EXIST "C:\Program Files\HPE\Unified Functional Testing\bin\UFT.exe" GOTO SUCCESS32
	IF EXIST "C:\Program Files\HP\Unified Functional Testing\bin\UFT.exe" GOTO SUCCESS32

:SUCCESS32
	type c:\UFT_Install_Log.txt | findstr /C:%SUCCESS_STRING%>nul
	if NOT "%errorlevel%"=="0" (GOTO ERRINSTALL) ELSE (GOTO END)

:ERRINSTALL
	echo "Unified Functional Testing -- Installation Failed!"
	exit 1

:END
	exit 0

