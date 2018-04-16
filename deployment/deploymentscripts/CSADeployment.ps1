
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

Install-Application -CSAName $CSAName -BuidlVersion $BuidlVersion -CleanMode $CleanMode -SUBSCRIPTION_ID $SUBSCRIPTION_ID


