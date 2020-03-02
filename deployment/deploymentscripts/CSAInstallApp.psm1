using namespace System.Management.Automation

class CSAInstallApp {
    CSAInstallApp() {
        Write-Host "CSAInstallApp::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    [Boolean]InstallApplication(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,        
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$BuildVersion
    ) {
        Write-Host "CSAInstallApp::InstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        $type = $this.GetType()
        if ($this.GetType() -eq [CSAInstallApp])
        {
            throw("Class $type must be inherited")
        }
        Write-Host "CSAInstallApp::InstallApplication End" -ForegroundColor Green -BackgroundColor Black
        return $false
    }

    [Void]RestartMachine(
        [string]$CSAName,
        [System.Management.Automation.PSCredential]$CSACredential
    ) {
        Write-Host "CSAInstallApp::RestartMachine Start" -ForegroundColor Green -BackgroundColor Black
        Restart-Computer -ComputerName $CSAName  -Credential $CSACredential -Wait -Timeout 600 -Force
        Start-Sleep -s 15 
        Write-Host "CSAInstallApp::RestartMachine End" -ForegroundColor Green -BackgroundColor Black
    }

    [Void]WaitWinRM(
        [string]$CSAName,
        [System.Management.Automation.PSCredential]$CSACredential
    ) {
        $iloop=0
        $WinRmSvr = $null
        do {
            if ($iloop -ne 0) {
                Start-Sleep 30
            }
            $WinRmSvr = Invoke-Command -Credential $CSACredential  -ComputerName $CSAName -ScriptBlock {Get-Service -Name winrm}
            Write-Host "CSAInstallApp::WaitWinRM Get winrm service result" -ForegroundColor Green -BackgroundColor Black
            Write-Host $WinRmSvr -ForegroundColor Green -BackgroundColor Black
            $iloop = $iloop + 1
        } until (($null-ne $WinRmSvr -and $WinRmSvr[0].Status -eq "Running") -or $iloop -gt 3)
        if ($null -eq $WinRmSvr) {
            throw("WinRm Services must be started!")
        }
    }

    [Void]StopMsiexecProcess(
        [string]$CSAName,      
        [System.Management.Automation.PSCredential]$CSACredential  
    ) {
        Write-Host "CSAInstallApp::StopMsiexecProcess Start" -ForegroundColor Green -BackgroundColor Black
        Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock {
            Get-Process -Name "msiexec" | Stop-Process -Force 
        }
        Write-Host "CSAInstallApp::StopMsiexecProcess Stop" -ForegroundColor Green -BackgroundColor Black
    }
    
    [Boolean]InstallPatch(
        [string]$CSAName,      
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$BuildVersion,
        [string]$PatchID
    ) {
        Write-Host "CSAInstallApp::InstallPatch Start" -ForegroundColor Green -BackgroundColor Black
        $type = $this.GetType()
        if ($this.GetType() -eq [CSAInstallApp])
        {
            throw("Class $type must be inherited")
        }
        Write-Host "CSAInstallApp::InstallPatch End" -ForegroundColor Green -BackgroundColor Black
        return $true
    }
}


class CSAInstallUFT : CSAInstallApp {

    CSAInstallUFT(
    ) : base(
    ) {
        Write-Host "CSAInstallUFT::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [CSAInstallUFT] $instance
    static [CSAInstallUFT] GetInstance() {
        if ($null -eq [CSAInstallUFT]::instance) { 
            [CSAInstallUFT]::instance = [CSAInstallUFT]::new() 
        }
        return [CSAInstallUFT]::instance
    }
    [Boolean]InstallApplication(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,        
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$BuildVersion
    ) {
        Write-Host "CSAInstallUFT::InstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        $sb = [scriptblock]::Create(
            "CMD.exe /C C:\installUFT.bat ${BuildVersion} mama.swinfra.net ${env:Rubicon_Username} ${env:Rubicon_Password}"
        )
        $iloop=0
        $installed=$false
        do {
            if ($iloop -ne 0) {
                ([CSAInstallUFT]$this).RestartMachine($CSAName, $CSACredential)
                ([CSAInstallUFT]$this).WaitWinRM($CSAName, $CSACredential)
                Start-Sleep 5
            }
            $this.StopMsiexecProcess($CSAName, $CSACredential)
            $ExpressionResult = Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock $sb
            Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
            $iloop=$iloop+1
        } until ( ($installed=$this.CheckUFTInstalled($CSAName, $CSAAccount, $CSAPwd, $CSACredential, $BuildVersion)) -eq $true -or $iloop -gt 3)
        Write-Host "CSAInstallUFT::InstallApplication End" -ForegroundColor Green -BackgroundColor Black
        return $installed
    }

