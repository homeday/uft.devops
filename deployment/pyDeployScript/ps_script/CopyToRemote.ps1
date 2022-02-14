#Define CLI Params
param(
    [string]$hostname="",
    [string]$username="_ft_auto@swinfra.net",
    [string]$pass="W3lcome1",
    [string]$source="",
    [string]$destination=""
)

($credential = New-Object System.Management.Automation.PSCredential($username, (ConvertTo-Securestring $pass -AsPlainText -Force)))

Write-Host "[Info]: Connecting to $hostname"
$session = New-PSSession -Credential $credential -ComputerName $hostname

Write-Host "[Info]: Copying file from '$source' to '$destination'"
Copy-Item -Path $source -Destination $destination -ToSession $session -recurse -Force
Write-Host "[Info]: Disconnecting from '$hostname'"
$session = Remove-PSSession -Session $session

if ($null -eq $session) {
    Write-Host "[Info]: The session has desconnected successfully for the '$hostname' host!"
}

