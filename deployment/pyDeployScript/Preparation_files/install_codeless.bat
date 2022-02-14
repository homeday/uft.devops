
net use * /delete /y
:: CDLS BuildNumber
:: Rubicon username
:: Rubicon Password

SET STORAGE_WIN_SERVER=\\mydanas01.swinfra.net
REM IF NOT EXIST X: ECHO X: was not mounted. mounting it to \\mydastr01.hpeswlab.net\products\FT\QTP\win32_release & net use X: \\mydastr01.hpeswlab.net\products\FT\QTP\win32_release %4 /USER:%3
net use %STORAGE_WIN_SERVER%\IPC$ %3 /USER:%2

ECHO Installing AI
pushd %STORAGE_WIN_SERVER%\products\FT\CDLS-AI\win32_release\%1\DVD
cmd /c setup.exe /InstallOnlyPrerequisite /s
popd 

pushd %STORAGE_WIN_SERVER%\products\FT\QTP\win32_release
cmd /c MsiExec /norestart /qn /i "%STORAGE_WIN_SERVER%\products\FT\CDLS-AI\win32_release\%1\DVD\AI_Installer.msi" /l*xv C:\AI_Install_Log.txt 
SET ERRORCODE=%ERRORLEVEL%
popd


exit 0

