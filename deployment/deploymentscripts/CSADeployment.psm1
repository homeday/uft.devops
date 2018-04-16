



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
        if ($null -eq $this.CSACredential) {
            $SecPwd = ConvertTo-Securestring $this.CSAPassword -AsPlainText -Force
            $this.CSACredential = New-Object System.Management.Automation.PSCredential($this.CSAAccount, $SecPwd)
        }
        return $this.CSACredential
    }

    
    [Void]PrepareMachine(

    ) {
        $this.SetCredential()
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
        $IsAppexist=$false
        $Arguments=@("/C",
            "Net Use \\$($this.CSAName)\IPC`$ /USER:$($this.CSAAccount) $($this.CSAPassword)"
        )
        Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait
        $ApplicationDir="\\$($this.CSAName)\C`$\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\UFT.exe"
        $IsAppexist=Test-Path -Path $ApplicationDir
        Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}"

        if (-Not $IsAppexist) {
            $ApplicationDir="\\$($this.CSAName)\C`$\Program Files (x86)\HPE\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}"
        }

        if (-Not $IsAppexist) {
            $ApplicationDir="\\$($this.CSAName)\C`$\Program Files (x86)\HP\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "It is ${IsAppexist} that UFT exists in the directory ${ApplicationDir}"
        }

        $Arguments=@("/C",
            "Net Use \\$($this.CSAName)\IPC`$ /D"
        )
        Start-Process -FilePath CMD.exe -ArgumentList "${Arguments}" -Wait
        Write-Host "It is ${IsAppexist} UFT exists"
        return $IsAppexist
    }

    [Void]RestartMachine(

    ) {
        Restart-Computer -ComputerName $this.CSAName  -Credential $this.CSACredential -Wait -Timeout 300 -Force
        Start-Sleep -s 15 
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
        Write-Host "Installing UFT ${BuildVersion} now!"
        ([CSAMachineDeploy]$this).CopyFileToMachine("${PSScriptRoot}\installUFT_LeanFT.bat", "C:\")
        $sb = [scriptblock]::Create(
            "C:\installUFT_LeanFT.bat ${BuildVersion} mama.hpeswlab.net"
        )
        $iloop=0
        $installed=$false
        do {
            Invoke-Command -Credential $this.CSACredential -ComputerName $this.CSAName -ScriptBlock $sb
            Start-Sleep 180
            $iloop=$iloop+1
        } until ( ($installed=$this.CheckAppExist()) -eq $true -or $iloop -gt 3)

        Write-Host "UFT ${BuildVersion} is installed - ${installed}"
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
        Write-Host "Removing old uft now!"
        #Copy the uninstaller tool to the machine
        ([CSAMachineDeploy]$this).CopyFileToMachine("${PSScriptRoot}\del.bat", "C:\")
        ([CSAMachineDeploy]$this).CopyFileToMachine("${PSScriptRoot}\UFTUninstaller_v2.0", "C:\")
        
        #Set-Item WSMan:\localhost\Client\TrustedHosts -Value ([CSAMachineDeploy]$this).CSAName -Force
        if (([CSAMachineDeploy]$this).CheckAppExist()) {
            ([CSAMachineDeploy]$this).RestartMachine()
            #Invoke the application to remove the UFT
            Invoke-Command -Credential ([CSAMachineDeploy]$this).CSACredential -ComputerName ([CSAMachineDeploy]$this).CSAName -ScriptBlock `
            { `
                Start-Process -FilePath C:\UFTUninstaller_v2.0\UFTUninstaller.exe -ArgumentList -silent -Wait `
            } 
            ([CSAMachineDeploy]$this).RestartMachine()
        }
        Invoke-Command -Credential ([CSAMachineDeploy]$this).CSACredential -ComputerName ([CSAMachineDeploy]$this).CSAName -ScriptBlock `
        { `
            C:\del.bat `
        } 
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

    [Boolean]RevertSnapshot() {
        $Arguments=@("-jar",
        "CSAWrapper-5.0.0.jar",
        "subscriptionId=$(([CSAMachineDeploy]$this).CSASubscriptionID)",
        "actionName=RevertToSnapshot",
        "csaOrganization=ADM",
        "csaUrl=https://mydcsa.hpeswlab.net:8443/csa/rest",
        "csaUsername=$(([CSAMachineDeploy]$this).CSAAccount)",
        "csaPassword=$(([CSAMachineDeploy]$this).CSAPassword)")
        $ExecProcess=Start-Process -FilePath java.exe -ArgumentList "${Arguments}" -Wait  -PassThru
        Start-Sleep 60
        return 0 -eq $ExecProcess.ExitCode
    }

    [Void]PrepareMachine(

    ) {
       ([CSAMachineDeploy]$this).PrepareMachine()
       $this.RevertSnapshot()
    }
}

function Install-Application {
    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$CSAName = "",
        [Parameter(Mandatory=$true)]
        [string]$BuidlVersion = "",
        [string]$CleanMode = "uninstall",
        [string]$SUBSCRIPTION_ID = ""
    )
    $csaDeployment=$null
    switch($CleanMode) 
    {
        "resnapshot" {
            $csaDeployment = [CSAMachineDeploySnapShot]::new($CSAName,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
            break
        }
        "uninstall" {
            $csaDeployment = [CSAMachineDeployUninstall]::new($CSAName,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
            break
        }
        default {
            $csaDeployment = [CSAMachineDeployUninstall]::new($CSAName,$SUBSCRIPTION_ID,$txtuser,$txtpwd)
            break
        }
    }
    if ($csaDeployment -ne $null) {
        $csaDeployment.DeployWithBuildVersion($BuidlVersion)
    }
    return $true
}

Export-ModuleMember -Function Install-Application

