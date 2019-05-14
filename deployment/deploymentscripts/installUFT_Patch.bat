net use * /delete /y
IF NOT EXIST P: ECHO P: was not mounted. mounting it to \\\mydastr01.hpeswlab.net\products & net use P: \\\mydastr01.hpeswlab.net\products 
REM %4 /USER:%3
set PATCHDIR=P:\FT\QTP\win32_release\%1\Patches\UFT\%2\PatchResult\default
pushd %PATCHDIR%
%2.exe /s /e /f C:\temp\%2
popd 

pushd C:\temp\%2\msp
msiexec /update %2.msp /qn /l*xv C:\%2.log
popd

