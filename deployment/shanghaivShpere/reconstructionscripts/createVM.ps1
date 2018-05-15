
[CmdletBinding(SupportsShouldProcess=$True)]
param (
	[Parameter(Mandatory=$true)]
    [string]$MachineName,
    [Parameter(Mandatory=$true)]
    [string]$TemplateName
    
)

#Add-PSSnapin "VMware.VimAutomation.Core"

#Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false
Get-Module -ListAvailable | Where-Object { $_.Name -Like "VMware.VimAutomation*" } |  Import-Module



#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false


$vCenterAcc = $env:vCenterAccount
$vCenterPwd = $env:vCenterPassword

if (-Not $vCenterAcc -Or -Not $vCenterPwd) {
    Write-Host "Can't find vCenter Account or Password or Server Address Environment Variables"
    exit 1
}

class CreateVSphereMachine {

    hidden [string]$vCenterSvr
    hidden [VMware.VimAutomation.Types.VIServer]$VIServer = $null

    static [CreateVSphereMachine] $instance
    static [CreateVSphereMachine] GetInstance() {
        if ([CreateVSphereMachine]::instance -eq $null) { 
            [CreateVSphereMachine]::instance = [CreateVSphereMachine]::new() 
            [CreateVSphereMachine]::instance.ConnectVIServer()
        }
        return [CreateVSphereMachine]::instance
    }

    [Boolean]ConnectVIServer(

    ) {
        if ( $null -eq $this.VIServer ) 
        {
            if (Test-Path 'env:vCenterServer')
            { 
                $this.vCenterSvr = $env:vCenterServer
            } 
            else 
            {
                $this.vCenterSvr = "selvc01.hpeswlab.net"
            }
            $this.VIServer = Connect-VIServer -Server $this.vCenterSvr -User $env:vCenterAccount -Password $env:vCenterPassword
            if ( $null -eq $this.VIServer ) 
            {
                return $false
            } 
        }
        return $true
    }


    [Boolean]DoAction(
        [string]$MachineName,
        [string]$TempalteName
    ) {
        Write-Host "CreateVSphereMachine::DoAction Start" -ForegroundColor Green -BackgroundColor Black
        $dictVMInfo = $this.GetVMInfo($MachineName)
        if (-Not $this.DeleteVM($MachineName)) {
            return $false
        }
        $VMTemplate = Get-Template -Location HPSSEL -Name $TempalteName | Select-Object -First 1  
        if ( $null -eq $VMTemplate) {
            Write-Host "Can't get template ${TempalteName}" -ForegroundColor Red -BackgroundColor Black
            return $false
        }

        Write-Host "Create VM now ..." -ForegroundColor Green -BackgroundColor Black
        New-VM -Name $MachineName -Location $dictVMInfo.Folder -Template $VMTemplate -Datastore $dictVMInfo.DataStore -ResourcePool $dictVMInfo.Host
        Start-Sleep -s 10
        $this.WaitForMachinePowerOn($MachineName, $true)
        if (-Not $this.IsGuestToolRunning($MachineName)) {
            Write-Host "Guest tools is not running, because of it, can't rename VM and create snapshot" -ForegroundColor Red -BackgroundColor Black
            return $false
        }
        $this.RenameTheMachine($MachineName)
        $this.GreateSnapshot($MachineName)
        Write-Host "CreateVSphereMachine::DoAction End" -ForegroundColor Green -BackgroundColor Black
        return $true
    }

    [Void]RenameTheMachine(
        [string]$MachineName
    ) {
        Write-Host "CreateVSphereMachine::RenameTheMachine Start" -ForegroundColor Green -BackgroundColor Black
        Write-Host "CreateVSphereMachine::RenameTheMachine Renaming to ${MachineName}" -ForegroundColor Green -BackgroundColor Black
        $renamecomputer = "wmic path win32_computersystem where Name='%computername%' CALL rename name='$MachineName'"
        $VM = Get-VM -Name $MachineName | Select-Object -First 1
        $VMScriptResult = Invoke-VMScript -VM $VM -GuestUser appsadmin -GuestPassword appsadmin -ScriptType Bat -ScriptText $renamecomputer
        Write-Host "CreateVSphereMachine::RenameTheMachine the exit code of script $($VMScriptResult.ExitCode)" -ForegroundColor Green -BackgroundColor Black
        Write-Host "CreateVSphereMachine::RenameTheMachine the output of script $($VMScriptResult.ScriptOutput)" -ForegroundColor Green -BackgroundColor Black
        restart-vmguest -VM $VM -Confirm:$false
        $this.WaitForMachinePowerOn($MachineName, $false)
        Write-Host "CreateVSphereMachine::RenameTheMachine End" -ForegroundColor Green -BackgroundColor Black
    }

