using module '.\vSpherePreparation.psm1'

class VShpereDeploy {

    hidden [string]$MachineName
    hidden [string]$UserName
    hidden [string]$Password
    hidden [string]$ApplicationName
    hidden [System.Management.Automation.PSCredential]$Credential
    hidden [VSpherePreparation]$vSpherePreparation


    VShpereDeploy() {
        Write-Host "VShpereDeploy::constructor" -ForegroundColor Green -BackgroundColor Black
    }


    VShpereDeploy(
        [string]$MachineName
    ){
        
        $this.UserName = "WORKGROUP\${env:VM_USER}"
        $this.Password = ${env:VM_PASSWORD}
        $this.MachineName = $MachineName
        $this.Credential = $null
        $this.vSpherePreparation = $null
        $this.SetCredential()
    }

    [System.Management.Automation.PSCredential]SetCredential(

    ){
        Write-Host "VShpereDeploy::SetCredential Start" -ForegroundColor Green -BackgroundColor Black
        if ($null -eq $this.Credential) {
            $SecPwd = ConvertTo-Securestring $this.Password -AsPlainText -Force
            $this.Credential = New-Object System.Management.Automation.PSCredential($this.UserName, $SecPwd)
        }
        Write-Host "Credential is $($this.Credential)" -ForegroundColor Green -BackgroundColor Black
        Write-Host "VShpereDeploy::SetCredential End" -ForegroundColor Green -BackgroundColor Black
        return $this.Credential
    }

    [Void]SetPreparation([VSpherePreparation]$vSpherePreparation) {
        $this.vSpherePreparation = $vSpherePreparation
    }


    # [Void]SetCSAInstallApp([CSAInstallApp]$CSAInstallApp) {
    #     $this.CSAInstallApp = $CSAInstallApp
    # }

    [Void]PrepareMachine() {
        $this.vSpherePreparation.doAction($this.MachineName, $this.UserName,$this.Password, $this.Credential)
    }

    # [Boolean]InstallApplication(
    #     [string]$BuildVersion
    # ) {
    #     return $this.CSAInstallApp.InstallApplication($this.MachineName, $this.UserName,$this.Password, $this.Credential, $BuildVersion)
    # }


    # [Boolean]InstallPatch(
    #     [string]$BuildVersion,
    #     [string]$PatchID
    # ) {
    #     return $this.CSAInstallApp.InstallPatch($this.MachineName, $this.Credential, $BuildVersion, $PatchID)
    # }

}


function Install-Application {
    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$MachineName = "",
        [Parameter(Mandatory=$true)]
        [string]$BuidlVersion = "",
        [Parameter(Mandatory=$true)]
        [string]$Application = "uft",
        [string]$CleanMode = "uninstall",
        [string]$SUBSCRIPTION_ID = "",
        [string]$GAVersion = "",
        [string]$PatchID = ""
    )
    
    $vSphereDeploy = [VShpereDeploy]::new($MachineName)
    $vSpherePreparation = $null
    $vSphereInstallApp = $null
    $installed=$false
    switch($CleanMode) 
    {
        "resnapshot" {
            $vSpherePreparation = [VSphereRevertMachine]::GetInstance()
            break
        }
        "uninstall" {
            #$vSpherePreparation = [CSAPreparationUninstallUFT]::GetInstance()
            break
        }
        default {
            $vSpherePreparation = [VSphereRevertMachine]::GetInstance()
            break
        }
    }

    # switch($Application) 
    # {
    #     "lftasfeature" {
    #         $csaInstallApp = [CSAInstallLFTAsFt]::GetInstance()
    #     }
    #     "uftpatch" {
    #         $csaInstallApp = [CSAInstallPatch]::GetInstance()
    #     }
    #     "uft" {
    #         $csaInstallApp = [CSAInstallUFT]::GetInstance()
    #         break
    #     }
    #     default {
    #         $csaInstallApp = [CSAInstallUFT]::GetInstance()
    #         break
    #     }
    # }

    $vSphereDeploy.SetPreparation([VSpherePreparation]$vSpherePreparation)
    $vSphereDeploy.PrepareMachine()
    # $csaDeployment.SetCSAInstallApp([CSAInstallApp]$csaInstallApp)
    # if ( "" -ne $GAVersion ) {
    #    $installed = $csaDeployment.InstallApplication($GAVersion)
    # } else {
    #    $installed = $csaDeployment.InstallApplication($BuidlVersion)
    # }
    # if (-Not $installed) { return $false } 
    # if ( "" -ne $GAVersion) {
    #     $installed = $csaDeployment.InstallPatch($BuidlVersion, $PatchID)
    # }
    return $installed
    
}



Export-ModuleMember -Function Install-Application