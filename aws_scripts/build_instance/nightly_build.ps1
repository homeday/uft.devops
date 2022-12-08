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


# Install Tools
choco install everything --version 1.4.11017.20220621 -y
Start-Sleep 10
choco install vscode --version 1.69.2 -y
Start-Sleep 10
choco install npppluginmanager --version 1.4.12 -y
Start-Sleep 10
choco install python --version 3.10.5 -y
Start-Sleep 10
choco install putty --version 0.77 -y
Start-Sleep 10
choco install winscp --version 5.21.1 -y
Start-Sleep 10
choco install 7zip --version 19.0 -y
Start-Sleep 10
choco install git --version 2.37.1 -y
Start-Sleep 10
choco install git-lfs --version 3.2.0 -y
Start-Sleep 2
git lfs install # Initialize git lfs

# Git configuration
Git config --global core.symlinks true
Git config --global core.autocrlf true
Git config --global core.fscache true
Git config --global color.diff auto
Git config --global color.status auto
Git config --global color.branch auto
Git config --global color.interactive true
Git config --global help.format html
Git config --global rebase.autosquash true
Git config --global http.sslbackend openssl
Git config --global diff.astextplain.textconv astextplain
Git config --global credential.helper manager-core
Git config --global core.editor """'C:\\Program Files\\Notepad++\\notepad++.exe' -multiInst -notabbar -nosession -noPlugin"""
Git config --global filter.lfs.clean git-lfs clean -- %f
Git config --global filter.lfs.smudge git-lfs smudge -- %f
Git config --global filter.lfs.process git-lfs filter-process
Git config --global filter.lfs.required true
Git config --global filter.lfs.clean git-lfs clean -- %f
Git config --global filter.lfs.smudge git-lfs smudge -- %f
Git config --global filter.lfs.process git-lfs filter-process
Git config --global filter.lfs.required true
Git config --global --unset-all http.sslcainfo
Git config --global http.sslcainfo "C:/Program Files/Git/mingw64/ssl/certs/ca-bundle.crt"
Git config --system core.editor """'C:\\Program Files\\Notepad++\\notepad++.exe' -multiInst -notabbar -nosession -noPlugin"""

#=================== Install NFS-Client ========================

Write-Host "*** Enbling NFS-Client Feature ***"
Install-WindowsFeature -Name NFS-Client
Start-Sleep 10
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

# Create a Git config file in ProgreamData
New-Item -ItemType Directory -Path "C:\ProgramData\Git"
"[core]`r`n`tsymlinks = false`r`n`tautocrlf = true`r`n`tfscache = true`r`n[color]`r`n`tdiff = auto`r`n`tstatus = auto`r`n`tbranch = auto`r`n`tinteractive = true`r`n[help]`r`n`tformat = html`r`n[rebase]`r`n`tautosquash = true" | out-file -filepath "C:\ProgramData\Git\config"

# Add GIT credential to Credential manager
cmdkey /generic:git:https://github.houston.softwaregrp.net /user:uftgithub /pass:0211f662b4b1f6b26aceaa5c1501c4bc67938c41
cmdkey /generic:git:https://uftgithub@github.houston.softwaregrp.net /user:uftgithub /pass:0211f662b4b1f6b26aceaa5c1501c4bc67938c41
cmdkey /generic:git:https://svc_ft-auto-01@github.houston.softwaregrp.net /user:svc_ft-auto-01 /pass:618b516b843eb4e1d642a55eb5a7a15651021065

# Download JQ at **\Git\mingw64\bin
$url="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe"
$outpath="$env:ProgramFiles\Git\mingw64\bin\jq.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $outpath

# Append tools path in PATH Environment Variable
setx PATH "$env:path;D:\UFT_Tools\Node.js" -m
setx UFT_Tools "D:\UFT_Tools" -m
setx PATH "$env:path;D:\UFT_Tools\Java\jdk1.7.0_55\bin;" -m
# Git
setx PATH "$env:path;$Env:ProgramFiles\Git\bin" -m
setx PATH "$env:path;$Env:ProgramFiles\Git\mingw64\bin" -m


# Install .NET Freamwork 3.5 feature
Install-WindowsFeature Net-Framework-Features



# Install VS Manually
# Prepare Perl
# step 1. Copy perl from D:\UFT_Tools to C:\
# Step 2. Set Perl path to ENV (this path should be the first one)

# VS 2005 and 2005 SP1 (Install @C:\VS80)
# VS 2008 and 2008 SP1 (Install @C:\VS90 | Install all components) | 2008 SDK1.1 (Install @default location)
# VS 2010 and 2010 SP1 (Install @C:\VS100) | 2010 SP1 SDK (Install @default location)
# VS 2012 and 2012 SP4 (Install @C:\VS110) 
# VS 2013 and Multibyte MFC Library for Visual Studio 2013 (Install @default location)
# VS 2015 with Update 3 (Install @VS140) - Downlaod it from https://my.visualstudio.com
# VS 2017
# VS 2019
# VS 2022 Version 7.1.4 (https://download.visualstudio.microsoft.com/download/pr/180ad262-2f90-4974-a63e-3e47a5b2033c/44b8415612f1bcb6a2b46a7ab626dbed415b55856c633ac1897e16215e065f75/vs_Professional.exe)
#    Components: 

# Open VS2022 -> Tools -> Options -> Project & Solution -> Build and Run -> Set max parallel setting from 8 to 24

# Install Windows Kits 10
# Download "Windows 10 SDK, version 2004 (10.0.19041.0)" from https://developer.microsoft.com/en-us/windows/downloads/sdk-archive/

# Add VS installation path in the System env
Setx NUMBER_OF_PROCESSORS "24" -m
Setx PATHEXT ".COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC;.PY;.PYW" -m
setx VS220COMNTOOLS "C:\VS220\Common7\Tools\" -m

# VS100COMNTOOLS=D:\VS100\Common7\Tools\
# VS110COMNTOOLS=D:\VS110\Common7\Tools\
# VS120COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\Tools\
# VS140COMNTOOLS=D:\VS140\Common7\Tools\
# VS220COMNTOOLS=D:\VS220\Common7\Tools\
# VS80COMNTOOLS=D:\VS80\Common7\Tools\
# VS90COMNTOOLS=D:\VS90\Common7\Tools\
# VSSDK100Install=C:\Program Files (x86)\Microsoft Visual Studio 2010 SDK SP1\
# VSSDK140Install=D:\VS140\VSSDK\
# VSSDK90Install=C:\Program Files (x86)\Microsoft Visual Studio 2008 SDK\

# Install dotnet 5.0.103 - https://dotnet.microsoft.com/en-us/download/dotnet/5.0

# Enable SymlinkEvaluation Remote to Local and Remote to Remote
fsutil behavior set SymlinkEvaluation R2L:1
fsutil behavior set SymlinkEvaluation R2R:1