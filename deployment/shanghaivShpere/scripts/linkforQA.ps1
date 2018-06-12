
[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$true)]
    [string]$BuildVersion,
    [Parameter(Mandatory=$true)]
    [string]$BuildLabel
)

#check folder exists
$BuildDir="E:\BuildSync\Builds\${BuildVersion}"
if(-Not (Test-Path -Path $BuildDir -PathType Container)){
    Write-Host "build folder doesn't exist!"
    exit 1
} 

$count = 10
while ((-Not (Test-Path -Path "${BuildDir}\DVD.7z.done" -PathType Leaf)) -And ($count -gt 0) ) {
    $count = $count - 1
    Start-Sleep -Seconds 300 
}

if ( -Not (Test-Path -Path "${BuildDir}\DVD.7z.done" -PathType Leaf )) {
    Write-Host "build synchronization doesn't complete!"
    exit 1
}


Push-Location -Path "E:\BuildSync\Builds\"
if(Test-Path -Path "${BuildLabel}"){
    cmd /c RD /s /q "${BuildLabel}"
} 
cmd /c mklink /J ${BuildLabel} ${BuildDir}
Pop-Location

if (-Not (Test-Path -Path "E:\BuildSync\Builds\${BuildVersion}\DVD\setup.exe" -PathType Leaf )) {
    Push-Location -Path "E:\BuildSync\Builds\${BuildVersion}"
    cmd /c 7z x DVD.7z.001
    Pop-Location
}

exit 0


