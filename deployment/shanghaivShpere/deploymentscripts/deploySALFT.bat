net use * /delete /y

@echo Installing KB2999226
REM xcopy /y /d \\%3\tools\Windows6.1-KB2999226-x64.msu C:\
REM wusa.exe C:\Windows6.1-KB2999226-x64.msu /extract:C:\Windows6.1-KB2999226-x64\
REM DISM.exe /Online /Add-Package /PackagePath:C:\Windows6.1-KB2999226-x64\Windows6.1-KB2999226-x64.cab

for /F  "tokens=4-5 delims=. " %%i in ( 'ver' ) DO (SET OS_VERSION=%%i.%%j)
echo OS_VERSION=%OS_VERSION%
if "10.0" == "%OS_VERSION%" (
	echo Windows %OS_VERSION%
) else (
	wusa.exe C:\Windows6.1-KB2999226-x64.msu /extract:C:\Windows6.1-KB2999226-x64\
	DISM.exe /Online /Add-Package /PackagePath:C:\Windows6.1-KB2999226-x64\Windows6.1-KB2999226-x64.cab
)

IF NOT EXIST P: ECHO P: was not mounted. mounting it to \\%3\builds & net use P: \\%3\builds /user:WORKGROUP\appsadmin appsadmin /persistent:no
set DVD_Path=P:\%1\DVD
REM set DVD_Path=C:\DVD
REM SET DVD_Path=\\%3\builds\%1\DVD

set SEE_MASK_NOZONECHECKS=1
set SUCCESS_STRING="Installation completed successfully"

pushd %DVD_Path%\LeanFT\EN
setup.exe /InstallOnlyPrerequisite /s
popd 


set AddinsToInstall=LeanFT_Engine,LeanFT_Client,RegVS2013,RegEclipse,RegIntelliJ
REM set UFTConfiguration=CONF_MSIE=1 ALLOW_RUN_FROM_ALM=1 ALLOW_RUN_FROM_SCRIPTS=1 DLWN_SCRIPT_DBGR=1
REM set LeanFTConfiguration=LeanFT_Engine,LeanFT_Client,Vs2013Addin,EclipseAddin  ECLIPSE_INSTALLDIR="c:\eclipse\eclipse"
set LeanFTConfiguration=ECLIPSE_INSTALLDIR="c:\eclipse\eclipse"
set LicenseAddress=%2


MsiExec /norestart /qn /i "%DVD_Path%\LeanFT\MSI\LeanFT_x64.msi" /l*xv C:\LFT_Install_Log.txt ADDLOCAL=%AddinsToInstall% LICSVR=%LicenseAddress% ECLIPSE_INSTALLDIR="c:\eclipse\eclipse" 

if %errorlevel% EQU 0 GOTO done

if %errorlevel% EQU 3010 goto RESTART
GOTO end

:done
@echo %SUCCESS_STRING%
net use * /delete /y 
exit 0

:RESTART
@Echo "LeanFT -- Installation completed BUT Restart is needed...."
net use * /delete /y 
exit 0

:end
net use * /delete /y 
exit 0