    [Boolean]GreateSnapshot(
        [string]$MachineName
    ) {
        
        Write-Host "CreateVSphereMachine::GreateSnapshot Start" -ForegroundColor Green -BackgroundColor Black
        $this.WaitForMachinePowerOff($MachineName, $true)
        $VM = Get-VM -Name $MachineName | Select-Object -First 1
        $snapshotName = "${MachineName}_Snapshot"
        $snapShots = New-Snapshot -VM $VM -Name $snapshotName
        start-sleep -s 20
        $snapShots = Get-Snapshot -VM $VM -Name $snapshotName
        if ($snapShots.Count -eq 0)
        {
            Write-Host "CreateVSphereMachine::GreateSnapshot Retrying" -ForegroundColor Green -BackgroundColor Black
            #retry 
            $snapShots = New-Snapshot -VM $VM -Name $snapshotName
            start-sleep -s 20
            $snapShots = Get-Snapshot -VM $VM -Name $snapshotName
            if ($snapShots.Count -eq 0)
            {   
                Write-Host "CreateVSphereMachine::GreateSnapshot Snapshot creation failed" -ForegroundColor Red -BackgroundColor Black
                #retry 
                return $false
            }
        }
        Write-Host "CreateVSphereMachine::GreateSnapshot End" -ForegroundColor Green -BackgroundColor Black
        return $true
    }

    [Boolean]IsGuestToolRunning(
        [string]$MachineName
    ) {
        Write-Host "CreateVSphereMachine::IsGuestToolRunning Start" -ForegroundColor Green -BackgroundColor Black
        $i=0
        $Toolsstatus=""
        Do {
            start-sleep -s 30
            $VM = Get-VM -Name $MachineName | Select-Object -First 1
            if ( $null -eq $VM) {
                return $false
            }
            $Toolsstatus = $VM.ExtensionData.Guest.ToolsRunningStatus
            Write-Host "CreateVSphereMachine::IsGuestToolRunning Waiting for $VM to start, tools status is $Toolsstatus" -ForegroundColor Green -BackgroundColor Black
            $i = $i + 1
        } # End of 'Do'
        Until ($Toolsstatus -eq "guestToolsRunning" -or $i -ge 10) 
        Write-Host "CreateVSphereMachine::IsGuestToolRunning End" -ForegroundColor Green -BackgroundColor Black
        return $Toolsstatus -eq "guestToolsRunning" 
    }

    [Void]WaitForMachinePowerOff(
        [string]$MachineName,
        [Boolean]$DoOperation
    ) {
        
        Write-Host "CreateVSphereMachine::WaitForMachinePowerOff Start" -ForegroundColor Green -BackgroundColor Black
        $VM = Get-VM -Name $MachineName | Select-Object -First 1
        if ( $null -eq $VM) {
            return
        }
        $PowerState = $VM.PowerState
        Write-Host "CreateVSphereMachine::WaitForMachinePowerOff the power state of ${MachineName} ${PowerState}" -ForegroundColor Green -BackgroundColor Black
            
        if ($PowerState -eq "PoweredOn" -And $DoOperation)
        {
            Write-Host "CreateVSphereMachine::WaitForMachinePowerOff power off the machine ${MachineName}" -ForegroundColor Green -BackgroundColor Black
            Stop-VMGuest -VM $VM -Confirm:$false 
        }
    
        $i=0
        Do {
            start-sleep -s 30
            $VM = Get-VM -Name $MachineName | Select-Object -First 1
            $PowerState = $VM.PowerState
            Write-Host "CreateVSphereMachine::WaitForMachinePowerOff the power state of ${MachineName} ${PowerState}" -ForegroundColor Green -BackgroundColor Black
            $i = $i + 1
        } # End of 'Do'
        Until (($PowerState -eq "PoweredOff") -or $i -ge 10) 
        Write-Host "CreateVSphereMachine::WaitForMachinePowerOff End" -ForegroundColor Green -BackgroundColor Black
    }



    [Void]WaitForMachinePowerOn(
        [string]$MachineName,
        [Boolean]$DoOperation
    ) {
        
        Write-Host "CreateVSphereMachine::WaitForMachinePowerOn Start" -ForegroundColor Green -BackgroundColor Black
        $VM = Get-VM -Name $MachineName
        if ( $null -eq $VM) {
            return
        }
        $PowerState = $VM.PowerState
        Write-Host "CreateVSphereMachine::WaitForMachinePowerOn the power state of ${MachineName} ${PowerState}" -ForegroundColor Green -BackgroundColor Black
            
        if ($PowerState -eq "PoweredOff" -And $DoOperation)
        {
            Write-Host "CreateVSphereMachine::WaitForMachinePowerOn power on the machine ${MachineName}" -ForegroundColor Green -BackgroundColor Black
            Start-VM -VM $VM -Confirm:$false | Select-Object -Property PowerState, Guest | Format-Table
        }
    
        $IPv4=""
        $i=0
        Do {
            start-sleep -s 30
            $VMs = Get-VM -Name $MachineName
            $VM = $VMs[0]
            $IPv4 = $VM.Guest.IPAddress | Where-Object {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}
            $PowerState = $VM.PowerState
            Write-Host "CreateVSphereMachine::WaitForMachinePowerOn the power state of ${MachineName} ${PowerState}" -ForegroundColor Green -BackgroundColor Black
            Write-Host "CreateVSphereMachine::WaitForMachinePowerOn the IP Address of ${MachineName} ${IPv4}" -ForegroundColor Green -BackgroundColor Black
            $i = $i + 1
            
        } # End of 'Do'
        Until (($IPv4 -and $IPv4 -ne "" -and $PowerState -eq "PoweredOn") -or $i -ge 10) 
        Write-Host "CreateVSphereMachine::WaitForMachinePowerOn End" -ForegroundColor Green -BackgroundColor Black
    }

