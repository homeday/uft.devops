:: Supported parameters
:: BuildNumber
:: Patch_ID
net use * /delete /y

:: Enable Symbolic like settings
fsutil behavior set SymlinkEvaluation R2L:1 
fsutil behavior set SymlinkEvaluation R2R:1

SET STORAGE_WIN_SERVER=\\rubicon.cross.admlabs.aws.swinfra.net\NAS_NTPP
net use P: %STORAGE_WIN_SERVER%\products /u:_ft_auto /PERSISTENT:YES

echo *********************************
net use
echo *********************************

set PATCHDIR=P:\FT\QTP\win32_release\%1\Patches\UFT\%2\PatchResult\default
pushd %PATCHDIR%
%2.exe /s /e /f C:\temp\%2
popd 

pushd C:\temp\%2\msp
msiexec /update %2.msp /qn /l*xv C:\%2.log
popd

