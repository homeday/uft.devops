@echo off
del /s /q c:\windows\installer\MSI*.tmp*"
for /D  %%G  IN (C:\Installation_uft\*) DO (call :subLoop1 %%G)
GOTO :DONE1
:subLoop1

SET each=%1
SET file=%each:~-13%
echo %each%
rd /s /q "%each%"  2>nul 
GOTO :eof

:DONE1
for /D  %%G  IN (C:\UFTUninstaller_v2.0\Backup*) DO (call :subLoop2 %%G)
GOTO :DONE2
:subLoop2
SET each=%1
echo %each%
rd /s /q "%each%"  2>nul 
GOTO :eof

:DONE2
@echo on

