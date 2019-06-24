using module '.\CSAPreparation.psm1'
using module '.\CSAInstallApp.psm1'


class CSAMachineDeploy {

    [string]$CSAName
    [ValidatePattern("^[a-fA-F\d]{32}")]
    [string]$CSASubscriptionID
    [string]$CSAAccount
    [string]$CSAPassword
    [string]$ApplicationName
    [System.Management.Automation.PSCredential]$CSACredential

    CSAMachineDeploy(
        [string]$CSAName,
        [string]$CSASubscriptionID,  
        [string]$CSAAccount,
        [string]$CSAPassword
    ){
        if ( $CSAAccount -eq $null -or $CSAAccount  -eq "") {
            $this.CSAAccount = ${env:CSAAccount}
        } else {
            $this.CSAAccount = $CSAAccount
        }
        
        if ( $CSAPassword -eq $null -or $CSAPassword  -eq "") {
            $this.CSAPassword = ${env:CSAPassword}
        } else {
            $this.CSAPassword = $CSAPassword
        }
        $this.CSAName=$CSAName
        $this.CSACredential = $null
        $this.CSASubscriptionID=$CSASubscriptionID
    }

    [System.Management.Automation.PSCredential]SetCredential(

    ){
        Write-Host "Set Credential Start" -ForegroundColor Green -BackgroundColor Black
        if ($null -eq $this.CSACredential) {
            $SecPwd = ConvertTo-Securestring $this.CSAPassword -AsPlainText -Force
            $this.CSACredential = New-Object System.Management.Automation.PSCredential($this.CSAAccount, $SecPwd)
        }
        Write-Host "Credential is $($this.CSACredential)" -ForegroundColor Green -BackgroundColor Black
        Write-Host "Set Credential End" -ForegroundColor Green -BackgroundColor Black
        return $this.CSACredential
    }

    
    [Void]PrepareMachine(

    ) {
        $this.SetCredential()
        $PSExecExpression = {d:\PSTools\psexec.exe -u $($this.CSAAccount) -p $($this.CSAPassword) powershell.exe "enable-psremoting -force"}
        $ExpressionResult = Invoke-Command -ScriptBlock $PSExecExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        $sb = [scriptblock]::Create(
            "Get-Service -Name winrm -ComputerName myd-vm08159 | Set-Service -Status Running"
        )
        $iloop=0
        $WinRmSvr = $null
        do {
            if ($iloop -ne 0) {
                Start-Sleep 120
            }
            $WinRmSvr = Invoke-Command -Credential $this.CSACredential  -ComputerName $this.CSAName -ScriptBlock {Get-Service -Name winrm}
            Write-Host $WinRmSvr -ForegroundColor Green -BackgroundColor Black
            $iloop = $iloop + 1
        } until (($WinRmSvr -ne $null -and $WinRmSvr[0].Status -eq "Running") -or $iloop -gt 3)
    }

    [Boolean]DeployWithBuildVersion (
        [string]$BuildVersion
    )
    {  
        $this.PrepareMachine()
        return $this.InstallApplication($BuildVersion)
    }

