
[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$true)]
    [string]$BuildVersion = $null
)
Set-ExecutionPolicy RemoteSigned
$result = Test-Path "P:\$BuildVersion\DVD\setup.exe"

if ($result) { 
    write-host Already uncompressed
    exit $LastExitCode
}
Get-ChildItem P:\$BuildVersion\DVD.7z.001 | % {& "7z.exe" "x" $_.fullname "-oP:\$BuildVersion"}

