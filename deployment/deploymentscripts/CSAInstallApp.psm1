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
}


class CSAInstallUFT : CSAInstallApp {

    CSAInstallUFT(
    ) : base(
    ) {
        Write-Host "CSAInstallUFT::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [CSAInstallUFT] $instance
    static [CSAInstallUFT] GetInstance() {
        if ([CSAInstallUFT]::instance -eq $null) { 
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
            "CMD.exe /C C:\installUFT.bat ${BuildVersion} mama.hpeswlab.net ${env:Rubicon_Username} ${env:Rubicon_Password}"
        )
        $iloop=0
        $installed=$false
        do {
            if ($iloop -ne 0) {
                Start-Sleep 120
            }
            $ExpressionResult = Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock $sb
            Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
            $iloop=$iloop+1
        } until ( ($installed=$this.CheckUFTExist($CSAName, $CSAAccount, $CSAPwd)) -eq $true -or $iloop -gt 3)
        Write-Host "CSAInstallUFT::InstallApplication End" -ForegroundColor Green -BackgroundColor Black
        return $installed
    }

    [Boolean]CheckUFTExist(
        [string]$CSAName,
        [string]$CSAAccount,
        [string]$CSAPwd
    ) {
        Write-Host "CSAPreparationUninstallUFT::CheckUFTExist Start" -ForegroundColor Green -BackgroundColor Black
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
        $ApplicationDir="\\${CSAName})\C`$\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\UFT.exe"
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
        Write-Host "CSAPreparationUninstallUFT::CheckUFTExist End" -ForegroundColor Green -BackgroundColor Black
        return $IsAppexist
    }
}