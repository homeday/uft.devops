
using module ".\CSADeployment.psm1"
[CmdletBinding(SupportsShouldProcess=$True)]
param (
	[Parameter(Mandatory=$true)]
    [string]$CSAName = "",
    [Parameter(Mandatory=$true)]
    [string]$BuidlVersion = "",
    [string]$CleanMode = "uninstall",
    [string]$SUBSCRIPTION_ID = ""
)

$txtuser=$env:CSAAccount
$txtpwd=$env:CSAPassword

switch($CleanMode) 
{
    "resnapshot" {break}
    "uninstall" {}
    default {
        $csaDeployment = [CSAMachineDeployUninstall]::new($CSAName,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
        $csaDeployment.DeployWithBuildVersion($BuidlVersion)
        break
    }
}


