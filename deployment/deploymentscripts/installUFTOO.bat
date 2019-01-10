net use * /delete /y
SET STORAGE_WIN_SERVER=\\mydastr01.hpeswlab.net
net use %STORAGE_WIN_SERVER% %4 /USER:%3
set DVD_Path=C:\temp\UFT
echo extract the compressed file
7z x %STORAGE_WIN_SERVER%\products\FT\QTP\win32_release\%1\SetupBuilder\Output\UFT\UFTSetup_ForOO.7z -o%DVD_Path%



set CURRENT_PATH=%~dp0
for /d %%i in ("%~d0%~p0") do set CURR_PATH=%%~fi
set TARGETDIR=%cd%
IF "%ProgramFiles(x86)%"=="" set MSI_FILE_NAME=Unified_Functional_Testing_x86.msi
IF NOT "%ProgramFiles(x86)%"=="" set MSI_FILE_NAME=Unified_Functional_Testing_x64.msi


set FULL_PATH=%CURR_PATH%
set FULL_PATH=%DVD_Path%
set LicenseAddress=%2

IF NOT EXIST "%FULL_PATH%%MSI_FILE_NAME%" (
	echo "Can't find the installer package %FULL_PATH%%MSI_FILE_NAME%"
	goto ERROR
)

For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set currdate=%%c_%%a_%%b)
For /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set currtime=%%a%%b)
SET MSI_LOG_FILE_NAME=UFTSetup_%currdate%_%currtime%.log
SET MSI_LOG_FILE_NAME=%MSI_LOG_FILE_NAME: =_%

echo Checking KB
cmd /c "%FULL_PATH%prerequisites\vc2015_redist_x86\VC2015Prerequisite.exe" silent
IF ERRORLEVEL 1 (
	echo Missing some KB
	goto ERROR
)

echo Installing the prerequisites
cmd /c "%FULL_PATH%setup.exe" /InstallOnlyPrerequisite /s

echo Installing UFT
set AddinsToInstall=Core_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in,RPA
set UFTConfiguration=CONF_MSIE=1 ALLOW_RUN_FROM_ALM=1 ALLOW_RUN_FROM_SCRIPTS=1 DLWN_SCRIPT_DBGR=1
cmd /c MsiExec /norestart /qn /i "%FULL_PATH%%MSI_FILE_NAME%" /l*xv C:\UFT_Install_Log.txt %UFTConfiguration% LICSVR=%LicenseAddress% LICID=23078 ADDLOCAL=%AddinsToInstall%

goto END

:END
exit 0

:ERROR
exit 1