    [Boolean]CheckAppExist(
    ) {
        Write-Host "CheckAppExist Start" -ForegroundColor Green -BackgroundColor Black
        $IsAppexist=$false
        #$Arguments=@("/C",
        #    "Net Use \\$($this.CSAName)\IPC`$ /USER:$($this.CSAAccount) $($this.CSAPassword)"
        #)
        #Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait -PassThru 

        #$NetUseExpression = "Net Use \\$($this.CSAName)\IPC`$ /USER:$($this.CSAAccount) `"$($this.CSAPassword)`""
        $NetUseExpression = { Net Use \\$($this.CSAName)\IPC$ /USER:$($this.CSAAccount) $($this.CSAPassword)}
        #$ExpressionResult = Invoke-Expression -Command $NetUseExpression
        $ExpressionResult = Invoke-Command -ScriptBlock $NetUseExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        $ApplicationDir="\\$($this.CSAName)\C`$\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\UFT.exe"
        $IsAppexist=Test-Path -Path $ApplicationDir
        Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black

        if (-Not $IsAppexist) {
            $ApplicationDir="\\$($this.CSAName)\C`$\Program Files (x86)\HPE\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        if (-Not $IsAppexist) {
            $ApplicationDir="\\$($this.CSAName)\C`$\Program Files (x86)\HP\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}" -ForegroundColor Green -BackgroundColor Black
        }

        #$Arguments=@("/C",
        #    "Net Use \\$($this.CSAName)\IPC`$ /D"
        #)
        #Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait
        $NetUseExpression = { Net Use \\$($this.CSAName)\IPC`$ /D }
        $ExpressionResult = Invoke-Command -ScriptBlock $NetUseExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        Write-Host "It is ${IsAppexist} UFT exists" -ForegroundColor Green -BackgroundColor Black
        Write-Host "CheckAppExist End" -ForegroundColor Green -BackgroundColor Black
        return $IsAppexist
    }

    [Void]RestartMachine(

    ) {
        Write-Host "RestartMachine Start" -ForegroundColor Green -BackgroundColor Black
        Restart-Computer -ComputerName $this.CSAName  -Credential $this.CSACredential -Wait -Timeout 300 -Force
        Start-Sleep -s 15 
        Write-Host "RestartMachine End" -ForegroundColor Green -BackgroundColor Black
    }

    [Void]CopyFileToMachine(
        [string]$SrcDir, [string]$DestDir
    ) {
        $ConnSession = New-PSSession -ComputerName $this.CSAName -Credential $this.CSACredential 
        Copy-Item $SrcDir -Destination $DestDir -ToSession $ConnSession -Recurse
        if ($null -ne $ConnSession) {
            Remove-PSSession -Session $ConnSession
        }
    }

    [Boolean]InstallApplication(
        [string]$BuildVersion
    ) {
        Write-Host "InstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        ([CSAMachineDeploy]$this).CopyFileToMachine("${PSScriptRoot}\installUFT_LeanFT.bat", "C:\")
        $sb = [scriptblock]::Create(
            "CMD.exe /C C:\installUFT_LeanFT.bat ${BuildVersion} mama.hpeswlab.net"
        )
        $iloop=0
        $installed=$false
        do {
            if ($iloop -ne 0) {
                Start-Sleep 120
            }
            $ExpressionResult = Invoke-Command -Credential $this.CSACredential -ComputerName $this.CSAName -ScriptBlock $sb
            Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
            $iloop=$iloop+1
        } until ( ($installed=$this.CheckAppExist()) -eq $true -or $iloop -gt 3)
        Write-Host "InstallApplication End - ${installed}" -ForegroundColor Green -BackgroundColor Black
        return $installed
    }
    
}


class CSAMachineDeployUninstall : CSAMachineDeploy {

    CSAMachineDeployUninstall (
        [string]$CSAName,
        [string]$CSASubscriptionID,  
        [string]$CSAAccount = "",
        [string]$CSAPassword = ""
    ) : base(
        $CSAName,
        $CSASubscriptionID,
        $CSAAccount,
        $CSAPassword) {
        
    }

    [Void]UninstallApplication(

    ) {
        Write-Host "UninstallApplication Start" -ForegroundColor Green -BackgroundColor Black
        Write-Host "Copy the uninstaller tool to the machine Start" -ForegroundColor Green -BackgroundColor Black
        ([CSAMachineDeploy]$this).CopyFileToMachine("${PSScriptRoot}\del.bat", "C:\")
        ([CSAMachineDeploy]$this).CopyFileToMachine("${PSScriptRoot}\UFTUninstaller_v2.0", "C:\")
        Write-Host " Copy the uninstaller tool to the machine End" -ForegroundColor Green -BackgroundColor Black
        #Set-Item WSMan:\localhost\Client\TrustedHosts -Value ([CSAMachineDeploy]$this).CSAName -Force
        if (([CSAMachineDeploy]$this).CheckAppExist()) {
            ([CSAMachineDeploy]$this).RestartMachine()
            Write-Host "To delete old version UFT with the uninstaller tool" -ForegroundColor Green -BackgroundColor Black
            $ExpressionResult = Invoke-Command -Credential ([CSAMachineDeploy]$this).CSACredential -ComputerName ([CSAMachineDeploy]$this).CSAName -ScriptBlock `
            { `
                Start-Process -FilePath C:\UFTUninstaller_v2.0\UFTUninstaller.exe -ArgumentList -silent -Wait `
            } 
            Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
            ([CSAMachineDeploy]$this).RestartMachine()
        }
        Write-Host "To delete useless files at remote machine" -ForegroundColor Green -BackgroundColor Black
        $ExpressionResult = Invoke-Command -Credential ([CSAMachineDeploy]$this).CSACredential -ComputerName ([CSAMachineDeploy]$this).CSAName -ScriptBlock `
        { `
            CMD.exe /C C:\del.bat `
        } 
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        Write-Host "UninstallApplication End" -ForegroundColor Green -BackgroundColor Black
    }


    [Void]PrepareMachine(

    ) {
       ([CSAMachineDeploy]$this).PrepareMachine()
       ([CSAMachineDeploy]$this).UninstallApplication()
    }

}

class CSAMachineDeploySnapShot : CSAMachineDeploy {

    CSAMachineDeploySnapShot (
        [string]$CSAName,
        [string]$CSASubscriptionID = "",  
        [string]$CSAAccount = "",
        [string]$CSAPassword = ""
    ) : base(
        $CSAName,
        $CSASubscriptionID,
        $CSAAccount,
        $CSAPassword) {
    }

    [Void]RevertSnapshot() {
        Write-Host "RevertSnapshot Start" -ForegroundColor Green -BackgroundColor Black
        $Arguments=@("-jar",
            "CSAWrapper-5.0.0.jar",
            "subscriptionId=$(([CSAMachineDeploy]$this).CSASubscriptionID)",
            "actionName=RevertToSnapshot",
            "csaOrganization=ADM",
            "csaUrl=https://mydcsa.hpeswlab.net:8443/csa/rest",
            "csaUsername=$(([CSAMachineDeploy]$this).CSAAccount)",
            "csaPassword=$(([CSAMachineDeploy]$this).CSAPassword)")
        $JavaExpression = { java $Arguments }
        $ExpressionResult = Invoke-Command -ScriptBlock $JavaExpression
        Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
        #$ExecProcess=Start-Process -FilePath java.exe -ArgumentList "${Arguments}" -Wait -PassThru 
        Start-Sleep 60
        Write-Host "RevertSnapshot End" -ForegroundColor Green -BackgroundColor Black
    }

    [Void]PrepareMachine(

    ) {
       ([CSAMachineDeploy]$this).PrepareMachine()
       $this.RevertSnapshot()
    }
}

# function Install-Application {
#     [CmdletBinding(SupportsShouldProcess=$True)]
#     param (
#         [Parameter(Mandatory=$true)]
#         [string]$CSAName = "",
#         [Parameter(Mandatory=$true)]
#         [string]$BuidlVersion = "",
#         [string]$CleanMode = "uninstall",
#         [string]$SUBSCRIPTION_ID = ""
#     )
#     $csaDeployment=$null
#     switch($CleanMode) 
#     {
#         "resnapshot" {
#             $csaDeployment = [CSAMachineDeploySnapShot]::new($CSAName,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
#             break
#         }
#         "uninstall" {
#             $csaDeployment = [CSAMachineDeployUninstall]::new($CSAName,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
#             break
#         }
#         default {
#             $csaDeployment = [CSAMachineDeployUninstall]::new($CSAName,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
#             break
#         }
#     }
#     if ($csaDeployment -ne $null) {
#         return $csaDeployment.DeployWithBuildVersion($BuidlVersion)
#     }
#     return $false
# }


#############################################################################
#Refactoring
#############################################################################
class CSADeployment {

    hidden [string]$CSAName
    [ValidatePattern("^[a-fA-F\d]{32}")]
    hidden [string]$CSASubscriptionID
    hidden [string]$CSAAccount
    hidden [string]$CSAPassword
    hidden [string]$ApplicationName
    hidden [System.Management.Automation.PSCredential]$CSACredential
    hidden [CSAPreparation]$CSAPreparation
    hidden [CSAInstallApp]$CSAInstallApp
    CSADeployment(
        [string]$CSAName,
        [string]$CSASubscriptionID
    ){
        
        if ($null -eq ${env:CSADomain} -Or ${env:CSADomain} -eq "") {
            $this.CSAAccount = ${env:CSAAccount}
        } else {
            $this.CSAAccount = "${env:CSADomain}\${env:CSAAccount}"
        } 
        $this.CSAPassword = ${env:CSAPassword}
        $this.CSAName=$CSAName
        $this.CSACredential = $null
        $this.CSASubscriptionID=$CSASubscriptionID
        $this.CSAPreparation = $null
        $this.CSAInstallApp = $null
        $this.SetCredential()
    }

    CSADeployment(
        [string]$CSAName,
        [string]$CSASubscriptionID,  
        [string]$CSAAccount,
        [string]$CSAPassword
    ){
        if ( $CSAAccount -eq $null -or $CSAAccount  -eq "") {
            if ( ${env:CSADomain} -eq "") {
                $this.CSAAccount = ${env:CSAAccount}
            } else {
                $this.CSAAccount = "${env:CSADomain}\${env:CSAAccount}"
            }
        } else {
            $this.CSAAccount = $CSAAccount
        }
        
        if ( $CSAPassword -eq $null -or $CSAPassword  -eq "") {
            $this.CSAPassword = ${env:CSAPassword}
        } else {
            $this.CSAPassword = $CSAPassword
        }
        $this.CSAName=$CSAName
        $this.CSACredential = $null
        $this.CSASubscriptionID=$CSASubscriptionID
        $this.CSAPreparation = $null
        $this.CSAInstallApp = $null
        $this.SetCredential()
    }

    [System.Management.Automation.PSCredential]SetCredential(

    ){
        Write-Host "CSADeployment::SetCredential Start" -ForegroundColor Green -BackgroundColor Black
        if ($null -eq $this.CSACredential) {
            $SecPwd = ConvertTo-Securestring $this.CSAPassword -AsPlainText -Force
            $this.CSACredential = New-Object System.Management.Automation.PSCredential($this.CSAAccount, $SecPwd)
        }
        Write-Host "Credential is $($this.CSACredential)" -ForegroundColor Green -BackgroundColor Black
        Write-Host "CSADeployment::SetCredential End" -ForegroundColor Green -BackgroundColor Black
        return $this.CSACredential
    }

    [Void]SetCSAPreparation([CSAPreparation]$CSAPreparation) {
        $this.CSAPreparation = $CSAPreparation
    }


    [Void]SetCSAInstallApp([CSAInstallApp]$CSAInstallApp) {
        $this.CSAInstallApp = $CSAInstallApp
    }

    [Void]PrepareMachine() {
        $this.CSAPreparation.doAction($this.CSAName, $this.CSAAccount,$this.CSAPassword, $this.CSACredential, $this.CSASubscriptionID)
    }

    [Boolean]InstallApplication(
        [string]$BuildVersion
    ) {
        return $this.CSAInstallApp.InstallApplication($this.CSAName, $this.CSAAccount,$this.CSAPassword, $this.CSACredential, $BuildVersion)
    }


    [Boolean]InstallPatch(
        [string]$BuildVersion,
        [string]$PatchID
    ) {
        return $this.CSAInstallApp.InstallPatch($this.CSAName, $this.CSACredential, $BuildVersion, $PatchID)
    }



    
}



function Install-Application {
    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$CSAName = "",
        [Parameter(Mandatory=$true)]
        [string]$BuidlVersion = "",
        [Parameter(Mandatory=$true)]
        [string]$Application = "uft",
        [string]$CleanMode = "uninstall",
        [string]$SUBSCRIPTION_ID = "",
        [string]$GAVersion = "",
        [string]$PatchID = ""
    )
    
    $csaDeployment = [CSADeployment]::new($CSAName, $SUBSCRIPTION_ID)
    $csaPreparation = $null
    $csaInstallApp = $null
    $installed=$false
    switch($CleanMode) 
    {
        "resnapshot" {
            $csaPreparation = [CSAPreparationRevertMachine]::GetInstance()
            break
        }
        "uninstall" {
            $csaPreparation = [CSAPreparationUninstallUFT]::GetInstance()
            break
        }
        default {
            $csaPreparation = [CSAPreparationUninstallUFT]::GetInstance()
            break
        }
    }

    switch($Application) 
    {
        "lftasfeature" {
            $csaInstallApp = [CSAInstallLFTAsFt]::GetInstance()
        }
        "uftpatch" {
            $csaInstallApp = [CSAInstallPatch]::GetInstance()
        }
        "uft" {
            $csaInstallApp = [CSAInstallUFT]::GetInstance()
            break
        }
        "rpa" {
            $csaInstallApp = [CSAInstallRPA]::GetInstance()
        }
        "ai" {
            $csaInstallApp = [CSAInstallAI]::GetInstance()
        }
        default {
            $csaInstallApp = [CSAInstallUFT]::GetInstance()
            break
        }
    }

    $csaDeployment.SetCSAPreparation([CSAPreparation]$csaPreparation)
    $csaDeployment.PrepareMachine()
    $csaDeployment.SetCSAInstallApp([CSAInstallApp]$csaInstallApp)
    if ( "" -ne $GAVersion ) {
       $installed = $csaDeployment.InstallApplication($GAVersion)
    } else {
       $installed = $csaDeployment.InstallApplication($BuidlVersion)
    }
    if (-Not $installed) { return $false } 
    if ( "" -ne $GAVersion) {
        $installed = $csaDeployment.InstallPatch($BuidlVersion, $PatchID)
    }
    return $installed
    
}



Export-ModuleMember -Function Install-Application

