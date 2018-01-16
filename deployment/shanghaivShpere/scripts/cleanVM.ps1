
[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$true)]
    [string]$vmName = $null,
    [string]$OutputDir = $null
)
Add-PSSnapin "VMware.VimAutomation.Core"
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false
#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
$vCenterAcc = $env:vCenterAccount
$vCenterPwd = $env:vCenterPassword
if (-Not $vCenterAcc -And -Not $vCenterPwd)
{
    Write-Host "Can't find vCenter Account and Password Environment Variables"
    exit 1
}


$ShangHaiVM = Connect-VIServer selvc01.hpeswlab.net -user $vCenterAcc.Value -Password $vCenterPwd.Value
try {
    
    $VMs = Get-VM -Name $vmName
    if ($null -eq $VMs) {
        write-host "there is no such VM " + $vmName
    }
    $VM = $VMs[0]
    $snapshotName = $vmName + "_Snapshot"
    $snapshot = Get-Snapshot -VM $VM -Name $snapshotName
    Set-VM -VM $VM -Snapshot $snapshot -Confirm:$false
    $ParamFile = $vmName + "_parm.txt"
    start-sleep -s 60

    $VMs = Get-VM -Name $vmName
    $VM = $VMs[0]
    $PowerState = $VM.PowerState
    write-host "$PowerState"
        
    if ($PowerState -eq "PoweredOff")
    {
        write-host "Power On $VM"
        Start-VM -VM $VM -Confirm:$false 
        start-sleep -s 120
    }
    
    $VMs = Get-VM -Name $vmName
	if ($null -eq $VMs) {
        write-host "there is no such VM " + $vmName
    }
    $VM = $VMs[0]
    $PowerState = $VM.PowerState
    write-host "$PowerState"

    if ($PowerState -eq "PoweredOff")
    {
        start-sleep -s 180
    }
	$IPv4 = $VM.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}
    write-host $IPv4
	
    Test-Connection -ComputerName $IPv4 -Count 3
    #$VMGuest = Get-VMGuest -VM $VM
    #write-host $VMGuest.IPAddress
    write-host $IPv4
    $Param = "VM_IP=" + $IPv4
    $CurrentDir = (Get-Location).Path
    $ParamFile = $CurrentDir + "\" + $ParamFile
    write-host $ParamFile
    $Param | Out-File -FilePath $ParamFile -Encoding "ASCII"
    $exitCode = 0
    
}
catch [Exception]{
    write-host $_.Exception.Message
    $exitCode = 1
}
finally {
    Disconnect-VIServer -Server $ShangHaiVM -Confirm:$false
    exit $exitCode
}





