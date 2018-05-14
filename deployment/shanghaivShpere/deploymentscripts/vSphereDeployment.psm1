using module '.\vSpherePreparation.psm1'
using module '.\vSphereInstallApp.psm1'

class VShpereDeploy {

    hidden [string]$MachineName
    hidden [string]$UserName
    hidden [string]$Password
    hidden [string]$ApplicationName
    hidden [System.Management.Automation.PSCredential]$Credential
    hidden [VSpherePreparation]$vSpherePreparation
    hidden [VSphereInstallApp]$vSphereInstallApp


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


    [Void]SetInstallApp([VSphereInstallApp]$vSphereInstallApp) {
        $this.vSphereInstallApp = $vSphereInstallApp
    }

    [Void]PrepareMachine() {
        $this.vSpherePreparation.doAction($this.MachineName, $this.UserName,$this.Password, $this.Credential)
    }

    [Boolean]InstallApplication(
        [string]$BuildVersion
    ) {
        return $this.vSphereInstallApp.InstallApplication($this.MachineName, $this.UserName, $this.Password, $this.Credential, $BuildVersion)
    }


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

    switch($Application) 
    {
        "lft" {
            $vSphereInstallApp = [VSphereInstallSALFT]::GetInstance()
        }
        # "uftpatch" {
        #     $vSphereInstallApp = [CSAInstallPatch]::GetInstance()
        # }
        "uft" {
            $vSphereInstallApp = [VSphereInstallUFT]::GetInstance()
            break
        }
        default {
            $vSphereInstallApp = [VSphereInstallUFT]::GetInstance()
            break
        }
    }

    $vSphereDeploy.SetPreparation([VSpherePreparation]$vSpherePreparation)
    $vSphereDeploy.PrepareMachine()
    $vSphereDeploy.SetInstallApp([VSphereInstallApp]$vSphereInstallApp)
    if ( "" -ne $GAVersion ) {
       $installed = $vSphereDeploy.InstallApplication($GAVersion)
    } else {
       $installed = $vSphereDeploy.InstallApplication($BuidlVersion)
    }
    # if (-Not $installed) { return $false } 
    # if ( "" -ne $GAVersion) {
    #     $installed = $csaDeployment.InstallPatch($BuidlVersion, $PatchID)
    # }
    return $installed
    
}



Export-ModuleMember -Function Install-Application