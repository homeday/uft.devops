REM %1 Source
REM %2 Destination
REM %3 Zip file name


SET SRC=%1
SET DEST=%2
SET FILE_NAME=%3
IF "%SRC%" == "" (SET SRC="\\mydastr01.hpeswlab.net\products\FT\UFT_Tools\CodeSign\Aujas")
IF "%DEST%" == "" (SET DEST="D:\UFT_Tools\CodeSign\AUJAS\")
IF "%FILE_NAME%" == "" (SET FILE_NAME="win_cli_3.1.4.zip")
robocopy %SRC% %DEST% %FILE_NAME%