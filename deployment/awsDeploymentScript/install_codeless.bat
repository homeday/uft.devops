
:: CDLS BuildNumber
net use * /delete /y
:: Enable Symbolic like settings
fsutil behavior set SymlinkEvaluation R2L:1 
fsutil behavior set SymlinkEvaluation R2R:1

SET STORAGE_WIN_SERVER=\\rubicon.cross.admlabs.aws.swinfra.net\fsx
net use P: %STORAGE_WIN_SERVER%\products /PERSISTENT:YES

echo *********************************
net use
echo *********************************

ECHO Installing AI
pushd P:\FT\CDLS-AI\win32_release\%1\DVD
cmd /c setup.exe /InstallOnlyPrerequisite /s
popd 

pushd P:\FT\QTP\win32_release
cmd /c MsiExec /norestart /qn /i "%STORAGE_WIN_SERVER%\products\FT\CDLS-AI\win32_release\%1\DVD\AI_Installer.msi" /l*xv C:\AI_Install_Log.txt 
SET ERRORCODE=%ERRORLEVEL%
popd


exit 0

