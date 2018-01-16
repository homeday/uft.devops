
[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$true)]
    [string]$vmName = $null,
    [string]$InstallBatch = $null,
    [string]$BuildVersion = $null,
    [string]$LicenseServer = $null,
    [string]$RemoveServer = $null
)
Add-PSSnapin "VMware.VimAutomation.Core"
$vCenterAcc = Get-Childitem ENV:vCenterAccount
$vCenterPwd = Get-Childitem ENV:vCenterPassword

if (-Not $vCenterAcc -And -Not $vCenterPwd)
{
    Write-Host "Can't find vCenter Account and Password Environment Variables"
    Disconnect-VIServer -Server $ShangHaiVM -Confirm:$false
    exit 1
}

Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false
#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
$ShangHaiVM = Connect-VIServer selvc.HPESWLAB.NET -user $vCenterAcc.Value -Password $vCenterPwd.Value
try {
    $VM = Get-VM -Name $vmName | Select-Object -First 1

    $InstallUFT = $InstallBatch + " " + $BuildVersion + " " + $LicenseServer + " " + $RemoveServer
    Invoke-VMScript -VM $VM -GuestUser WORKGROUP\appsadmin -GuestPassword appsadmin -ScriptType Bat -ScriptText $InstallUFT
   
    
}
catch [Exception]{
    write-host $_.Exception.Message
    $exitCode = 1
}
finally {
    Disconnect-VIServer -Server $ShangHaiVM -Confirm:$false
    exit $exitCode
}





