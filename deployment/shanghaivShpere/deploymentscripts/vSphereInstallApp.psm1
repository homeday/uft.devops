using namespace System.Management.Automation

class VSphereInstallApp {
    VSphereInstallApp() {
        Write-Host "VSphereInstallApp::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    [Boolean]InstallApplication(
        [string]$MachineName,
        [string]$UserName,
        [string]$Password,        
        [System.Management.Automation.PSCredential]$VSphereCredential,
        [string]$BuildVersion
    ) {
        Write-Host "VSphereInstallApp::InstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        $type = $this.GetType()
        if ($this.GetType() -eq [VSphereInstallApp])
        {
            throw("Class $type must be inherited")
        }
        Write-Host "VSphereInstallApp::InstallApplication End" -ForegroundColor Green -BackgroundColor Black
        return $false
    }

    [Boolean]InstallPatch(
        [string]$MachineName,      
        [System.Management.Automation.PSCredential]$VSphereCredential,
        [string]$BuildVersion,
        [string]$PatchID
    ) {
        Write-Host "VSphereInstallApp::InstallPatch Start" -ForegroundColor Green -BackgroundColor Black
        $type = $this.GetType()
        if ($this.GetType() -eq [VSphereInstallApp])
        {
            throw("Class $type must be inherited")
        }
        Write-Host "VSphereInstallApp::InstallPatch End" -ForegroundColor Green -BackgroundColor Black
        return $true
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
        } until (($null-ne $WinRmSvr -and $WinRmSvr[0].Status -eq "Running") -or $iloop -gt 6)
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

}


class VSphereInstallUFT : VSphereInstallApp {

