
[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$true)]
    [string]$vmName = $null,
    [string]$vmTemplateName = $null
   
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
$ShangHaiVM = Connect-VIServer selvc01.hpeswlab.net -user $vCenterAcc.Value -Password $vCenterPwd.Value


$VMs = Get-VM -Name $vmName
$VMDataStore = $null
$VMHost = $null
if ($VMs -And $VMs.Count -gt 0 )
{
    $VM = Get-VM -Name $vmName | Select-Object -First 1 
    #hard code datastore name now  SHCADMLUN03
    #$VMDataStoreID = Get-DataStore -RelatedObject $VM | Select-Object -First 1 -ExpandProperty ID
    $VMDataStoreID = Get-DataStore -Name SHCADMLUN03 | Select-Object -First 1 -ExpandProperty ID
    Write-Host "DataStore ID = $VMDataStoreID "

    $VMHostID = Get-VMHost -VM $VM | Select-Object Select-Object -First 1 -ExpandProperty ID
    Write-Host "Host ID = $VMHostID"

    Stop-VM -VM $VM -Confirm:$false
      
    do {
        $VM = Get-VM -Name $vmName | Select-Object -First 1
        $Toolsstatus = $VM.ExtensionData.Guest.ToolsRunningStatus
        Write-Host "Waiting for $VM to be poweroff, tools status is $Toolsstatus"
        Sleep 7
    } until ($Toolsstatus -eq "guestToolsNotRunning")
    start-sleep -s 10
    $VM = Get-VM -Name $vmName | Select-Object -First 1

    Write-Host "Remove $VM now ..."

    $retry = 3
    DO 
    {  
        $retry--
        $VMs = Get-VM -Name $vmName  
        Remove-VM $VMs -DeletePermanently -Confirm:$false
        start-sleep -s 60     
        $VMs = Get-VM -Name $vmName     
        if ($VMs.Count -le 0)
        {
            Write-Host "Remove VM successfully"
            break    
        }
    } until ($retry -le 0)
    
    $VMs = Get-VM -Name $vmName  
    if ($VMs.Count -gt 0)
    {
        Write-Host "VM remove failed"
        Disconnect-VIServer -Server $ShangHaiVM -Confirm:$false
        exit 1
    }
    $VMDataStore = Get-DataStore -ID $VMDataStoreID
    #$VMHost = Get-VMHost -ID $VMHostID
	$VMHost = Get-VMHost -Name shc-gsts-esx03.hpeswlab.net
    #$VMDataStore
    #$VMHost

} else {
    #hard code datastore name now  SHCADMLUN03
    #$VMDataStore = Get-DataStore | Sort-Object -property FreeSpaceGB -descending | Select-Object -First 1
    $VMDataStore = Get-DataStore -Name SHCADMLUN03
    $VMHost = Get-VMHost -Name shc-gsts-esx03.hpeswlab.net #| Sort-Object -property MemoryUsageGB | Select -First 1
    #$VMDataStore
    #$VMHost
}


$VMTemplate = Get-Template -Location HPSSEL -Name $vmTemplateName | Select-Object -First 1  
$VMFolder = Get-Folder -Location HPSSEL -Name "DEVOPS" | Select-Object -First 1  
#$VMSpec = Get-OSCustomizationSpec -Name "UFTDEVSPEC" |  Select-Object -First 1 

Write-Host "Host : $VMHost"
Write-Host "Template : $VMTemplate"
Write-Host "Folder : $VMFolder"
Write-Host "Datastore : $VMDataStore"

Write-Host "Create VM now ..."
$VM = New-VM -Name $vmName -Location $VMFolder -Template $VMTemplate -Datastore $VMDataStore -ResourcePool $VMHost

start-sleep -s 10

#Set-VM -VM $VM -MemoryGB 8 -NumCPU 2

Write-Host "Power on the $VM now ..."
Start-VM -VM $VM -Confirm:$false

start-sleep -s 10

$VM = Get-VM -Name $vmName | Select-Object -First 1  

$PowerState = $VM.PowerState
write-host "$PowerState"
#do {
#    $VM = Get-VM -Name $vmName | Select-Object -First 1
#    $Toolsstatus = $VM.ExtensionData.Guest.ToolsRunningStatus
#    Write-Host "Waiting for $VM to start, tools status is $Toolsstatus"
#    Sleep 7
#} until ($Toolsstatus -eq "guestToolsRunning")
start-sleep -s 180
$VM = Get-VM -Name $vmName | Select-Object -First 1  
$PowerState = $VM.PowerState
write-host "2nd time - $PowerState"
if ($PowerState -eq "PoweredOff")
{
    start-sleep -s 180
}

$VM = Get-VM -Name $vmName | Select-Object -First 1  
$PowerState = $VM.PowerState
if ($PowerState -eq "PoweredOff")
{
    Start-VM -VM $VM -Confirm:$false
    start-sleep -s 180
}

for($i=1; $i -le 10; $i++){

    $VM = Get-VM -Name $vmName | Select-Object -First 1
    $Toolsstatus = $VM.ExtensionData.Guest.ToolsRunningStatus
    Write-Host "Waiting for $VM to start, tools status is $Toolsstatus"
    if ($Toolsstatus -eq "guestToolsRunning")
    {
        break
    }
    Sleep 6
}

$VM = Get-VM -Name $vmName | Select-Object -First 1
$Toolsstatus = $VM.ExtensionData.Guest.ToolsRunningStatus
if ($Toolsstatus -eq "guestToolsNotRunning")
{
    Disconnect-VIServer -Server $ShangHaiVM -Confirm:$false
    Write-Host "Guest tools is not running, because of it, can't rename VM and create snapshot"
    exit 2
}

Write-Host "renaming"
$renamecomputer = "wmic path win32_computersystem where Name='%computername%' CALL rename name='$vmName'"
Invoke-VMScript -VM $VM -GuestUser appsadmin -GuestPassword appsadmin -ScriptType Bat -ScriptText $renamecomputer
restart-vmguest -VM $VM -Confirm:$false

start-sleep -s 180
$VM = Get-VM -Name $vmName | Select-Object -First 1  
if ($PowerState -eq "PoweredOff")
{
    start-sleep -s 180
}

$VMs = Get-VM -Name $vmName
if ($VMs.Count -eq 0)
{
    Write-Host "VM Creation failed"
    exit 3    
}

Write-Host "Create snapshot now ..."
$snapshotName = $VM.Name + "_Snapshot"
$snapShots = New-Snapshot -VM $VM -Name $snapshotName
start-sleep -s 10
$snapShots = Get-Snapshot -VM $VM -Name $snapshotName
if ($VMs.Count -eq 0)
{
    #retry 
    $snapShots = New-Snapshot -VM $VM -Name $snapshotName
    start-sleep -s 10
    $snapShots = Get-Snapshot -VM $VM -Name $snapshotName
    if ($VMs.Count -eq 0)
    {   
        Write-Host "VM Snapshot creation failed"
        exit 4
    }
}
Disconnect-VIServer -Server $ShangHaiVM -Confirm:$false
exit 0