
using module ".\CSADeployment.psm1"
[CmdletBinding(SupportsShouldProcess=$True)]
param (
	[Parameter(Mandatory=$true)]
    [string]$VM_NAME = "",
    [Parameter(Mandatory=$true)]
    [string]$BUILD_NUMBER = "",
    [string]$CLEAN_MODE = "uninstall",
    [string]$SUBSCRIPTION_ID = ""
)

$txtuser=$env:CSAAccount
$txtpwd=$env:CSAPassword

switch($CLEAN_MODE) 
{
    "resnapshot" {break}
    "uninstall" {}
    default {
        $csaDeployment = [CSAMachineDeployUninstall]::new($VM_NAME,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
        $csaDeployment.DeployWithBuildVersion($BUILD_NUMBER)
        break
    }
}


