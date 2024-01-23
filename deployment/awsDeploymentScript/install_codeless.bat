
:: CDLS BuildNumber
net use * /delete /y
:: Enable Symbolic like settings
fsutil behavior set SymlinkEvaluation R2L:1 
fsutil behavior set SymlinkEvaluation R2R:1

SET STORAGE_WIN_SERVER=\\rubicon.cross.admlabs.aws.swinfra.net\NAS_NTPP
net use P: %STORAGE_WIN_SERVER%\products /u:swinfra.net\_btoabuild ruw.gnd.rbs.260 /PERSISTENT:YES
net use

robocopy /s /e P:\FT\CDLS-AI\win32_release\%1\DVD_Remote C:\Installation_uft\CDLS-AI\%1\DVD /MT:16 /R:5 /NDL /NFL
set DVD_Path=C:\Installation_uft\CDLS-AI\%1\DVD

net use * /delete /y

echo *********************************
echo Installing prerequisites
echo *********************************

pushd %DVD_Path%
cmd /c setup.exe /InstallOnlyPrerequisite /s

echo *********************************
echo Installing AI
echo *********************************

cmd /c MsiExec /norestart /qn /i "%DVD_Path%\AI_Installer.msi" /l*xv C:\AI_Install_Log.txt 
SET ERRORCODE=%ERRORLEVEL%

popd
exit 0

