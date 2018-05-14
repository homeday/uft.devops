[CmdletBinding(SupportsShouldProcess=$True)]
param (
	[Parameter(Mandatory=$true)]
    [string]$MachineName,
    [Parameter(Mandatory=$true)]
    [string]$BuidlVersion,
    [Parameter(Mandatory=$true)]
    [string]$Application = "uft",
    [string]$CleanMode = "resnapshot",
    [string]$GAVersion = "",
    [string]$PatchID = ""
    
)


$env:VM_USER = "appsadmin"
$env:VM_PASSWORD = "appsadmin"
$env:vCenterAccount = "ASIAPACIFIC\guoyibi"
$env:vCenterPassword = "`$rfv5tgb6yhn"
$env:vCenterServer = "selvc01.hpeswlab.net"

Import-Module -Force ".\vSphereDeployment.psm1"

Write-Host "Install ${BuidlVersion} ${Application} at machine ${MachineName} with ${CleanMode} mode Start" -ForegroundColor Green -BackgroundColor Black
$result = Install-Application -MachineName $MachineName `
            -BuidlVersion $BuidlVersion `
            -CleanMode $CleanMode `
            -Application $Application `
            -GAVersion $GAVersion -PatchID $PatchID
if ($result -eq $true) {
    Write-Host "It is successful to install ${BuidlVersion} at machine ${MachineName} with ${CleanMode} mode " -ForegroundColor Green -BackgroundColor Black
    exit 0
}
Write-Host "It is failed to install ${BuidlVersion} at machine ${MachineName} with ${CleanMode} mode " -ForegroundColor Red -BackgroundColor Black
exit 1
