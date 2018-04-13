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
@echo on
