@echo off
for /D  %%G  IN (C:\*) DO (call :subLoop1 %%G)
GOTO :DONE1
:subLoop1

SET each=%1
SET file=%each:~-13%
echo %each%
IF [%file%]==[_Installation] (
rd /s /q "%each%"  2>nul 
echo file=%file%
)
GOTO :eof

:DONE1
for /D  %%G  IN (C:\UFTUninstaller_v2.0\Backup*) DO (call :subLoop2 %%G)
GOTO :DONE2
:subLoop2
SET each=%1
rd /s /q "%each%"  2>nul 
GOTO :eof

:DONE2
@echo on

