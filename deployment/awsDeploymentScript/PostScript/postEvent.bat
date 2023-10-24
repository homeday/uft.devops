regedit /s %1
echo f | xcopy /Y %2 %ProgramData%\Hewlett-Packard\UFT\Common\
echo grant premission to Everyone
cmd /c icacls "%ProgramData%\Hewlett-Packard" /grant Everyone:(OI)(CI)F /T
