from ConnectMachine import ConnectMachine
from Deploy import Deploy
import xmltodict
machine = { "name": "", "sid": "", "cid":"", "username":"", "password":"", "domain": ""}
machines = [
    { "name": "", "sid": "", "cid":"", "username":"", "password":"", "domain": ""},
    { "name": "", "sid": ""}
]

print(machines)

with open('machines.xml') as f:
    text = f.read()

d = xmltodict.parse(text)
GlobalProperties = {}
hosts = []
for k,deploy in d.items():
    for k, gp in deploy.items():
        if(k == "GlobalProperties"):
            GlobalProperties = dict(gp)
        if(k == "hosts"):
            for key, value in gp.items():
                for host in value:
                    hosts.append(dict(host))

 
# print(GlobalProperties)
# print(hosts)
# conn = ConnectMachine("myd-hvm00266.swinfra.net")
# print(conn.runCommand('ipconfig', ['/all']))
#deploy = Deploy("myd-hvm00266.swinfra.net", "2c90b185765081f00176ffbd31485073", "8a471d916170325b016174057e31037b")
# deploy = Deploy("myd-hvm03853.swinfra.net", "2c9090b36e91b9e10170389b750579e5")
# print(deploy.revert_snapshot())
# print(deploy.WaitForWinrmServices())
# print(deploy.prepare_machine())
#print(deploy.install_uft("2021.1.0.862", "uninstall"))
# print(deploy.uninstall())
# print(deploy.install_Test())
# print(conn.CopyFile("C:\\works\\naren\\DevOps\\devops\\auto_deploy\\deployment\\Preparation_files\\*", "C:\\Preparation_files\\"))
#print(conn.copy_file("C:\\works\\naren\\DevOps\\devops\\auto_deploy\\deployment\\wrapper.py", "C:\\test.py"))
#print(conn.runCommand('cd /'))
#print(conn.runCommand('dir'))