    [Boolean]CheckUFTInstalled(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$BuildVersion
    ) {
        Write-Host "CSAInstallUFT::CheckUFTInstalled Start" -ForegroundColor Green -BackgroundColor Black
        $IsAppexist=$false
        #$Arguments=@("/C",
        #    "Net Use \\$($this.CSAName)\IPC`$ /USER:$($this.CSAAccount) $($this.CSAPwd)"
        #)
        #Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait -PassThru 

        #$NetUseExpression = "Net Use \\$($this.CSAName)\IPC`$ /USER:$($this.CSAAccount) `"$($this.CSAPwd)`""
        $NetUseExpression = { Net Use \\$CSAName\IPC$ /USER:$CSAAccount $CSAPwd}
        #$ExpressionResult = Invoke-Expression -Command $NetUseExpression
        $ExpressionResult = Invoke-Command -ScriptBlock $NetUseExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        $ApplicationDir="\\${CSAName}\C`$\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\UFT.exe"
        $IsAppexist=Test-Path -Path $ApplicationDir
        Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black

        if (-Not $IsAppexist) {
            $ApplicationDir="\\${CSAName}\C`$\Program Files (x86)\HPE\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        if (-Not $IsAppexist) {
            $ApplicationDir="\\${CSAName}\C`$\Program Files (x86)\HP\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        if (-Not $IsAppexist) {
            $ApplicationDir="\\${CSAName}\C`$\Program Files\Micro Focus\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        if (-Not $IsAppexist) {
            $ApplicationDir="\\${CSAName}\C`$\Program Files\HPE\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        if (-Not $IsAppexist) {
            $ApplicationDir="\\${CSAName}\C`$\Program Files\HP\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        try {
            if ($IsAppexist) {
                $IsAppexist = $false
                if ($BuildVersion -match "[1-9]{2}\.[8|9]{1}[0-9]{1}") {
                    $IsAppexist = $true
                } else {
                    Write-Host "Check Version ${BuildVersion}" -ForegroundColor Green -BackgroundColor Black
                    $result = Invoke-Command -ComputerName $CSAName -Credential $CSACredential {Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Mercury Interactive\QuickTest Professional\CurrentVersion"}
                    #Write-Host "Check Version result =  ${result}" -ForegroundColor Green -BackgroundColor Black
                    if ($result -ne $null) {
                        $versionInreg = $result.Major + "." + $result.Minor + "." + $result.ServicePack + "." + $result.build
                        Write-Host "versionInreg = ${versionInreg}" -ForegroundColor Green -BackgroundColor Black
                        if ($versionInreg -eq $BuildVersion) {
                            $IsAppexist = $true
                            ([CSAInstallApp]$this).RestartMachine($CSAName, $CSACredential)
                        }
                    }
                }
            }

        }
        catch [Exception] {
            Write-Host $_.Exception|format-list -force
        }
        
        #$Arguments=@("/C",
        #    "Net Use \\$($this.CSAName)\IPC`$ /D"
        #)
        #Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait
        $NetUseExpression = { Net Use \\${CSAName}\IPC`$ /D }
        $ExpressionResult = Invoke-Command -ScriptBlock $NetUseExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        Write-Host "It is ${IsAppexist} UFT exists" -ForegroundColor Green -BackgroundColor Black
        Write-Host "CSAInstallUFT::CheckUFTInstalled End" -ForegroundColor Green -BackgroundColor Black
        return $IsAppexist
    }
}

class CSAInstallLFTAsFt : CSAInstallUFT {

    CSAInstallLFTAsFt(
    ) : base(
    ) {
        Write-Host "CSAInstallLFTAsFt::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [CSAInstallLFTAsFt] $instance
    static [CSAInstallLFTAsFt] GetInstance() {
        if ($null -eq [CSAInstallLFTAsFt]::instance) { 
            [CSAInstallLFTAsFt]::instance = [CSAInstallLFTAsFt]::new() 
        }
        return [CSAInstallLFTAsFt]::instance
    }
    [Boolean]InstallApplication(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,        
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$BuildVersion
    ) {
        Write-Host "CSAInstallLFTAsFt::InstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        $sb = [scriptblock]::Create(
            "CMD.exe /C C:\installUFT_LFTasFeature.bat ${BuildVersion} mama.hpeswlab.net ${env:Rubicon_Username} ${env:Rubicon_Password}" 
        )
        $iloop=0
        $installed=$false
        do {
            if ($iloop -ne 0) {
                ([CSAInstallUFT]$this).RestartMachine($CSAName, $CSACredential)
                ([CSAInstallUFT]$this).WaitWinRM($CSAName, $CSACredential)
                Start-Sleep 5
            }
            $this.StopMsiexecProcess($CSAName, $CSACredential)
            $ExpressionResult = Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock $sb
            Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
            $iloop=$iloop+1
        } until ( ($installed=([CSAInstallUFT]$this).CheckUFTInstalled($CSAName, $CSAAccount, $CSAPwd, $CSACredential, $BuildVersion)) -eq $true -or $iloop -gt 3)
        Write-Host "CSAInstallLFTAsFt::InstallApplication End" -ForegroundColor Green -BackgroundColor Black
        return $installed
    }
}



class CSAInstallRPA : CSAInstallUFT {

    CSAInstallRPA(
    ) : base(
    ) {
        Write-Host "CSAInstallRPA::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [CSAInstallRPA] $instance
    static [CSAInstallRPA] GetInstance() {
        if ($null -eq [CSAInstallRPA]::instance) { 
            [CSAInstallRPA]::instance = [CSAInstallRPA]::new() 
        }
        return [CSAInstallRPA]::instance
    }
    [Boolean]InstallApplication(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,        
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$BuildVersion
    ) {
        Write-Host "CSAInstallRPA::InstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        $sb = [scriptblock]::Create(
            "CMD.exe /C C:\installUFTOO.bat ${BuildVersion} mama.swinfra.net ${env:Rubicon_Username} ${env:Rubicon_Password}" 
        )
        $iloop=0
        $installed=$false
        do {
            if ($iloop -ne 0) {
                ([CSAInstallUFT]$this).RestartMachine($CSAName, $CSACredential)
                ([CSAInstallUFT]$this).WaitWinRM($CSAName, $CSACredential)
                Start-Sleep 5
            }
            $this.StopMsiexecProcess($CSAName, $CSACredential)
            $ExpressionResult = Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock $sb
            Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
            $iloop=$iloop+1
        } until ( ($installed=([CSAInstallUFT]$this).CheckUFTInstalled($CSAName, $CSAAccount, $CSAPwd, $CSACredential, $BuildVersion)) -eq $true -or $iloop -gt 3)
        Write-Host "CSAInstallRPA::InstallApplication End" -ForegroundColor Green -BackgroundColor Black
        return $installed
    }
}

class CSAInstallAI : CSAInstallUFT {

    CSAInstallAI(
    ) : base(
    ) {
        Write-Host "CSAInstallAI::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [CSAInstallAI] $instance
    static [CSAInstallAI] GetInstance() {
        if ($null -eq [CSAInstallAI]::instance) { 
            [CSAInstallAI]::instance = [CSAInstallAI]::new() 
        }
        return [CSAInstallAI]::instance
    }
    [Boolean]InstallApplication(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,        
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$BuildVersion
    ) {
        Write-Host "CSAInstallAI::InstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        $sb = [scriptblock]::Create(
            "CMD.exe /C C:\installAI.bat ${BuildVersion} mama.swinfra.net ${env:Rubicon_Username} ${env:Rubicon_Password}" 
        )
        $iloop=0
        $installed=$false
        do {
            if ($iloop -ne 0) {
                ([CSAInstallUFT]$this).RestartMachine($CSAName, $CSACredential)
                ([CSAInstallUFT]$this).WaitWinRM($CSAName, $CSACredential)
                Start-Sleep 5
            }
            $this.StopMsiexecProcess($CSAName, $CSACredential)
            $ExpressionResult = Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock $sb
            Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
            $iloop=$iloop+1
        } until ( ($installed=([CSAInstallUFT]$this).CheckUFTInstalled($CSAName, $CSAAccount, $CSAPwd, $CSACredential, $BuildVersion)) -eq $true -or $iloop -gt 3)
        Write-Host "CSAInstallAI::InstallApplication End" -ForegroundColor Green -BackgroundColor Black
        return $installed
    }
}



class CSAInstallPatch : CSAInstallUFT {

    CSAInstallPatch(
    ) : base(
    ) {
        Write-Host "CSAInstallPatch::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [CSAInstallPatch] $instance
    static [CSAInstallPatch] GetInstance() {
        if ($null -eq [CSAInstallPatch]::instance) { 
            [CSAInstallPatch]::instance = [CSAInstallPatch]::new() 
        }
        return [CSAInstallPatch]::instance
    }

    [Boolean]InstallPatch(
        [string]$CSAName,      
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$BuildVersion,
        [string]$PatchID
    ) {
        Write-Host "CSAInstallPatch::InstallPatch Start" -ForegroundColor Green -BackgroundColor Black
        $sb = [scriptblock]::Create(
            "CMD.exe /C C:\installUFT_Patch.bat ${BuildVersion} ${PatchID} ${env:Rubicon_Username} ${env:Rubicon_Password}" 
        )
        $ExpressionResult = Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock $sb
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
 		Write-Host "CSAInstallPatch::InstallPatch End" -ForegroundColor Green -BackgroundColor Black
        return $true
    }
}