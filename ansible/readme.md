# Ansible 

## How to add slave machine
Adding slave machines are effortless, You can follow the instructions as described below 
* **Windows** 

    Ansible communicates with windows slave using [Winrm](https://docs.microsoft.com/en-us/windows/win32/winrm/portal). Make sure winrm is enabled in the slave machine. To enable WinRM, Download and run the [winRM.ps1](https://github.houston.softwaregrp.net/uft/uft.devops/blob/master/ansible/winRM.ps1) power shell in the administrator privilege.

    Run the script with '-Verbose -EnableCredSSP' parameter to enable [CredSSP](https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html#credssp).

## upgrade_cli playbook
This job upgrade Aujas CLI to target machines

* **Dependencies**
    1. Download latest Aujas CLI from Aujas portal
    2. Extract **\\10.199.156.19\products\FT\UFT_Tools\CodeSign\Aujas\win_cli_latest.zip** and replace new CLI contents. (do not delete other folders as used by the signing process)
    3. zip the contents with the same name (**win_cli_latest.zip**)

* **How to run playbook**
    1. Trigger a [Jenkins job](http://mydtbld0211.swinfra.net:8080/view/Products/view/Self%20Services/job/Upgrade_Aujas_Cli/)
    2. Validate **D:\UFT_Tools\CodeSign\AUJAS\win_cli_latest** folder exist with correct cli