########### Choco installation block ############
$i=0
do {

	if($i -ne 0){
		Write-Host "[Info]: Failed to install choco! Retry ($i)/5 after 10 seconds..."
		Start-Sleep 10
	}

	# Download and install Choch
	Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
	$isChocoExist = (Test-Path -Path "C:\ProgramData\chocolatey\bin\choco.exe")

	$i = $i + 1

} until($isChocoExist -eq "False" -or $i -gt 5)
########### Choco installation block ############

#============== Install OpenSSH ================

# Install OpenSSH Server
dism /online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0
sc start sshd
Start-Sleep 20
# =============================================================

#==================== Install tools ===========================
choco install googlechrome --version 104.0.5112.102 -y
Start-Sleep 20
choco install firefox --version 102.0.1 -y
Start-Sleep 20
choco install nodejs --version 18.6.0 -y
Start-Sleep 20
choco install ojdkbuild8 --version 8.0.332 -y
Start-Sleep 20
choco install git --version 2.37.1 -y
Start-Sleep 20
choco install npppluginmanager --version 1.4.12 -y
Start-Sleep 20
choco install python --version 3.10.5 -y
Start-Sleep 20
choco install putty --version 0.77 -y
Start-Sleep 20
choco install winscp --version 5.21.1 -y
Start-Sleep 20
choco install everything --version 1.4.11017.20220621 -y
Start-Sleep 20
choco install vscode --version 1.70.2 -y
Start-Sleep 20
choco install jq --version 1.6 -y
Start-Sleep 20
#===============================================================

#=================== Install NFS-Client ========================

Write-Host "*** Enbling NFS-Client Feature ***"
Install-WindowsFeature -Name NFS-Client
Start-Sleep 10

Write-Host "*** Enabling Media Foundation Feature ***"
Install-WindowsFeature -Name Server-Media-Foundation
Start-Sleep 10
#===============================================================
# ================== Install AWS CLI ===========================

if ((Get-Command aws -ErrorAction SilentlyContinue) -ne $null) {
    Write-Host "AWS CLI is already installed in the machine!"
    return
}

$command = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
Invoke-Expression $command
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -Outfile C:\AWSCLIV2.msi
$arguments = "/i `"C:\AWSCLIV2.msi`" /quiet"
Start-Process msiexec.exe -ArgumentList $arguments -Wait

# =============== AWS CLI Installation done =====================