    VSphereInstallUFT(
    ) : base(
    ) {
        Write-Host "VSphereInstallUFT::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [VSphereInstallUFT] $instance
    static [VSphereInstallUFT] GetInstance() {
        if ([VSphereInstallUFT]::instance -eq $null) { 
            [VSphereInstallUFT]::instance = [VSphereInstallUFT]::new() 
        }
        return [VSphereInstallUFT]::instance
    }
    [Boolean]InstallApplication(
        [string]$MachineName,
        [string]$UserName,
        [string]$Password,        
        [System.Management.Automation.PSCredential]$VSphereCredential,
        [string]$BuildVersion
    ) {
        Write-Host "VSphereInstallUFT::InstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        #$MyIpAddr=(Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4'} | Select-Object -First 1).IPAddress
        $MyIpAddr="shcuftjenkins.hpeswlab.net"

        if (Test-Path 'env:VM_DOMAIN')
        { 
            $MachineName = "${MachineName}.${env:VM_DOMAIN}"
        }
        $sb = [scriptblock]::Create(
            "CMD.exe /C C:\deployUFT.bat ${BuildVersion} mama.hpeswlab.net ${MyIpAddr}"
        )
        $iloop=0
        $installed=$false
        do {
            if ($iloop -ne 0) {
                ([VSphereInstallApp]$this).RestartMachine($MachineName, $VSphereCredential)
                ([VSphereInstallApp]$this).WaitWinRM($MachineName, $VSphereCredential)
                Start-Sleep 5
            }
            $ExpressionResult = Invoke-Command -Credential $VSphereCredential -ComputerName $MachineName -ScriptBlock $sb
            Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
            $iloop=$iloop+1
        } until ( ($installed=$this.CheckUFTInstalled($MachineName, $UserName, $Password, $VSphereCredential, $BuildVersion)) -eq $true -or $iloop -gt 3)
        Write-Host "VSphereInstallUFT::InstallApplication End" -ForegroundColor Green -BackgroundColor Black
        return $installed
    }

    [Boolean]CheckUFTInstalled(
        [string]$MachineName,
        [string]$UserName,
        [string]$Password,
        [System.Management.Automation.PSCredential]$VSphereCredential,
        [string]$BuildVersion
    ) {
        Write-Host "VSphereInstallUFT::CheckUFTInstalled Start" -ForegroundColor Green -BackgroundColor Black
        $IsAppexist=$false
        #$Arguments=@("/C",
        #    "Net Use \\$($this.MachineName)\IPC`$ /USER:$($this.UserName) $($this.Password)"
        #)
        #Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait -PassThru 

        #$NetUseExpression = "Net Use \\$($this.MachineName)\IPC`$ /USER:$($this.UserName) `"$($this.Password)`""
        $NetUseExpression = { Net Use \\$MachineName\IPC$ /USER:$UserName $Password}
        #$ExpressionResult = Invoke-Expression -Command $NetUseExpression
        $ExpressionResult = Invoke-Command -ScriptBlock $NetUseExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        $ApplicationDir="\\${MachineName}\C`$\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\UFT.exe"
        $IsAppexist=Test-Path -Path $ApplicationDir
        Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black

        if (-Not $IsAppexist) {
            $ApplicationDir="\\${MachineName}\C`$\Program Files (x86)\HPE\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        if (-Not $IsAppexist) {
            $ApplicationDir="\\${MachineName}\C`$\Program Files (x86)\HP\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

          try {
            if ($IsAppexist) {
                $IsAppexist = $false
                Write-Host "Check Version ${BuildVersion}" -ForegroundColor Green -BackgroundColor Black
                $result = Invoke-Command -ComputerName $MachineName -Credential $VSphereCredential {Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Mercury Interactive\QuickTest Professional\CurrentVersion"}
                #Write-Host "Check Version result =  ${result}" -ForegroundColor Green -BackgroundColor Black
                if ($result -ne $null) {
                    $versionInreg = $result.Major + "." + $result.Minor + "." + $result.build + ".0"
                    Write-Host "versionInreg = ${versionInreg}" -ForegroundColor Green -BackgroundColor Black
                    if ($versionInreg -eq $BuildVersion) {
                        $IsAppexist = $true
                    }
                }
            }
        }
        catch [Exception] {
            Write-Host $_.Exception|format-list -force
        }

        #$Arguments=@("/C",
        #    "Net Use \\$($this.MachineName)\IPC`$ /D"
        #)
        #Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait
        $NetUseExpression = { Net Use \\${MachineName}\IPC`$ /D }
        $ExpressionResult = Invoke-Command -ScriptBlock $NetUseExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        Write-Host "It is ${IsAppexist} UFT exists" -ForegroundColor Green -BackgroundColor Black
        Write-Host "VSphereInstallUFT::CheckUFTInstalled End" -ForegroundColor Green -BackgroundColor Black
        return $IsAppexist
    }
}

class VSphereInstallSALFT : VSphereInstallUFT {

    VSphereInstallSALFT(
    ) : base(
    ) {
        Write-Host "VSphereInstallSALFT::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [VSphereInstallSALFT] $instance
    static [VSphereInstallSALFT] GetInstance() {
        if ([VSphereInstallSALFT]::instance -eq $null) { 
            [VSphereInstallSALFT]::instance = [VSphereInstallSALFT]::new() 
        }
        return [VSphereInstallSALFT]::instance
    }
    [Boolean]InstallApplication(
        [string]$MachineName,
        [string]$UserName,
        [string]$Password,        
        [System.Management.Automation.PSCredential]$VSphereCredential,
        [string]$BuildVersion
    ) {
        Write-Host "VSphereInstallSALFT::InstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        #$MyIpAddr=(Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4'} | Select-Object -First 1).IPAddress
        $MyIpAddr="shcuftjenkins.hpeswlab.net"
        $sb = [scriptblock]::Create(
            "CMD.exe /C C:\deploySALFT.bat ${BuildVersion} mama.hpeswlab.net ${MyIpAddr}" 
        )
        if (Test-Path 'env:VM_DOMAIN')
        { 
            $MachineName = "${MachineName}.${env:VM_DOMAIN}"
        }
        $iloop=0
        $installed=$false
        do {
            if ($iloop -ne 0) {
                ([VSphereInstallApp]$this).RestartMachine($MachineName, $VSphereCredential)
                ([VSphereInstallApp]$this).WaitWinRM($MachineName, $VSphereCredential)
                Start-Sleep 5
            }
            $ExpressionResult = Invoke-Command -Credential $VSphereCredential -ComputerName $MachineName -ScriptBlock $sb
            Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
            $iloop=$iloop+1
        } until ( ($installed=([VSphereInstallUFT]$this).CheckLFTExist($MachineName, $UserName, $Password)) -eq $true -or $iloop -gt 3)
        Write-Host "VSphereInstallSALFT::InstallApplication End" -ForegroundColor Green -BackgroundColor Black
        return $installed
    }

    [Boolean]CheckLFTExist(
        [string]$MachineName,
        [string]$UserName,
        [string]$Password
    ) {
        Write-Host "VSphereInstallSALFT::CheckLFTExist Start" -ForegroundColor Green -BackgroundColor Black
        $IsAppexist=$false
        #$Arguments=@("/C",
        #    "Net Use \\$($this.MachineName)\IPC`$ /USER:$($this.UserName) $($this.Password)"
        #)
        #Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait -PassThru 

        #$NetUseExpression = "Net Use \\$($this.MachineName)\IPC`$ /USER:$($this.UserName) `"$($this.Password)`""
        $NetUseExpression = { Net Use \\$MachineName\IPC$ /USER:$UserName $Password}
        #$ExpressionResult = Invoke-Expression -Command $NetUseExpression
        $ExpressionResult = Invoke-Command -ScriptBlock $NetUseExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        $ApplicationDir="\\${MachineName}\C`$\Program Files (x86)\Micro Focus\LeanFT\bin\LFTRuntime.exe"
        $IsAppexist=Test-Path -Path $ApplicationDir
        Write-Host "It is ${IsAppexist} that LFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black

        if (-Not $IsAppexist) {
            $ApplicationDir="\\${MachineName}\C`$\Program Files (x86)\HPE\LeanFT\bin\LFTRuntime.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that LFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        if (-Not $IsAppexist) {
            $ApplicationDir="\\${MachineName}\C`$\Program Files (x86)\HP\LeanFT\bin\LFTRuntime.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that LFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        #$Arguments=@("/C",
        #    "Net Use \\$($this.MachineName)\IPC`$ /D"
        #)
        #Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait
        $NetUseExpression = { Net Use \\${MachineName}\IPC`$ /D }
        $ExpressionResult = Invoke-Command -ScriptBlock $NetUseExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        Write-Host "It is ${IsAppexist} LFT exists" -ForegroundColor Green -BackgroundColor Black
        Write-Host "VSphereInstallSALFT::CheckLFTExist End" -ForegroundColor Green -BackgroundColor Black
        return $IsAppexist
    }
}


# class VSphereInstallPatch : VSphereInstallUFT {

#     VSphereInstallPatch(
#     ) : base(
#     ) {
#         Write-Host "VSphereInstallPatch::constructor" -ForegroundColor Green -BackgroundColor Black
#     }
#     static [VSphereInstallPatch] $instance
#     static [VSphereInstallPatch] GetInstance() {
#         if ([VSphereInstallPatch]::instance -eq $null) { 
#             [VSphereInstallPatch]::instance = [VSphereInstallPatch]::new() 
#         }
#         return [VSphereInstallPatch]::instance
#     }

#     [Boolean]InstallPatch(
#         [string]$MachineName,      
#         [System.Management.Automation.PSCredential]$VSphereCredential,
#         [string]$BuildVersion,
#         [string]$PatchID
#     ) {
#         Write-Host "VSphereInstallPatch::InstallPatch Start" -ForegroundColor Green -BackgroundColor Black
#         $sb = [scriptblock]::Create(
#             "CMD.exe /C C:\installUFT_Patch.bat ${BuildVersion} ${PatchID} ${env:Rubicon_Username} ${env:Rubicon_Password}" 
#         )
#         $ExpressionResult = Invoke-Command -Credential $VSphereCredential -ComputerName $MachineName -ScriptBlock $sb
#         Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
#  		Write-Host "VSphereInstallPatch::InstallPatch End" -ForegroundColor Green -BackgroundColor Black
#         return $true
#     }
# }