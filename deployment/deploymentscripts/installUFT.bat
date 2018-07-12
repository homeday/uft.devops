
net use * /delete /y

SET STORAGE_WIN_SERVER=\\mydastr01.hpeswlab.net
REM IF NOT EXIST X: ECHO X: was not mounted. mounting it to \\mydastr01.hpeswlab.net\products\FT\QTP\win32_release & net use X: \\mydastr01.hpeswlab.net\products\FT\QTP\win32_release %4 /USER:%3
net use %STORAGE_WIN_SERVER% %4 /USER:%3
set DVD_Path=Z:\%1\DVD_WIX

set SEE_MASK_NOZONECHECKS=1
set SUCCESS_STRING="completed successfully"
pushd %STORAGE_WIN_SERVER%\products\FT\QTP\win32_release\%1\SetupBuilder\Output\UFT\prerequisites
setup.exe /InstallOnlyPrerequisite /s
popd 

SET DVDNUM=%1
IF "%DVDNUM:~0,5%"=="12.02" goto 12.02 
IF "%DVDNUM:~0,9%"=="UFT_12_02" goto 12.02

goto common

:12.02
set AddinsToInstall=Core_Components,Web_Add_in,ALM_Plugin,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in 
goto continue

:common
set AddinsToInstall=Core_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in
goto continue

:continue
echo %AddinsToInstall%



set UFTConfiguration=CONF_MSIE=1 ALLOW_RUN_FROM_ALM=1 ALLOW_RUN_FROM_SCRIPTS=1 DLWN_SCRIPT_DBGR=1
set LeanFTConfiguration=LeanFT,LeanFT_Engine,LeanFT_Client,Vs2012Addin,Vs2013Addin,IntelliJAddin,EclipseAddin ECLIPSE_INSTALLDIR="C:\DevTools\eclipse"
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

pushd %STORAGE_WIN_SERVER%\products\FT\QTP\win32_release
IF "%5" == "" (
echo installing UFT

MsiExec /norestart /qn /i "Z:\FT\QTP\win32_release\14.50.741.0\DVD_WIX\Unified Functional Testing\MSI\Unified_Functional_Testing_x64.msi" /l*xv C:\UFT_Install_Log.txt ADDLOCAL=%AddinsToInstall% LICSVR=%LicenseAddress% %UFTConfiguration% %LOCALE_STRING%

) ELSE (
echo installing UFT and LFT as a feature	

MsiExec /norestart /qn /i "Z:\FT\QTP\win32_release\14.50.741.0\DVD_WIX\Unified Functional Testing\MSI\Unified_Functional_Testing_x64.msi" /l*xv C:\UFT_Install_Log.txt ADDLOCAL=%AddinsToInstall%,%LeanFTConfiguration% LICSVR=%LicenseAddress% %UFTConfiguration% %LOCALE_STRING%	

)
popd


if %errorlevel% EQU 3010 goto RESTART
goto CheckOS
:RESTART
set RestartNeed=true


:CheckOS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
IF EXIST "C:\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\UFT.exe" GOTO SUCCESS
IF EXIST "C:\Program Files (x86)\HPE\Unified Functional Testing\bin\UFT.exe" GOTO SUCCESS
IF EXIST "C:\Program Files (x86)\HP\Unified Functional Testing\bin\UFT.exe" GOTO SUCCESS


:SUCCESS
type c:\UFT_Install_Log.txt | findstr /C:%SUCCESS_STRING%>nul
if NOT "%errorlevel%"=="0" (GOTO ERRINSTALL) ELSE (GOTO END)


:32BIT

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
IF NOT "%RestartNeed%" == "true" goto Finished
Echo "Unified Functional Testing -- Installation completed BUT Restart is needed...."
IF NOT "%5" == "" (
	"C:\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\HP.UFT.LicenseInstall.exe" seat "C:\HP UFT-licfile.dat"
)
exit 0
:Finished
IF NOT "%5" == "" (
	"C:\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\HP.UFT.LicenseInstall.exe" seat "C:\HP UFT-licfile.dat"
)
echo %SUCCESS_STRING%
exit 0

