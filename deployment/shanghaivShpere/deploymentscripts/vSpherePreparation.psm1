using namespace System.Management.Automation

class VSpherePreparation {
    VSpherePreparation() {
        Write-Host "VSpherePreparation::constructor" -ForegroundColor Green -BackgroundColor Black
    }


    [Void] doAction(
        [string]$MachineName,
        [string]$UserName,
        [string]$Password,
        [PSCredential]$MachineCredential
    ) {
        Write-Host "VSpherePreparation::doAction Start" -ForegroundColor Green -BackgroundColor Black
        $type = $this.GetType()
        if ($this.GetType() -eq [VSpherePreparation])
        {
            throw("Class $type must be inherited")
        }
        if (Test-Path 'env:VM_DOMAIN')
        { 
            $MachineName = "${MachineName}.${env:VM_DOMAIN}"
        }
        #$PSExecExpression = {C:\tools\PSTools\PsExec.exe \\$MachineName -u $UserName -p $Password powershell.exe "enable-psremoting -force"}
        #$ExpressionResult = Invoke-Command -ScriptBlock $PSExecExpression
        #Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        $this.WaitWinRM($MachineName, $MachineCredential)
        $this.CopyRelatedFiles($MachineName, $MachineCredential)
        Write-Host "To delete useless files at remote machine" -ForegroundColor Green -BackgroundColor Black
        $ExpressionResult = Invoke-Command -Credential $MachineCredential -ComputerName $MachineName -ScriptBlock `
        { `
            CMD.exe /C C:\del.bat `
        } 
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        Write-Host "VSpherePreparation::doAction End" -ForegroundColor Green -BackgroundColor Black
    }

    [Void]WaitWinRM(
        [string]$MachineName,
        [System.Management.Automation.PSCredential]$MachMachineCredential
    ) {
        $iloop=0
        $WinRmSvr = $null
        do {
            if ($iloop -ne 0) {
                Start-Sleep 30
            }
            $WinRmSvr = Invoke-Command -Credential $MachMachineCredential  -ComputerName $MachineName -ScriptBlock {Get-Service -Name winrm}
            Write-Host "CSAInstallApp::WaitWinRM Get winrm service result" -ForegroundColor Green -BackgroundColor Black
            Write-Host $WinRmSvr -ForegroundColor Green -BackgroundColor Black
            $iloop = $iloop + 1
        } until (($null-ne $WinRmSvr -and $WinRmSvr[0].Status -eq "Running") -or $iloop -gt 3)
        if ($null -eq $WinRmSvr) {
            throw("WinRm Services must be started!")
        }
    }

    [Void]RestartMachine(
        [string]$MachineName,
        [System.Management.Automation.PSCredential]$MachMachineCredential
    ) {
        Write-Host "VSpherePreparation::RestartMachine Start" -ForegroundColor Green -BackgroundColor Black
        Restart-Computer -ComputerName $MachineName  -Credential $MachMachineCredential -Wait -Timeout 600 -Force
        Start-Sleep -s 15 
        Write-Host "VSpherePreparation::RestartMachine End" -ForegroundColor Green -BackgroundColor Black
    }

    [Void]CopyRelatedFiles(
        [string]$MachineName,
        [System.Management.Automation.PSCredential]$MachMachineCredential
    ) {
        Write-Host "VSpherePreparation::CopyRelatedFiles Start" -ForegroundColor Green -BackgroundColor Black
        $ConnSession = New-PSSession -ComputerName $MachineName -Credential $MachMachineCredential 
        Copy-Item "${PSScriptRoot}\del.bat" -Destination "C:\" -ToSession $ConnSession -Recurse
        Copy-Item "${PSScriptRoot}\deploySALFT.bat" -Destination "C:\" -ToSession $ConnSession -Recurse
        Copy-Item "${PSScriptRoot}\deployUFT.bat" -Destination "C:\" -ToSession $ConnSession -Recurse
        Copy-Item "${PSScriptRoot}\Windows6.1-KB2999226-x64.msu" -Destination "C:\" -ToSession $ConnSession -Recurse
        if ($null -ne $ConnSession) {
            Remove-PSSession -Session $ConnSession
        }
        Write-Host "VSpherePreparation::CopyRelatedFiles End" -ForegroundColor Green -BackgroundColor Black
    }
}



class VSphereRevertMachine : VSpherePreparation {
    VSphereRevertMachine (
    ) : base(
    ) {
        Write-Host "VSphereRevertMachine::constructor" -ForegroundColor Green -BackgroundColor Black
    }
   
    static [string] $vCenterAcc = $env:vCenterAccount
    static [string] $vCenterPwd = $env:vCenterPassword
    static [string] $vCenterSvr = $env:vCenterServer

    static [VSphereRevertMachine] $instance
    static [VSphereRevertMachine] GetInstance() {
        if ([VSphereRevertMachine]::instance -eq $null) { 
            [VSphereRevertMachine]::instance = [VSphereRevertMachine]::new() 
        }
        return [VSphereRevertMachine]::instance
    }

    [Void] doAction(
        [string]$MachineName,
        [string]$UserName,
        [string]$Password,
        [PSCredential]$MachineCredential
    ) {
        Write-Host "VSphereRevertMachine::doAction Start" -ForegroundColor Green -BackgroundColor Black
        $this.RevertSnapshot($MachineName)
        ([VSpherePreparation]$this).doAction($MachineName, $UserName,$Password, $MachineCredential)
        Write-Host "VSphereRevertMachine::doAction End" -ForegroundColor Green -BackgroundColor Black
    }

    [Boolean]RevertSnapshot(
        [string]$MachineName
    ) {
        Write-Host "VSphereRevertMachine::RevertSnapshot Start" -ForegroundColor Green -BackgroundColor Black
        [string[]] $Server = [VSphereRevertMachine]::vCenterSvr
		
		$output = Get-Module -Name VMware* -ListAvailable
		Write-Host "VSphereRevertMachine::RevertSnapshot "
		Write-Host  $output
		Write-Host "VSphereRevertMachine::RevertSnapshot 2"
		Get-Module -Name VMware* -ListAvailable | Import-Module
        $ShangHaiVM = Connect-VIServer -Server $Server -User "$([VSphereRevertMachine]::vCenterAcc)" -Password "$([VSphereRevertMachine]::vCenterPwd)"

        $VMs = Get-VM -Name $MachineName
        if ($null -eq $VMs) {
            Write-Host "VSphereRevertMachine::RevertSnapshot the machine ${MachineName} doesn't exists" -ForegroundColor Red -BackgroundColor Black
            Disconnect-VIServer -Server $ShangHaiVM -Confirm:$false
            return $false
        }

        $VM = $VMs[0]
        $snapshotName = $MachineName + "_Snapshot"
        $snapshot = Get-Snapshot -VM $VM -Name $snapshotName
        Set-VM -VM $VM -Snapshot $snapshot -Confirm:$false | Select-Object -Property PowerState, Guest | Format-Table
        start-sleep -s 5
        $this.WaitForMachinePowerOn($MachineName)
        Disconnect-VIServer -Server $ShangHaiVM -Confirm:$false
        Write-Host "VSphereRevertMachine::RevertSnapshot End" -ForegroundColor Green -BackgroundColor Black
        return $true
      
    }

    [Void]WaitForMachinePowerOn(
        [string]$MachineName
    ) {
        
        Write-Host "VSphereRevertMachine::WaitForMachinePowerOn Start" -ForegroundColor Green -BackgroundColor Black
        $VMs = Get-VM -Name $MachineName
        $VM = $VMs[0]
        $PowerState = $VM.PowerState
        Write-Host "VSphereRevertMachine::WaitForMachinePowerOn the power state of ${MachineName} ${PowerState}" -ForegroundColor Green -BackgroundColor Black
            
        if ($PowerState -eq "PoweredOff")
        {
            Write-Host "VSphereRevertMachine::WaitForMachinePowerOn power on the machine ${MachineName}" -ForegroundColor Green -BackgroundColor Black
            Start-VM -VM $VM -Confirm:$false | Select-Object -Property PowerState, Guest | Format-Table
        }
        
        #$VMs = Get-VM -Name $MachineName
        #$VM = $VMs[0]
        #$PowerState = $VM.PowerState
        #Write-Host "VSphereRevertMachine::WaitForMachinePowerOn the power state of ${MachineName} ${PowerState}" -ForegroundColor Green -BackgroundColor Black
    
        $IPv4=""
        $i=0
        Do {
            start-sleep -s 30
            $VMs = Get-VM -Name $MachineName
            $VM = $VMs[0]
            $IPv4 = $VM.Guest.IPAddress | Where-Object {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}
            $PowerState = $VM.PowerState
            Write-Host "VSphereRevertMachine::RevertSnapshot the power state of ${MachineName} ${PowerState}" -ForegroundColor Green -BackgroundColor Black
            Write-Host "VSphereRevertMachine::RevertSnapshot the IP Address of ${MachineName} ${IPv4}" -ForegroundColor Green -BackgroundColor Black
            $i = $i + 1
            
        } # End of 'Do'
        Until (($IPv4 -and $IPv4 -ne "" -and $PowerState -eq "PoweredOn") -or $i -ge 10) 
        Write-Host "VSphereRevertMachine::WaitForMachinePowerOn End" -ForegroundColor Green -BackgroundColor Black
    }
}


