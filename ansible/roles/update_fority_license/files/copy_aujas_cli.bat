REM %1 Source
REM %2 Destination
REM %3 Zip file name


SET SRC=%1
SET DEST=%2
SET FILE_NAME=%3
IF "%SRC%" == "" (SET SRC="\\mydastr01.hpeswlab.net\products\FT\UFT_Tools\HP_Fortify_SCA_and_Apps_4.42")
IF "%DEST%" == "" (SET DEST="D:\HP_Fortify_SCA_and_Apps_4.42")
IF "%FILE_NAME%" == "" (SET FILE_NAME="fortify.license")
robocopy %SRC% %DEST% %FILE_NAME%

