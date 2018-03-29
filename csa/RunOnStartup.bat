@echo off
REM net use /delete * /Y
REM net use H: \\mydastr01.hpeswlab.net\repositories\netapp\groups\qa\ft_qa /user:emea\$qtpqa000 pan.dot.bit-106 /P:No
REM net use P: \\mydastr01.hpeswlab.net\products /user:emea\$qtpqa000 pan.dot.bit-106 /P:No
REM pushd H:\QTP_AUTOMATION\AUTOMATION\Tools\JenkinSlave
REM SlaveStartupScript.bat
REM popd
C:\SlaveStartupScript.bat