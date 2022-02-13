:: Supported parameters
:: BuildNumber
:: Patch_ID
:: Rubicon Username
:: Rubicon Password

net use * /delete /y
REM IF NOT EXIST P: ECHO P: was not mounted. mounting it to \\\mydastr01.hpeswlab.net\products & net use P: \\\mydastr01.hpeswlab.net\products %4 /USER:%3
SET STORAGE_WIN_SERVER=\\mydanas01.swinfra.net
net use %STORAGE_WIN_SERVER%\IPC$ %4 /USER:%3
set PATCHDIR=%STORAGE_WIN_SERVER%\products\FT\QTP\win32_release\%1\Patches\UFT\%2\PatchResult\default
pushd %PATCHDIR%
%2.exe /s /e /f C:\temp\%2
popd 

pushd C:\temp\%2\msp
msiexec /update %2.msp /qn /l*xv C:\%2.log
popd

