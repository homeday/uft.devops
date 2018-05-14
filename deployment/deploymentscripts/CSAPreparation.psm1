using namespace System.Management.Automation

class CSAPreparation {
    CSAPreparation() {
        Write-Host "CSAPreparation::constructor" -ForegroundColor Green -BackgroundColor Black
    }

    [Void] doAction(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,
        [PSCredential]$CSACredential,
        [string]$CSASubscriptionID
    ) {
         
        $type = $this.GetType()
        if ($this.GetType() -eq [CSAPreparation])
        {
            throw("Class $type must be inherited")
        }
        #$PSExecExpression = {D:\PSTools\PsExec.exe \\$CSAName -u $CSAAccount -p $CSAPwd powershell.exe "enable-psremoting -force"}
        #$ExpressionResult = Invoke-Command -ScriptBlock $PSExecExpression
        #Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        $iloop=0
        $WinRmSvr = $null
        do {
            if ($iloop -ne 0) {
                Start-Sleep 120
            }
            $WinRmSvr = Invoke-Command -Credential $CSACredential  -ComputerName $CSAName -ScriptBlock {Get-Service -Name winrm}
            Write-Host $WinRmSvr -ForegroundColor Green -BackgroundColor Black
            $iloop = $iloop + 1
        } until (($WinRmSvr -ne $null -and $WinRmSvr[0].Status -eq "Running") -or $iloop -gt 3)
        if ($null -eq $WinRmSvr) {
            throw("WinRm Services must be started!")
        }

        $this.CopyRelatedFiles($CSAName, $CSACredential)
        Write-Host "To delete useless files at remote machine" -ForegroundColor Green -BackgroundColor Black
        $ExpressionResult = Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock `
        { `
            CMD.exe /C C:\del.bat `
        } 
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        Write-Host "CSAPreparation::End Start" -ForegroundColor Green -BackgroundColor Black
    }

    [Void]RestartMachine(
        [string]$CSAName,
        [System.Management.Automation.PSCredential]$CSACredential
    ) {
        Write-Host "RestartMachine Start" -ForegroundColor Green -BackgroundColor Black
        Restart-Computer -ComputerName $CSAName  -Credential $CSACredential -Wait -Timeout 600 -Force
        Start-Sleep -s 15 
        Write-Host "RestartMachine End" -ForegroundColor Green -BackgroundColor Black
    }

    [Void]CopyRelatedFiles(
        [string]$CSAName,
        [System.Management.Automation.PSCredential]$CSACredential
    ) {
        $ConnSession = New-PSSession -ComputerName $CSAName -Credential $CSACredential 
        Copy-Item "${PSScriptRoot}\del.bat" -Destination "C:\" -ToSession $ConnSession -Recurse
        Copy-Item "${PSScriptRoot}\UFTUninstaller_v2.0" -Destination "C:\" -ToSession $ConnSession -Recurse
        Copy-Item "${PSScriptRoot}\installUFT.bat" -Destination "C:\" -ToSession $ConnSession -Recurse
        Copy-Item "${PSScriptRoot}\installUFT_Patch.bat" -Destination "C:\" -ToSession $ConnSession -Recurse
        Copy-Item "${PSScriptRoot}\HP UFT-licfile.dat" -Destination "C:\" -ToSession $ConnSession -Recurse
        if ($null -ne $ConnSession) {
            Remove-PSSession -Session $ConnSession
        }
    }
    
}

class CSAPreparationUninstallUFT : CSAPreparation {
    
    CSAPreparationUninstallUFT (
    ) : base(
    ) {
        Write-Host "CSAPreparationUninstallUFT::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [CSAPreparationUninstallUFT] $instance
    static [CSAPreparationUninstallUFT] GetInstance() {
        if ([CSAPreparationUninstallUFT]::instance -eq $null) { 
            [CSAPreparationUninstallUFT]::instance = [CSAPreparationUninstallUFT]::new() 
        }
        return [CSAPreparationUninstallUFT]::instance
    }
    [Void] doAction(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$CSASubscriptionID
    ) {
        Write-Host "CSAPreparationUninstallUFT::doAction Start" -ForegroundColor Green -BackgroundColor Black        
        ([CSAPreparation]$this).doAction($CSAName, $CSAAccount,$CSAPwd, $CSACredential, $CSASubscriptionID)
        $isUFTExists = $this.CheckUFTExist($CSAName, $CSAAccount, $CSAPwd);

        if ($isUFTExists) {
            $this.UninstallApplication($CSAName, $CSACredential)
        }
        Write-Host "CSAPreparationUninstallUFT::doAction End" -ForegroundColor Green -BackgroundColor Black

    }

    [Boolean]CheckUFTExist(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd
    ) {
        Write-Host "CSAPreparationUninstallUFT::CheckAppExist Start" -ForegroundColor Green -BackgroundColor Black
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

        #$Arguments=@("/C",
        #    "Net Use \\$($this.CSAName)\IPC`$ /D"
        #)
        #Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait
        $NetUseExpression = { Net Use \\${CSAName}\IPC`$ /D }
        $ExpressionResult = Invoke-Command -ScriptBlock $NetUseExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        Write-Host "It is ${IsAppexist} UFT exists" -ForegroundColor Green -BackgroundColor Black
        Write-Host "CSAPreparationUninstallUFT::CheckAppExist End" -ForegroundColor Green -BackgroundColor Black
        return $IsAppexist
    }

    [Void]UninstallApplication(
        [string]$CSAName,
        [System.Management.Automation.PSCredential]$CSACredential
    ) {
        Write-Host "CSAPreparationUninstallUFT::UninstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        ([CSAPreparation]$this).RestartMachine($CSAName, $CSACredential)
        Write-Host "To delete old version UFT with the uninstaller tool" -ForegroundColor Green -BackgroundColor Black
        $ExpressionResult = Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock `
        { `
            Start-Process -FilePath C:\UFTUninstaller_v2.0\UFTUninstaller.exe -ArgumentList -silent -Wait `
        } 
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        ([CSAPreparation]$this).RestartMachine($CSAName, $CSACredential)
        Write-Host "CSAPreparationUninstallUFT::UninstallApplication End" -ForegroundColor Green -BackgroundColor Black
    }
}

class CSAPreparationRevertMachine : CSAPreparation {
    CSAPreparationRevertMachine (
    ) : base(
    ) {
        
    }
   