print( b'\r\nC:\\Users\\_ft_auto>net use * /delete /y \r\nThere are no entries in the list.\r\n\r\n\r\nC:\\Users\\_ft_auto>SET STORAGE_WIN_SERVER=\\\\mydanas01.swinfra.net \r\n\r\nC:\\Users\\_ft_auto>REM IF NOT EXIST X: ECHO X: was not mounted. mounting it to \\\\mydastr01.hpeswlab.net\\products\\FT\\QTP\\win32_release & net use X: \\\\mydastr01.hpeswlab.net\\products\\FT\\QTP\\win32_release ruw.gnd.rbs.260 /USER:SWINFRA.NET\\_btoabuild \r\n\r\nC:\\Users\\_ft_auto>net use \\\\mydanas01.swinfra.net ruw.gnd.rbs.260 /USER:SWINFRA.NET\\_btoabuild \r\nThe command completed successfully.\r\n\r\n\r\nC:\\Users\\_ft_auto>set DVD_Path=Z:\\2021.1.0.869\\DVD \r\n\r\nC:\\Users\\_ft_auto>set SEE_MASK_NOZONECHECKS=1 \r\n\r\nC:\\Users\\_ft_auto>set SUCCESS_STRING="completed successfully" \r\n\r\nC:\\Users\\_ft_auto>pushd \\\\mydanas01.swinfra.net\\products\\FT\\QTP\\win32_release\\2021.1.0.869\\SetupBuilder\\Output\\UFT\\prerequisites \r\n\r\nZ:\\FT\\QTP\\win32_release\\2021.1.0.869\\SetupBuilder\\Output\\UFT\\Prerequisites>cmd /c setup.exe /InstallOnlyPrerequisite /s \r\n\r\nZ:\\FT\\QTP\\win32_release\\2021.1.0.869\\SetupBuilder\\Output\\UFT\\Prerequisites>popd  \r\n\r\nC:\\Users\\_ft_auto>ping 127.0.0.1 -n 50   1>nul \r\n\r\nC:\\Users\\_ft_auto>SET DVDNUM=2021.1.0.869 \r\n\r\nC:\\Users\\_ft_auto>IF "2021." == "12.02" goto 12.02  \r\n\r\nC:\\Users\\_ft_auto>IF "2021.1.0." == "UFT_12_02" goto 12.02 \r\n\r\nC:\\Users\\_ft_auto>goto common \r\n\r\nC:\\Users\\_ft_auto>set AddinsToInstall=Core_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in,AIServices,PDF_Add_in,Abbyy_OCR \r\n\r\nC:\\Users\\_ft_auto>goto continue \r\n\r\nC:\\Users\\_ft_auto>echo Core_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in,AIServices,PDF_Add_in,Abbyy_OCR \r\nCore_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in,AIServices,PDF_Add_in,Abbyy_OCR\r\n\r\nC:\\Users\\_ft_auto>set UFTConfiguration=CONF_MSIE=1 ALLOW_RUN_FROM_ALM=1 ALLOW_RUN_FROM_SCRIPTS=1 DLWN_SCRIPT_DBGR=1 \r\n\r\nC:\\Users\\_ft_auto>set LeanFTConfiguration=LeanFT,LeanFT_Engine,LeanFT_Client,Vs2012Addin,Vs2013Addin,IntelliJAddin,EclipseAddin ECLIPSE_INSTALLDIR="C:\\DevTools\\eclipse" \r\n\r\nC:\\Users\\_ft_auto>set LicenseAddress=mama.swinfra.net \r\n\r\nC:\\Users\\_ft_auto>REM ######################   Getting the language of the machine and setting the correct PRODUCT_LOCALE ######################    \r\n\r\nC:\\Users\\_ft_auto>FOR /F "tokens=* USEBACKQ" %F IN (`powershell "(Get-UICulture).ThreeLetterWindowsLanguageName"`) DO (SET THREE_LETTER_LANG=%F ) \r\n\r\nC:\\Users\\_ft_auto>(SET THREE_LETTER_LANG=ENU ) \r\n\r\nC:\\Users\\_ft_auto>IF ENU == ENU (SET LOCALE_STRING= )  ELSE IF ENU == ESN (SET LOCALE_STRING=PRODUCT_LOCALE=ESP )  ELSE (SET LOCALE_STRING=PRODUCT_LOCALE=ENU ) \r\n\r\nC:\\Users\\_ft_auto>ECHO #### \r\n####\r\n\r\nC:\\Users\\_ft_auto>pushd C:\\Windows\\Installer \r\n\r\nC:\\Windows\\Installer>cmd /c bash -c "rm -rf MSI*.tmp*" \r\n\r\nC:\\Windows\\Installer>popd\r\n\r\nC:\\Users\\_ft_auto>pushd \\\\mydanas01.swinfra.net\\products\\FT\\QTP\\win32_release \r\n\r\nZ:\\FT\\QTP\\win32_release>SET OS_ARCH=x64 \r\n\r\nZ:\\FT\\QTP\\win32_release>IF not defined ProgramFiles(x86) SET OS_ARCH=x86 \r\n\r\nZ:\\FT\\QTP\\win32_release>SET msi_path="Z:\\FT\\QTP\\win32_release\\2021.1.0.869\\DVD\\Unified Functional Testing\\MSI\\Unified_Functional_Testing_x64.msi" \r\n\r\nZ:\\FT\\QTP\\win32_release>IF EXIST "Z:\\FT\\QTP\\win32_release\\2021.1.0.869\\DVD\\UFT One\\MSI\\x64.msi" (SET msi_path="Z:\\FT\\QTP\\win32_release\\2021.1.0.869\\DVD\\UFT One\\MSI\\UFT_One_x64.msi" ) \r\n\r\nZ:\\FT\\QTP\\win32_release>echo msi_path="Z:\\FT\\QTP\\win32_release\\2021.1.0.869\\DVD\\Unified Functional Testing\\MSI\\Unified_Functional_Testing_x64.msi" \r\nmsi_path="Z:\\FT\\QTP\\win32_release\\2021.1.0.869\\DVD\\Unified Functional Testing\\MSI\\Unified_Functional_Testing_x64.msi"\r\n\r\nZ:\\FT\\QTP\\win32_release>IF "" == "" (\r\necho installing UFT  \r\n cmd /c MsiExec /norestart /qn /i "Z:\\FT\\QTP\\win32_release\\2021.1.0.869\\DVD\\Unified Functional Testing\\MSI\\Unified_Functional_Testing_x64.msi" /l*xv C:\\UFT_Install_Log.txt ADDLOCAL=Core_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in,AIServices,PDF_Add_in,Abbyy_OCR LICSVR=mama.swinfra.net LICID=23078 CONF_MSIE=1 ALLOW_RUN_FROM_ALM=1 ALLOW_RUN_FROM_SCRIPTS=1 DLWN_SCRIPT_DBGR=1  \r\n)  ELSE (\r\necho installing UFT and LFT as a feature\t  \r\n cmd /c MsiExec /norestart /qn /i "Z:\\FT\\QTP\\win32_release\\2021.1.0.869\\DVD\\Unified Functional Testing\\MSI\\Unified_Functional_Testing_x64.msi" /l*xv C:\\UFT_Install_Log.txt ADDLOCAL=Core_Components,Web_Add_in,ALM_Plugin,IDE,Test_Results_Viewer,Samples,ActiveX_Add_in,Visual_Basic_Add_in,Delphi_Add_in,Flex_Add_in,Java_Add_in,_Net_Add_in,Oracle_Add_in,PeopleSoft_Add_in,PowerBuilder_Add_in,Qt_Add_in,SAP_Solutions_Add_in,SAP_eCATT_integration,Siebel_Add_in,Stingray_Add_in,TE_Add_in,VisualAge_Add_in,AIServices,PDF_Add_in,Abbyy_OCR,LeanFT,LeanFT_Engine,LeanFT_Client,Vs2012Addin,Vs2013Addin,IntelliJAddin,EclipseAddin ECLIPSE_INSTALLDIR="C:\\DevTools\\eclipse" LICSVR=mama.swinfra.net CONF_MSIE=1 ALLOW_RUN_FROM_ALM=1 ALLOW_RUN_FROM_SCRIPTS=1 DLWN_SCRIPT_DBGR=1 \t \r\n) \r\ninstalling UFT\r\nA\x00n\x00o\x00t\x00h\x00e\x00r\x00 \x00p\x00r\x00o\x00g\x00r\x00a\x00m\x00 \x00i\x00s\x00 \x00b\x00e\x00i\x00n\x00g\x00 \x00i\x00n\x00s\x00t\x00a\x00l\x00l\x00e\x00d\x00.\x00 \x00P\x00l\x00e\x00a\x00s\x00e\x00 \x00w\x00a\x00i\x00t\x00 \x00u\x00n\x00t\x00i\x00l\x00 \x00t\x00h\x00a\x00t\x00 \x00i\x00n\x00s\x00t\x00a\x00l\x00l\x00a\x00t\x00i\x00o\x00n\x00 \x00i\x00s\x00 \x00c\x00o\x00m\x00p\x00l\x00e\x00t\x00e\x00,\x00 \x00a\x00n\x00d\x00 \x00t\x00h\x00e\x00n\x00 \x00t\x00r\x00y\x00 \x00i\x00n\x00s\x00t\x00a\x00l\x00l\x00i\x00n\x00g\x00 \x00t\x00h\x00i\x00s\x00 \x00s\x00o\x00f\x00t\x00w\x00a\x00r\x00e\x00 \x00a\x00g\x00a\x00i\x00n\x00.\x00\n\x00\r\x00\r\nZ:\\FT\\QTP\\win32_release>popd\r\n\r\nC:\\Users\\_ft_auto>if 1618 EQU 3010 goto RESTART \r\n\r\nC:\\Users\\_ft_auto>goto CheckOS \r\n\r\nC:\\Users\\_ft_auto>IF EXIST "C:\\Program Files (x86)" (GOTO 64BIT )  ELSE (GOTO 32BIT ) \r\n\r\nC:\\Users\\_ft_auto>IF EXIST "C:\\Program Files (x86)\\Micro Focus\\UFT One\\bin\\UFT.exe" GOTO SUCCESS \r\n\r\nC:\\Users\\_ft_auto>IF EXIST "C:\\Program Files (x86)\\Micro Focus\\Unified Functional Testing\\bin\\UFT.exe" GOTO SUCCESS \r\n\r\nC:\\Users\\_ft_auto>IF EXIST "C:\\Program Files (x86)\\HPE\\Unified Functional Testing\\bin\\UFT.exe" GOTO SUCCESS \r\n\r\nC:\\Users\\_ft_auto>IF EXIST "C:\\Program Files (x86)\\HP\\Unified Functional Testing\\bin\\UFT.exe" GOTO SUCCESS \r\n\r\nC:\\Users\\_ft_auto>type c:\\UFT_Install_Log.txt   | findstr /C:"completed successfully" 1>nul \r\n\r\nC:\\Users\\_ft_auto>if NOT "1" == "0" (GOTO ERRINSTALL )  ELSE (GOTO END ) \r\n\r\nC:\\Users\\_ft_auto>echo "Unified Functional Testing -- Installation Failed!" \r\n"Unified Functional Testing -- Installation Failed!"\r\n\r\nC:\\Users\\_ft_auto>exit 1 \r\n'.decode("utf-8"))