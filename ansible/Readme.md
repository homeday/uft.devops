# Ansible 

## upgrade_cli playbook
This job upgrade Aujas cli to traget machines

* **Dependencies**
    1. Download latest Aujas CLI from Aujas portal
    2. Extract **\\10.199.156.19\products\FT\UFT_Tools\CodeSign\Aujas\win_cli_latest.zip** and replace new CLI contents. (do not delete other folders as it used by signing process)
    3. zip the contents with the same name (**win_cli_latest.zip**)

* **How to run playbook**
    1. Trigger a [Jenkins job](http://mydtbld0211.swinfra.net:8080/view/Products/view/Self%20Services/job/Upgrade_Aujas_Cli/)
    2. Validate **D:\UFT_Tools\CodeSign\AUJAS\win_cli_latest** folder exist with correct cli