    static [CSAPreparationRevertMachine] $instance
    static [CSAPreparationRevertMachine] GetInstance() {
        if ([CSAPreparationRevertMachine]::instance -eq $null) { 
            [CSAPreparationRevertMachine]::instance = [CSAPreparationRevertMachine]::new() 
        }
        return [CSAPreparationRevertMachine]::instance
    }

    [Void] doAction(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,
        [System.Management.Automation.PSCredential]$CSACredential,
        [string]$CSASubscriptionID
    ) {
        Write-Host "CSAPreparationRevertMachine::doAction Start" -ForegroundColor Green -BackgroundColor Black
        if ( $CSAAccount -eq $null -or $CSAAccount  -eq "") {
            $CSAAccount = ${env:CSAAccount}
        } 
        
        if ( $CSAPwd -eq $null -or $CSAPwd  -eq "") {
            $CSAPwd = ${env:CSAPwd}
        }
        if ($null -eq $CSACredential) {
            $SecPwd = ConvertTo-Securestring $CSAPwd -AsPlainText -Force
            $CSACredential = New-Object System.Management.Automation.PSCredential($CSAAccount, $SecPwd)
        }
        
        $this.RevertSnapshot($CSAName, $CSAAccount, $CSAPwd, $CSASubscriptionID)
        ([CSAPreparation]$this).doAction($CSAName, $CSAAccount,$CSAPwd, $CSACredential, $CSASubscriptionID)
        

    }

    [Void]RevertSnapshot(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd,
        [string]$CSASubscriptionID
    ) {
        Write-Host "CSAPreparationRevertMachine::RevertSnapshot Start" -ForegroundColor Green -BackgroundColor Black
        $Arguments=@("-jar",
            "CSAWrapper-5.0.0.jar",
            "subscriptionId=$CSASubscriptionID",
            "actionName=RevertToSnapshot",
            "csaOrganization=ADM",
            "csaUrl=https://mydcsa.hpeswlab.net:8443/csa/rest",
            "csaUsername=$CSAAccount",
            "csaPassword=$CSAPwd")
        $JavaExpression = { java $Arguments }
        $ExpressionResult = Invoke-Command -ScriptBlock $JavaExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        Start-Sleep 60
        $Arguments=@("-jar",
            "CSAWrapper-5.0.0.jar",
            "subscriptionId=$CSASubscriptionID",
            "actionName=Restart",
            "csaOrganization=ADM",
            "csaUrl=https://mydcsa.hpeswlab.net:8443/csa/rest",
            "csaUsername=$CSAAccount",
            "csaPassword=$CSAPwd")
        $JavaExpression = { java $Arguments }
        $ExpressionResult = Invoke-Command -ScriptBlock $JavaExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        #$ExecProcess=Start-Process -FilePath java.exe -ArgumentList "${Arguments}" -Wait -PassThru 
        Start-Sleep 60
        Write-Host "CSAPreparationRevertMachine::RevertSnapshot End" -ForegroundColor Green -BackgroundColor Black
    }

    
}