    [Boolean]TestVM (
        [string]$MachineName
    ) {
        $VMs = Get-VM -Name $MachineName
        return $($VMs -And $VMs.Count -gt 0)
    }

    [System.Collections.Hashtable]GetVMInfo(
        [string]$MachineName
    ) {
        Write-Host "CreateVSphereMachine::GetVMInfo Start" -ForegroundColor Green -BackgroundColor Black
        $dict = @{}
        $Exists = $this.TestVM($MachineName)
        $VMDataStore = $null
        $VMHost = $null
        $VMFolder = $null
        if ($Exists) {
            $VM = Get-VM -Name $MachineName | Select-Object -First 1 
            $VMFolder = $VM.Folder
            $VMDataStore = Get-DataStore -RelatedObject $VM | Select-Object -First 1 #-ExpandProperty ID
            #$VMDataStoreID = Get-DataStore -Name $vCenterDataStore | Select-Object -First 1 -ExpandProperty ID
            Write-Host "DataStore ID = $($VMDataStore.Id) " -ForegroundColor Green -BackgroundColor Black
            $VMHost = Get-VMHost -VM $VM | Select-Object -First 1
            Write-Host "Host ID = $($VMHost.Id)" -ForegroundColor Green -BackgroundColor Black
        } else {
            $vCenterHost = ""
            $vCenterDataStore = ""
            $vCenterFolder = ""
            if (Test-Path 'env:vCenterHost')
            { 
                $vCenterHost = $env:vCenterHost
            } 
            else 
            {
                $vCenterHost = "shc-gsts-esx03.hpeswlab.net"
            }

            if (Test-Path 'env:vCenterDataStore')
            { 
                $vCenterDataStore = $env:vCenterDataStore
            } 
            else 
            {
                $vCenterDataStore = "SHCADMLUN03"
            }

            if (Test-Path 'env:vCenterFolder')
            { 
                $vCenterFolder = $env:vCenterServer
            } 
            else 
            {
                $vCenterFolder = "DEVOPS"
            }
            $VMFolder = Get-Folder -Name $vCenterFolder | Select-Object -First 1
            $VMDataStore = Get-DataStore -Name $vCenterDataStore | Select-Object -First 1
            $VMHost = Get-VMHost -Name $vCenterHost | Select-Object -First 1
            Write-Host "DataStore ID = $($VMDataStore.Id) " -ForegroundColor Green -BackgroundColor Black
            Write-Host "Host ID = $($VMHost.Id)" -ForegroundColor Green -BackgroundColor Black
        }
        
        $dict.DataStore=$VMDataStore
        $dict.Host=$VMHost
        $dict.Folder=$VMFolder
        Write-Host "CreateVSphereMachine::GetVMInfo End" -ForegroundColor Green -BackgroundColor Black
        return $dict
    }

    [Boolean]DeleteVM(
        [string]$MachineName
    ) {
        Write-Host "CreateVSphereMachine::DeleteVM Start" -ForegroundColor Green -BackgroundColor Black
        $VM = Get-VM -Name $MachineName | Select-Object -First 1
        if ( $null -eq $VM ) {
            return $true
        }
        $this.WaitForMachinePowerOff($MachineName, $true)
        Get-VM -Name $MachineName | Remove-VM -DeletePermanently -Confirm:$false
        Write-Host "Remove $MachineName now ..." -ForegroundColor Green -BackgroundColor Black
        $retry = 3
        $Exists = $true
        DO 
        {  
            $retry--
            start-sleep -s 60     
            $Exists = $this.TestVM($MachineName)
        } until (($retry -le 0) -Or (-Not $Exists))
        Write-Host "CreateVSphereMachine::DeleteVM End ${Exists}" -ForegroundColor Green -BackgroundColor Black
        return -Not $Exists
    }

    [Void]DisConnectVIServer(

    ) {
        if ( $null -ne $this.vCenterSvr ) {
            Disconnect-VIServer -Server $this.vCenterSvr -Confirm:$false 
        }
    }
} 

$vCenterAcc = $env:vCenterAccount
$vCenterPwd = $env:vCenterPassword

if (-Not $vCenterAcc -Or -Not $vCenterPwd) {
    Write-Host "Can't find vCenter Account or Password or Server Address Environment Variables"
    exit 1
}

$createVSphereMachine=[CreateVSphereMachine]::GetInstance()
$result = $createVSphereMachine.DoAction($MachineName, $TemplateName)
if ($result)
{
    exit 0
} else {
    exit 1
}


