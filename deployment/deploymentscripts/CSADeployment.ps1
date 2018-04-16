
#using module ".\CSADeployment.psm1"
[CmdletBinding(SupportsShouldProcess=$True)]
param (
	[Parameter(Mandatory=$true)]
    [string]$CSAName = "",
    [Parameter(Mandatory=$true)]
    [string]$BuidlVersion = "",
    [string]$CleanMode = "uninstall",
    [string]$SUBSCRIPTION_ID = ""
)

Import-Module -Force ".\CSADeployment.psm1"

#$txtuser=$env:CSAAccount
#$txtpwd=$env:CSAPassword

$env:CSAAccount="swinfra.net\guoyibi"
$env:CSAPassword="!Qasdfghjkl;`'"

#$env:CSAAccount="hpeswlab.net\alm_uft_auto"
#$env:CSAPassword="W3lcome1"

# switch($CleanMode) 
# {
#     "resnapshot" {break}
#     "uninstall" {
#         $csaDeployment = [CSAMachineDeployUninstall]::new($CSAName,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
#         $csaDeployment.DeployWithBuildVersion($BuidlVersion)
#         break
#     }
#     default {
#         $csaDeployment = [CSAMachineDeployUninstall]::new($CSAName,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
#         $csaDeployment.DeployWithBuildVersion($BuidlVersion)
#         break
#     }
# }


Install-Application -CSAName $CSAName -BuidlVersion $BuidlVersion -CleanMode $CleanMode -SUBSCRIPTION_ID $SUBSCRIPTION_ID


