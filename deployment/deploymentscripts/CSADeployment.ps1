
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

Write-Host "Install ${BuidlVersion} at machine ${CSAName} with ${CleanMode} mode Start" -ForegroundColor Green -BackgroundColor Black
$result = Install-Application -CSAName $CSAName -BuidlVersion $BuidlVersion -CleanMode $CleanMode -SUBSCRIPTION_ID $SUBSCRIPTION_ID
if ($result -eq $true) {
    Write-Host "It is successful to install ${BuidlVersion} at machine ${CSAName} with ${CleanMode} mode " -ForegroundColor Green -BackgroundColor Black
    exit 0
}
Write-Host "It is failed to install ${BuidlVersion} at machine ${CSAName} with ${CleanMode} mode " -ForegroundColor Red -BackgroundColor Black
exit 1

