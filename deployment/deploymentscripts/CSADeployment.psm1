



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
#        $this.CSACredential = $null
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
        Write-Host "In the base class"
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
        Net Use "\\$($this.CSAName)\IPC`$ `/USER:$($this.CSAAccount) $($this.CSAPassword)"
        $ApplicationDir="\\$($this.CSAName)\C`$\Program Files (x86)\Micro Focus\Unified Functional Testing\bin\UFT.exe"
        $IsAppexist=Test-Path -Path $ApplicationDir
        Write-Host "UFT exists in the directory ${ApplicationDir} is ${IsAppexist}"

        if (-Not $IsAppexist) {
            $ApplicationDir="\\$($this.CSAName)\C`$\Program Files (x86)\HPE\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "UFT exists in the directory ${ApplicationDir} is ${IsAppexist}"
        }

        if (-Not $IsAppexist) {
            $ApplicationDir="\\$($this.CSAName)\C`$\Program Files (x86)\HP\Unified Functional Testing\bin\UFT.exe"
            $IsAppexist=Test-Path -Path $ApplicationDir
            Write-Host "UFT exists in the directory ${ApplicationDir} is ${IsAppexist}"
        }

        Net Use "\\$this.CSAName\IPC`$ `/D"

        Write-Host "UFT exists ${IsAppexist}"
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
        Write-Host "Installing old uft now!"
        ([CSAMachineDeploy]$this).CopyFileToMachine("${PSScriptRoot}\installUFT_LeanFT.bat", "C:\")
        $sb = [scriptblock]::Create(
            "C:\installUFT_LeanFT.bat ${BuildVersion} mama.hpeswlab.net"
        )
        Invoke-Command -Credential $this.CSACredential -ComputerName $this.CSAName -ScriptBlock $sb

        if (-Not $this.CheckAppExist()) {
            #retry and in case machine needs a reboot
            Start-Sleep 180
            Invoke-Command -Credential $this.CSACredential -ComputerName $this.CSAName -ScriptBlock $sb
        }

        return $this.CheckAppExist()
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
        ([CSAMachineDeploy]$this).CopyFileToMachine("${PSScriptRoot}\UFTUninstaller_v2.0", "C:\UFTUninstaller_v2.0")
        Invoke-Command -Credential ([CSAMachineDeploy]$this).CSACredential -ComputerName ([CSAMachineDeploy]$this).CSAName -ScriptBlock `
        { `
            C:\del.bat `
        } 
        #([CSAMachineDeploy]$this).RestartMachine()
        #Set-Item WSMan:\localhost\Client\TrustedHosts -Value ([CSAMachineDeploy]$this).CSAName -Force
        if (([CSAMachineDeploy]$this).CheckAppExist()) {
            #Invoke the application to remove the UFT
            Invoke-Command -Credential ([CSAMachineDeploy]$this).CSACredential -ComputerName ([CSAMachineDeploy]$this).CSAName -ScriptBlock `
            { `
                Start-Process -FilePath C:\UFTUninstaller_v2.0\UFTUninstaller.exe -ArgumentList -silent -Wait `
            } 
        }
        ([CSAMachineDeploy]$this).RestartMachine()
    }


    [Void]PrepareMachine(

    ) {
       ([CSAMachineDeploy]$this).PrepareMachine()
       ([CSAMachineDeploy]$this).UninstallApplication()
    }

}



