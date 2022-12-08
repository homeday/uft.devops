## Windows Server 2019

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

Start-Sleep 20
choco install googlechrome --version 104.0.5112.81 -y
Start-Sleep 20
choco install nodejs --version 18.6.0 -y
Start-Sleep 20
choco install ojdkbuild8 --version 8.0.332 -y
Start-Sleep 20
# choco install git --version 2.37.1 -y
# Start-Sleep 20
choco install npppluginmanager --version 1.4.12 -y
Start-Sleep 20
choco install 7zip --version 19.0 -y
Start-Sleep 10
choco install git --version 2.37.1 -y
Start-Sleep 10
choco install git-lfs --version 3.2.0 -y


# Add credentials to the manager
# Do it manually

# Install NFS-Client
Install-WindowsFeature -Name NFS-Client


## Install
Install-Module DockerMsftProvider -Force
Install-Package Docker -ProviderName DockerMsftProvider -Force
Install-WindowsFeature Containers
if((Install-WindowsFeature Containers).RestartNeeded -eq "Yes") {
	Restart-Computer
}
